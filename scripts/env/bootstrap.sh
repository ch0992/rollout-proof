#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly MANIFEST="${REPO_ROOT}/infra/local/tool-versions.yaml"
readonly BREWFILE="${REPO_ROOT}/Brewfile"
readonly APPLY="${APPLY:-false}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

manifest_value() {
  local tool="$1"
  local field="$2"
  awk -v tool="${tool}" -v field="${field}" '
    $0 == "  " tool ":" { in_tool = 1; next }
    in_tool && $0 ~ "^    " field ":" {
      sub("^    " field ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
    in_tool && $0 ~ /^  [a-zA-Z0-9_-]+:/ { exit }
  ' "${MANIFEST}"
}

checksum_source() {
  local tool="$1"
  local platform="$2"
  awk -v tool="${tool}" -v platform="${platform}" '
    $0 == "  " tool ":" { in_tool = 1; next }
    in_tool && $0 == "    checksum_source:" { in_checksums = 1; next }
    in_checksums && $0 ~ "^      " platform ":" {
      sub("^      " platform ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
    in_tool && $0 ~ /^  [a-zA-Z0-9_-]+:/ { exit }
  ' "${MANIFEST}"
}

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) readonly PLATFORM="darwin_arm64" ;;
  Darwin-x86_64) readonly PLATFORM="darwin_amd64" ;;
  *) fail "unsupported platform: $(uname -s)-$(uname -m)" ;;
esac

[[ -f "${MANIFEST}" ]] || fail "manifest not found: ${MANIFEST}"
[[ -f "${BREWFILE}" ]] || fail "Brewfile not found: ${BREWFILE}"
command -v brew >/dev/null 2>&1 || fail "Homebrew is required; install it manually from https://brew.sh/"

GO_VERSION="$(manifest_value go version)"
readonly GO_VERSION
KIND_VERSION="$(manifest_value kind version)"
readonly KIND_VERSION
KUBECTL_VERSION="$(manifest_value kubectl version)"
readonly KUBECTL_VERSION

for tool in go kind kubectl; do
  version="$(manifest_value "${tool}" version)"
  checksum="$(checksum_source "${tool}" "${PLATFORM}")"
  [[ -n "${version}" ]] || fail "missing version for ${tool}"
  [[ "${checksum}" == https://* ]] || fail "missing checksum source for ${tool}/${PLATFORM}"
done

printf 'task=ENV-002 mode=%s platform=%s\n' "$([[ "${APPLY}" == "true" ]] && printf apply || printf plan)" "${PLATFORM}"
printf 'manifest=%s\n' "${MANIFEST}"
printf 'plan: brew bundle --file %s --no-lock\n' "${BREWFILE}"
printf 'plan: mise install go@%s kind@%s kubectl@%s\n' "${GO_VERSION}" "${KIND_VERSION}" "${KUBECTL_VERSION}"

if [[ "${APPLY}" != "true" ]]; then
  printf 'result=PLAN_ONLY hint="rerun with APPLY=true to install"\n'
  exit 0
fi

brew bundle --file "${BREWFILE}" --no-lock
command -v mise >/dev/null 2>&1 || fail "mise was not installed by Homebrew"
mise install "go@${GO_VERSION}" "kind@${KIND_VERSION}" "kubectl@${KUBECTL_VERSION}"

mise exec "go@${GO_VERSION}" -- go version
mise exec "kind@${KIND_VERSION}" -- kind version
mise exec "kubectl@${KUBECTL_VERSION}" -- kubectl version --client
printf 'result=APPLIED\n'
