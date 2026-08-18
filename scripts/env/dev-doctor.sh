#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2
readonly EXIT_TOOL=3
readonly EXIT_PROVIDER=4

FORMAT="json"
PROVIDER="docker-desktop"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      [[ $# -ge 2 ]] || { printf 'ERROR: --format requires a value\n' >&2; exit "${EXIT_USAGE}"; }
      FORMAT="$2"
      shift 2
      ;;
    --provider)
      [[ $# -ge 2 ]] || { printf 'ERROR: --provider requires a value\n' >&2; exit "${EXIT_USAGE}"; }
      PROVIDER="$2"
      shift 2
      ;;
    -h|--help)
      printf 'usage: %s [--format json|markdown] [--provider docker-desktop|colima]\n' "${0##*/}"
      exit 0
      ;;
    *)
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      exit "${EXIT_USAGE}"
      ;;
  esac
done

case "${FORMAT}" in json|markdown) ;; *) printf 'ERROR: unsupported format: %s\n' "${FORMAT}" >&2; exit "${EXIT_USAGE}" ;; esac
case "${PROVIDER}" in docker-desktop|colima) ;; *) printf 'ERROR: unsupported provider: %s\n' "${PROVIDER}" >&2; exit "${EXIT_USAGE}" ;; esac

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  printf '%s' "${value}"
}

emit() {
  local verdict="$1" code="$2" reason="$3" tool="$4" version="$5" context="$6" daemon="$7"
  if [[ "${FORMAT}" == "json" ]]; then
    printf '{"schema_version":1,"verdict":"%s","exit_code":%s,"provider":"%s","platform":"%s","reason":"%s","tool":"%s","version":"%s","context":"%s","daemon":"%s"}\n' \
      "$(json_escape "${verdict}")" "${code}" "$(json_escape "${PROVIDER}")" "$(json_escape "$(uname -s)/$(uname -m)")" \
      "$(json_escape "${reason}")" "$(json_escape "${tool}")" "$(json_escape "${version}")" "$(json_escape "${context}")" "$(json_escape "${daemon}")"
  else
    printf '# RolloutProof development doctor\n\n'
    # Backticks are intentional Markdown delimiters, not shell expressions.
    # shellcheck disable=SC2016
    printf -- '- Verdict: `%s`\n- Exit code: `%s`\n- Provider: `%s`\n- Platform: `%s`\n- Reason: `%s`\n- Tool: `%s`\n- Version: `%s`\n- Context: `%s`\n- Daemon: `%s`\n' \
      "${verdict}" "${code}" "${PROVIDER}" "$(uname -s)/$(uname -m)" "${reason}" "${tool}" "${version}" "${context}" "${daemon}"
  fi
}

if [[ "${PROVIDER}" == "docker-desktop" ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    emit NOT_READY "${EXIT_TOOL}" tool_missing docker unknown unknown unknown
    exit "${EXIT_TOOL}"
  fi
  VERSION="$(docker version --format '{{.Client.Version}}' 2>/dev/null || true)"
  CONTEXT="$(docker context show 2>/dev/null || true)"
  DAEMON="$(docker info --format '{{.ServerVersion}}' 2>/dev/null || true)"
  if [[ -z "${DAEMON}" ]]; then
    emit NOT_READY "${EXIT_PROVIDER}" daemon_unavailable docker "${VERSION:-unknown}" "${CONTEXT:-unknown}" unavailable
    exit "${EXIT_PROVIDER}"
  fi
  emit READY 0 ok docker "${VERSION:-unknown}" "${CONTEXT:-unknown}" ready
  exit 0
fi

if ! command -v colima >/dev/null 2>&1; then
  emit NOT_READY "${EXIT_TOOL}" tool_missing colima unknown rolloutproof unknown
  exit "${EXIT_TOOL}"
fi

VERSION="$(colima version 2>/dev/null | head -n 1 || true)"
if ! colima status --profile rolloutproof >/dev/null 2>&1; then
  emit NOT_READY "${EXIT_PROVIDER}" profile_not_running colima "${VERSION:-unknown}" rolloutproof unavailable
  exit "${EXIT_PROVIDER}"
fi
emit READY 0 ok colima "${VERSION:-unknown}" rolloutproof ready
