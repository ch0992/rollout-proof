#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly WORKSPACE="${REPO_ROOT}/scripts/env/workspace.sh"
readonly METADATA="${REPO_ROOT}/.work/cluster/rolloutproof-dev.metadata"
readonly RUN_ID="env009-failure-$$"
readonly NAMESPACE="rolloutproof-test-${RUN_ID}"

kubectl_project() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kubectl@1.36.3 -- kubectl --kubeconfig "${REPO_ROOT}/.work/kubeconfig" "$@"
}

kind_clusters() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kind@0.32.0 -- kind get clusters | sort
}

original_metadata="$(cat "${METADATA}")"
restore() {
  printf '%s\n' "${original_metadata}" >"${METADATA}"
  kubectl_project label namespace "${NAMESPACE}" "rollout-proof.dev/run-id=${RUN_ID}" --overwrite >/dev/null 2>&1 || true
  ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1 || true
}
trap restore EXIT

clusters_before="$(kind_clusters)"
sed 's/^fingerprint=.*/fingerprint=injected-drift/' "${METADATA}" >"${METADATA}.tmp"
mv "${METADATA}.tmp" "${METADATA}"
set +e
APPLY=true "${REPO_ROOT}/scripts/env/kind.sh" up --minor 1.36 >/dev/null 2>&1
drift_code=$?
set -e
[[ ${drift_code} -eq 6 ]]
[[ "$(kind_clusters)" == "${clusters_before}" ]]
printf '%s\n' "${original_metadata}" >"${METADATA}"

APPLY=true "${WORKSPACE}" init --run-id "${RUN_ID}" >/dev/null
kubectl_project label namespace "${NAMESPACE}" 'rollout-proof.dev/run-id=injected-wrong-owner' --overwrite >/dev/null
set +e
ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1
ownership_code=$?
set -e
[[ ${ownership_code} -eq 6 ]]
kubectl_project get namespace "${NAMESPACE}" >/dev/null

printf 'failure_test: PASS\n'
