#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2
readonly EXIT_TOOL=3
readonly EXIT_PROVIDER=4
readonly EXIT_KUBERNETES=5
readonly EXIT_SAFETY=6
readonly CLUSTER_NAME="rolloutproof-dev"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly CONFIG="${REPO_ROOT}/infra/local/kind/cluster.yaml"
readonly VERSIONS="${REPO_ROOT}/infra/local/kind/versions.yaml"
readonly TOOL_VERSIONS="${REPO_ROOT}/infra/local/tool-versions.yaml"
readonly WORK_DIR="${REPO_ROOT}/.work"
readonly KUBECONFIG_FILE="${WORK_DIR}/kubeconfig"
readonly METADATA_FILE="${WORK_DIR}/cluster/${CLUSTER_NAME}.metadata"

usage() {
  printf 'usage: %s <plan|up|check|down> [--minor 1.34|1.35|1.36]\n' "${0##*/}" >&2
}

ACTION="${1:-plan}"
[[ $# -gt 0 ]] && shift
K8S_MINOR="${K8S_MINOR:-1.36}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minor)
      [[ $# -ge 2 ]] || { usage; exit "${EXIT_USAGE}"; }
      K8S_MINOR="$2"
      shift 2
      ;;
    *) usage; exit "${EXIT_USAGE}" ;;
  esac
done

case "${ACTION}" in plan|up|check|down) ;; *) usage; exit "${EXIT_USAGE}" ;; esac
case "${K8S_MINOR}" in 1.34|1.35|1.36) ;; *) printf 'ERROR: unsupported Kubernetes minor: %s\n' "${K8S_MINOR}" >&2; exit "${EXIT_USAGE}" ;; esac

tool_version() {
  local tool="$1"
  awk -v tool="${tool}" '
    $0 == "  " tool ":" { in_tool = 1; next }
    in_tool && $0 ~ /^    version:/ {
      sub(/^    version:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
    in_tool && $0 ~ /^  [a-zA-Z0-9_-]+:/ { exit }
  ' "${TOOL_VERSIONS}"
}

image_for_minor() {
  local minor="$1"
  awk -v minor="${minor}" '
    $0 == "  \"" minor "\":" { in_minor = 1; next }
    in_minor && $0 ~ /^    image:/ {
      sub(/^    image:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
    in_minor && $0 ~ /^  "/ { exit }
  ' "${VERSIONS}"
}

KIND_VERSION="$(tool_version kind)"
readonly KIND_VERSION
KUBECTL_VERSION="$(tool_version kubectl)"
readonly KUBECTL_VERSION
NODE_IMAGE="$(image_for_minor "${K8S_MINOR}")"
readonly NODE_IMAGE
[[ "${NODE_IMAGE}" == *@sha256:* ]] || { printf 'ERROR: missing digest-pinned image for %s\n' "${K8S_MINOR}" >&2; exit "${EXIT_USAGE}"; }

kind_cmd() {
  if command -v mise >/dev/null 2>&1; then
    mise exec "kind@${KIND_VERSION}" -- kind "$@"
  elif command -v kind >/dev/null 2>&1; then
    kind "$@"
  else
    printf 'ERROR: kind is missing; run APPLY=true scripts/env/bootstrap.sh\n' >&2
    return "${EXIT_TOOL}"
  fi
}

kubectl_cmd() {
  if command -v mise >/dev/null 2>&1; then
    mise exec "kubectl@${KUBECTL_VERSION}" -- kubectl --kubeconfig "${KUBECONFIG_FILE}" "$@"
  elif command -v kubectl >/dev/null 2>&1; then
    kubectl --kubeconfig "${KUBECONFIG_FILE}" "$@"
  else
    printf 'ERROR: kubectl is missing; run APPLY=true scripts/env/bootstrap.sh\n' >&2
    return "${EXIT_TOOL}"
  fi
}

cluster_exists() {
  kind_cmd get clusters 2>/dev/null | grep -Fxq "${CLUSTER_NAME}"
}

fingerprint() {
  { shasum -a 256 "${CONFIG}"; printf '%s\n' "${NODE_IMAGE}"; } | shasum -a 256 | awk '{print $1}'
}

metadata_matches() {
  [[ -f "${METADATA_FILE}" ]] && grep -Fxq "fingerprint=$(fingerprint)" "${METADATA_FILE}"
}

write_metadata() {
  mkdir -p "$(dirname "${METADATA_FILE}")"
  {
    printf 'cluster=%s\n' "${CLUSTER_NAME}"
    printf 'minor=%s\n' "${K8S_MINOR}"
    printf 'image=%s\n' "${NODE_IMAGE}"
    printf 'fingerprint=%s\n' "$(fingerprint)"
  } >"${METADATA_FILE}"
}

check_cluster() {
  [[ -f "${KUBECONFIG_FILE}" ]] || { printf 'ERROR: dedicated kubeconfig missing: %s\n' "${KUBECONFIG_FILE}" >&2; return "${EXIT_KUBERNETES}"; }
  cluster_exists || { printf 'ERROR: cluster not found: %s\n' "${CLUSTER_NAME}" >&2; return "${EXIT_KUBERNETES}"; }
  metadata_matches || { printf 'ERROR: cluster config drift detected; refusing automatic replacement\n' >&2; return "${EXIT_SAFETY}"; }
  kubectl_cmd wait --for=condition=Ready node --all --timeout=30s >/dev/null
  local control_planes workers total
  control_planes="$(kubectl_cmd get nodes -l node-role.kubernetes.io/control-plane -o name | wc -l | tr -d ' ')"
  total="$(kubectl_cmd get nodes -o name | wc -l | tr -d ' ')"
  workers=$((total - control_planes))
  [[ "${control_planes}" -eq 1 && "${workers}" -eq 1 ]] || {
    printf 'ERROR: expected control-plane=1 worker=1, got control-plane=%s worker=%s\n' "${control_planes}" "${workers}" >&2
    return "${EXIT_KUBERNETES}"
  }
  printf 'cluster=%s status=READY minor=%s control_plane=%s worker=%s kubeconfig=%s\n' \
    "${CLUSTER_NAME}" "${K8S_MINOR}" "${control_planes}" "${workers}" "${KUBECONFIG_FILE}"
}

case "${ACTION}" in
  plan)
    printf 'task=ENV-006 mode=plan cluster=%s minor=%s image=%s kubeconfig=%s\n' \
      "${CLUSTER_NAME}" "${K8S_MINOR}" "${NODE_IMAGE}" "${KUBECONFIG_FILE}"
    if cluster_exists; then
      if metadata_matches; then
        printf 'result=REUSE\n'
      else
        printf 'result=DRIFT action=FAIL_WITHOUT_DELETE\n'
        exit "${EXIT_SAFETY}"
      fi
    else
      printf 'result=CREATE_REQUIRES_APPLY_TRUE\n'
    fi
    ;;
  up)
    [[ "${APPLY:-false}" == "true" ]] || { printf 'ERROR: up requires APPLY=true\n' >&2; exit "${EXIT_SAFETY}"; }
    "${REPO_ROOT}/scripts/env/provider.sh" docker-desktop check >/dev/null || exit "${EXIT_PROVIDER}"
    if cluster_exists; then
      metadata_matches || { printf 'ERROR: cluster config drift detected; refusing automatic delete/recreate\n' >&2; exit "${EXIT_SAFETY}"; }
      mkdir -p "${WORK_DIR}"
      kind_cmd export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_FILE}"
    else
      mkdir -p "${WORK_DIR}"
      kind_cmd create cluster --name "${CLUSTER_NAME}" --config "${CONFIG}" --image "${NODE_IMAGE}" --kubeconfig "${KUBECONFIG_FILE}" --wait 120s
      write_metadata
    fi
    check_cluster
    ;;
  check)
    check_cluster
    ;;
  down)
    [[ "${ALLOW_DELETE:-false}" == "true" ]] || { printf 'ERROR: down requires ALLOW_DELETE=true\n' >&2; exit "${EXIT_SAFETY}"; }
    cluster_exists || { printf 'result=NO_CHANGE reason=cluster_absent\n'; exit 0; }
    metadata_matches || { printf 'ERROR: ownership metadata mismatch; refusing deletion\n' >&2; exit "${EXIT_SAFETY}"; }
    kind_cmd delete cluster --name "${CLUSTER_NAME}"
    rm -f "${KUBECONFIG_FILE}" "${METADATA_FILE}"
    printf 'result=DELETED cluster=%s\n' "${CLUSTER_NAME}"
    ;;
esac
