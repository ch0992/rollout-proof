#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly WORKSPACE="${REPO_ROOT}/scripts/env/workspace.sh"
readonly RUN_ID="env009-cleanup-$$"
readonly TARGET_NAMESPACE="rolloutproof-test-${RUN_ID}"
readonly UNRELATED_NAMESPACE="rolloutproof-test-unrelated-$$"

kubectl_project() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kubectl@1.36.3 -- kubectl --kubeconfig "${REPO_ROOT}/.work/kubeconfig" "$@"
}

cleanup_fixture() {
  ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1 || true
  kubectl_project delete namespace "${UNRELATED_NAMESPACE}" --ignore-not-found --wait=true --timeout=60s >/dev/null 2>&1 || true
}
trap cleanup_fixture EXIT

kubectl_project create namespace "${UNRELATED_NAMESPACE}" >/dev/null
unrelated_uid="$(kubectl_project get namespace "${UNRELATED_NAMESPACE}" -o 'jsonpath={.metadata.uid}')"
APPLY=true "${WORKSPACE}" init --run-id "${RUN_ID}" >/dev/null

set +e
"${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1
no_opt_in_code=$?
set -e
[[ ${no_opt_in_code} -eq 6 ]]
kubectl_project get namespace "${TARGET_NAMESPACE}" >/dev/null

ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null
if kubectl_project get namespace "${TARGET_NAMESPACE}" >/dev/null 2>&1; then
  printf 'target namespace survived cleanup\n' >&2
  exit 1
fi
[[ "$(kubectl_project get namespace "${UNRELATED_NAMESPACE}" -o 'jsonpath={.metadata.uid}')" == "${unrelated_uid}" ]]

second_cleanup="$(ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}")"
grep -q 'result=NO_CHANGE' <<<"${second_cleanup}"

printf 'cleanup_test: PASS\n'
