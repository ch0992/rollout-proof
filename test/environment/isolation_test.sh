#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly WORKSPACE="${REPO_ROOT}/scripts/env/workspace.sh"
readonly RUN_ID="env007-$$"
readonly NAMESPACE="rolloutproof-test-${RUN_ID}"

kubectl_project() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kubectl@1.36.3 -- kubectl --kubeconfig "${REPO_ROOT}/.work/kubeconfig" "$@"
}

cleanup() {
  ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

global_before="$(kubectl config current-context 2>/dev/null || printf '<unset>')"
docker_before="$(docker context show)"
clusters_before="$(MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kind@0.32.0 -- kind get clusters | sort)"
namespaces_before="$(kubectl_project get namespaces -o name | sort)"

"${WORKSPACE}" plan --run-id "${RUN_ID}" | grep -q 'result=NO_MUTATION'

set +e
"${WORKSPACE}" init --run-id "${RUN_ID}" >/dev/null 2>&1
no_apply_code=$?
"${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null 2>&1
no_cleanup_code=$?
set -e
[[ ${no_apply_code} -eq 6 ]]
[[ ${no_cleanup_code} -eq 6 ]]

APPLY=true "${WORKSPACE}" init --run-id "${RUN_ID}" >/dev/null
kubectl_project get namespace "${NAMESPACE}" -o 'jsonpath={.metadata.labels.rollout-proof\.dev/run-id}' | grep -Fxq "${RUN_ID}"
"${WORKSPACE}" verify --run-id "${RUN_ID}" | grep -q 'result=PASS'
ALLOW_CLEANUP=true "${WORKSPACE}" cleanup --run-id "${RUN_ID}" >/dev/null

global_after="$(kubectl config current-context 2>/dev/null || printf '<unset>')"
docker_after="$(docker context show)"
clusters_after="$(MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kind@0.32.0 -- kind get clusters | sort)"
namespaces_after="$(kubectl_project get namespaces -o name | sort)"

[[ "${global_before}" == "${global_after}" ]]
[[ "${docker_before}" == "${docker_after}" ]]
[[ "${clusters_before}" == "${clusters_after}" ]]
[[ "${namespaces_before}" == "${namespaces_after}" ]]

printf 'isolation_test: PASS\n'
