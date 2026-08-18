#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSIONS_FILE="${ROOT_DIR}/infra/local/kind/versions.yaml"
CLUSTER_CONFIG="${ROOT_DIR}/infra/local/kind/cluster.yaml"

usage() {
  printf 'Usage: %s <plan|run|cleanup> --minor <1.34|1.35|1.36>\n' "$0" >&2
}

command="${1:-}"
shift || true
minor=""
while (($#)); do
  case "$1" in
    --minor) minor="${2:-}"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done

case "${command}" in plan|run|cleanup) ;; *) usage; exit 2 ;; esac
case "${minor}" in 1.34|1.35|1.36) ;; *) usage; exit 2 ;; esac

require_command() {
  command -v "$1" >/dev/null 2>&1 || { printf 'missing command: %s\n' "$1" >&2; exit 1; }
}

manifest_value() {
  local field="$1"
  awk -v target="\"${minor}\":" -v field="${field}:" '
    $1 == target { found=1; next }
    found && $1 == field { gsub(/\"/, "", $2); print $2; exit }
    found && $1 ~ /^\"[0-9]+\.[0-9]+\":$/ { exit }
  ' "${VERSIONS_FILE}"
}

image="$(manifest_value image)"
version="$(manifest_value version)"
[[ -n "${image}" && -n "${version}" ]] || { printf 'version not found: %s\n' "${minor}" >&2; exit 1; }

cluster_name="rolloutproof-k${minor//./}"
work_dir="${ROOT_DIR}/.work/ci/${minor}"
kubeconfig="${work_dir}/kubeconfig"
artifact_dir="${ROOT_DIR}/.work/artifacts/environment/ci-${minor}"

if [[ "${command}" == plan ]]; then
  printf 'minor=%s\nversion=%s\nimage=%s\ncluster=%s\nconfig=%s\nkubeconfig=%s\n' \
    "${minor}" "${version}" "${image}" "${cluster_name}" "${CLUSTER_CONFIG}" "${kubeconfig}"
  exit 0
fi

require_command kind

if [[ "${command}" == cleanup ]]; then
  [[ "${ALLOW_DELETE:-false}" == true ]] || { printf 'cleanup requires ALLOW_DELETE=true\n' >&2; exit 1; }
  kind delete cluster --name "${cluster_name}"
  exit 0
fi

require_command docker
require_command kubectl
docker info >/dev/null
mkdir -p "${work_dir}" "${artifact_dir}"

if kind get clusters | grep -Fxq "${cluster_name}"; then
  kind export kubeconfig --name "${cluster_name}" --kubeconfig "${kubeconfig}"
else
  kind create cluster \
    --name "${cluster_name}" \
    --config "${CLUSTER_CONFIG}" \
    --image "${image}" \
    --kubeconfig "${kubeconfig}" \
    --wait 180s
fi

kubectl --kubeconfig "${kubeconfig}" wait --for=condition=Ready nodes --all --timeout=120s
node_count="$(kubectl --kubeconfig "${kubeconfig}" get nodes --no-headers | wc -l | tr -d ' ')"
server_version="$(kubectl --kubeconfig "${kubeconfig}" version -o json | awk -F'"' '/gitVersion/ { value=$4 } END { print value }')"
[[ "${node_count}" == 2 ]] || { printf 'expected 2 ready nodes, got %s\n' "${node_count}" >&2; exit 1; }
[[ "${server_version}" == "v${version}" ]] || { printf 'expected v%s, got %s\n' "${version}" "${server_version}" >&2; exit 1; }

json_report="${artifact_dir}/environment-ci-report.json"
md_report="${artifact_dir}/environment-ci-report.md"
cat >"${json_report}" <<EOF
{"schemaVersion":1,"minor":"${minor}","version":"${version}","image":"${image}","cluster":"${cluster_name}","nodeCount":${node_count},"serverVersion":"${server_version}","verdict":"READY","exitCode":0}
EOF
cat >"${md_report}" <<EOF
# Environment CI report

- Kubernetes: ${server_version}
- Image: \`${image}\`
- Cluster: \`${cluster_name}\`
- Ready nodes: ${node_count}
- Verdict: **READY**
EOF

(
  cd "${artifact_dir}"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum environment-ci-report.json environment-ci-report.md >checksums.sha256
  else
    shasum -a 256 environment-ci-report.json environment-ci-report.md >checksums.sha256
  fi
)
printf 'READY: %s (%s)\n' "${cluster_name}" "${server_version}"
