#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly KUBECONFIG_FILE="${REPO_ROOT}/.work/kubeconfig"

RUN_ID="${ROLLOUTPROOF_RUN_ID:-verify-$(date -u +%Y%m%d%H%M%S)}"
if [[ "${1:-}" == "--run-id" && $# -eq 2 ]]; then RUN_ID="$2"; elif [[ $# -ne 0 ]]; then printf 'usage: %s [--run-id <id>]\n' "${0##*/}" >&2; exit "${EXIT_USAGE}"; fi
[[ "${RUN_ID}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || { printf 'ERROR: invalid run ID\n' >&2; exit "${EXIT_USAGE}"; }

readonly ARTIFACT_DIR="${REPO_ROOT}/.work/artifacts/environment/${RUN_ID}"
readonly RESULTS="${ARTIFACT_DIR}/verification.tsv"
readonly METADATA="${ARTIFACT_DIR}/metadata.env"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly STARTED_AT
mkdir -p "${ARTIFACT_DIR}"
: >"${RESULTS}"

add() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >>"${RESULTS}"; }

if [[ "$(grep -c 'role: control-plane' "${REPO_ROOT}/infra/local/kind/cluster.yaml")" -eq 1 && "$(grep -c 'role: worker' "${REPO_ROOT}/infra/local/kind/cluster.yaml")" -eq 1 ]]; then
  add ENV-STATIC-004 PASS 0 'kind config has one control-plane and one worker' -
else
  add ENV-STATIC-004 FAIL 2 'kind node topology is invalid' 'inspect infra/local/kind/cluster.yaml'
fi

if [[ "$(grep -Ec 'image: .*@sha256:[0-9a-f]{64}' "${REPO_ROOT}/infra/local/kind/versions.yaml")" -eq 3 ]]; then
  add ENV-STATIC-005 PASS 0 'three Kubernetes minors have pinned digests' -
else
  add ENV-STATIC-005 FAIL 2 'node image digest manifest is incomplete' 'inspect infra/local/kind/versions.yaml'
fi

if command -v mise >/dev/null 2>&1 && MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kind@0.32.0 -- kind version >/dev/null 2>&1; then
  add ENV-TOOL-004 PASS 0 'kind 0.32.0 is available' -
  tool_ready=true
else
  add ENV-TOOL-004 FAIL 3 'kind 0.32.0 is unavailable' 'APPLY=true scripts/env/bootstrap.sh'
  tool_ready=false
fi

if "${REPO_ROOT}/scripts/env/provider.sh" docker-desktop check >/dev/null 2>&1; then
  add ENV-RUNTIME-004 PASS 0 'Docker Desktop desktop-linux daemon is ready' -
  runtime_ready=true
else
  add ENV-RUNTIME-004 FAIL 4 'Docker Desktop provider is unavailable' 'open Docker Desktop and rerun provider check'
  runtime_ready=false
fi

if [[ -f "${KUBECONFIG_FILE}" ]]; then
  add ENV-KIND-002 PASS 0 'dedicated kubeconfig exists under .work' -
  kubeconfig_ready=true
else
  add ENV-KIND-002 FAIL 5 'dedicated kubeconfig is missing' 'APPLY=true scripts/env/kind.sh up --minor 1.36'
  kubeconfig_ready=false
fi

if [[ "${tool_ready}" == true && "${runtime_ready}" == true && "${kubeconfig_ready}" == true ]]; then
  if "${REPO_ROOT}/scripts/env/kind.sh" check --minor 1.36 >/dev/null 2>&1; then
    add ENV-K8S-003 PASS 0 'control-plane and worker are Ready' -
    cluster_ready=true
  else
    add ENV-K8S-003 FAIL 5 'cluster readiness check failed' 'scripts/env/kind.sh check --minor 1.36'
    cluster_ready=false
  fi
else
  add ENV-K8S-003 BLOCKED 10 'cluster check blocked by tool/runtime/kubeconfig' -
  cluster_ready=false
fi

if [[ "${cluster_ready}" == true ]]; then
  add ENV-ISOLATION-001 PASS 0 'all Kubernetes access uses project kubeconfig' -
else
  add ENV-ISOLATION-001 BLOCKED 10 'isolation check blocked by cluster readiness' -
fi

server_version="unknown"
if [[ "${cluster_ready}" == true ]]; then
  server_version="$(MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kubectl@1.36.3 -- kubectl --kubeconfig "${KUBECONFIG_FILE}" version -o json 2>/dev/null | awk -F'"' '/gitVersion/ { value=$4 } END { print value }')"
fi

{
  printf 'run_id=%s\n' "${RUN_ID}"
  printf 'commit=%s\n' "$(git rev-parse HEAD)"
  printf 'started_at=%s\n' "${STARTED_AT}"
  printf 'finished_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'host_os=%s\n' "$(sw_vers -productVersion 2>/dev/null || uname -s)"
  printf 'architecture=%s\n' "$(uname -m)"
  printf 'go_version=1.26.2\nkind_version=0.32.0\nkubectl_version=1.36.3\n'
  printf 'docker_context=%s\n' "$(docker context show 2>/dev/null || printf unavailable)"
  printf 'server_version=%s\n' "${server_version:-unknown}"
} >"${METADATA}"

"${REPO_ROOT}/scripts/env/report.sh" "${ARTIFACT_DIR}"
