#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2
readonly EXIT_PROVIDER=4

usage() {
  printf 'usage: %s <docker-desktop|colima> <check|plan|start|wait|inspect|stop> [args...]\n' "${0##*/}" >&2
}

[[ $# -ge 2 ]] || {
  usage
  exit "${EXIT_USAGE}"
}

readonly PROVIDER="$1"
readonly OPERATION="$2"
shift 2

case "${PROVIDER}" in
  docker-desktop|colima) ;;
  *)
    printf 'ERROR: unsupported provider: %s\n' "${PROVIDER}" >&2
    exit "${EXIT_USAGE}"
    ;;
esac

case "${OPERATION}" in
  check|plan|start|wait|inspect|stop) ;;
  *)
    printf 'ERROR: unsupported operation: %s\n' "${OPERATION}" >&2
    exit "${EXIT_USAGE}"
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly ADAPTER_DIR="${PROVIDER_ADAPTER_DIR:-${REPO_ROOT}/infra/local/providers}"
readonly ADAPTER="${ADAPTER_DIR}/${PROVIDER}.sh"

if [[ ! -f "${ADAPTER}" ]]; then
  printf 'ERROR: provider adapter is not implemented: %s\n' "${PROVIDER}" >&2
  exit "${EXIT_PROVIDER}"
fi

# shellcheck source=/dev/null
source "${ADAPTER}"

readonly FUNCTION_NAME="provider_${OPERATION}"
if ! declare -F "${FUNCTION_NAME}" >/dev/null 2>&1; then
  printf 'ERROR: adapter %s does not implement %s\n' "${PROVIDER}" "${OPERATION}" >&2
  exit "${EXIT_PROVIDER}"
fi

"${FUNCTION_NAME}" "$@"
