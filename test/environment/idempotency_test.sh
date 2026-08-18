#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly KIND_SCRIPT="${REPO_ROOT}/scripts/env/kind.sh"

kind_project() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kind@0.32.0 -- kind "$@"
}

kubectl_project() {
  MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec kubectl@1.36.3 -- kubectl --kubeconfig "${REPO_ROOT}/.work/kubeconfig" "$@"
}

snapshot() {
  printf 'clusters=%s\n' "$(kind_project get clusters | sort | paste -sd, -)"
  printf 'containers=%s\n' "$(docker ps -aq --filter 'name=rolloutproof-dev' | sort | paste -sd, -)"
  printf 'nodes=%s\n' "$(kubectl_project get nodes -o 'jsonpath={range .items[*]}{.metadata.name}:{.metadata.uid}{"\\n"}{end}' | sort | paste -sd, -)"
  printf 'global=%s\n' "$(kubectl config current-context 2>/dev/null || printf '<unset>')"
  printf 'docker=%s\n' "$(docker context show)"
}

before="$(snapshot)"
first="$(APPLY=true "${KIND_SCRIPT}" up --minor 1.36)"
middle="$(snapshot)"
second="$(APPLY=true "${KIND_SCRIPT}" up --minor 1.36)"
after="$(snapshot)"

[[ "${before}" == "${middle}" ]]
[[ "${middle}" == "${after}" ]]
grep -q 'status=READY' <<<"${first}"
grep -q 'status=READY' <<<"${second}"

printf 'idempotency_test: PASS\n'
