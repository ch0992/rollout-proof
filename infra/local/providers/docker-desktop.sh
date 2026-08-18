#!/usr/bin/env bash

# Sourced by scripts/env/provider.sh. This adapter intentionally never changes
# Docker Desktop settings, contexts, containers, images, or application state.

readonly DD_EXIT_TOOL=3
readonly DD_EXIT_PROVIDER=4
readonly DD_EXPECTED_CONTEXT="desktop-linux"

dd_recovery() {
  local reason="$1"
  case "${reason}" in
    tool_missing)
      printf 'recovery: install or start Docker Desktop manually, then rerun provider check\n' >&2
      ;;
    context_mismatch)
      printf 'recovery: select the desktop-linux Docker context manually, then rerun provider check\n' >&2
      ;;
    daemon_unavailable)
      printf 'recovery: open Docker Desktop and wait for the engine to become ready\n' >&2
      ;;
  esac
}

dd_client_version() {
  docker version --format '{{.Client.Version}}' 2>/dev/null || true
}

dd_context() {
  docker context show 2>/dev/null || true
}

dd_server_version() {
  docker info --format '{{.ServerVersion}}' 2>/dev/null || true
}

provider_check() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'provider=docker-desktop status=NOT_READY reason=tool_missing\n' >&2
    dd_recovery tool_missing
    return "${DD_EXIT_TOOL}"
  fi

  local context
  context="$(dd_context)"
  if [[ "${context}" != "${DD_EXPECTED_CONTEXT}" ]]; then
    printf 'provider=docker-desktop status=NOT_READY reason=context_mismatch expected=%s actual=%s\n' \
      "${DD_EXPECTED_CONTEXT}" "${context:-none}" >&2
    dd_recovery context_mismatch
    return "${DD_EXIT_PROVIDER}"
  fi

  local server_version
  server_version="$(dd_server_version)"
  if [[ -z "${server_version}" ]]; then
    printf 'provider=docker-desktop status=NOT_READY reason=daemon_unavailable context=%s\n' "${context}" >&2
    dd_recovery daemon_unavailable
    return "${DD_EXIT_PROVIDER}"
  fi

  printf 'provider=docker-desktop status=READY context=%s client=%s server=%s\n' \
    "${context}" "$(dd_client_version)" "${server_version}"
}

provider_plan() {
  printf 'provider=docker-desktop mode=plan mutation=none\n'
  if provider_check >/dev/null 2>&1; then
    printf 'result=NO_CHANGE reason=already_ready\n'
  else
    printf 'result=MANUAL_ACTION_REQUIRED action="start Docker Desktop and select desktop-linux"\n'
  fi
}

provider_start() {
  if provider_check; then
    printf 'result=NO_CHANGE reason=already_ready\n'
    return 0
  fi
  printf 'result=MANUAL_ACTION_REQUIRED reason=docker_desktop_not_project_owned\n' >&2
  return "${DD_EXIT_PROVIDER}"
}

provider_wait() {
  local timeout="${1:-60}"
  local interval="${PROVIDER_WAIT_INTERVAL:-2}"
  [[ "${timeout}" =~ ^[0-9]+$ ]] || {
    printf 'ERROR: wait timeout must be an integer\n' >&2
    return 2
  }

  local deadline=$((SECONDS + timeout))
  while (( SECONDS <= deadline )); do
    if provider_check >/dev/null 2>&1; then
      provider_check
      return 0
    fi
    sleep "${interval}"
  done
  printf 'provider=docker-desktop status=NOT_READY reason=wait_timeout timeout=%s\n' "${timeout}" >&2
  dd_recovery daemon_unavailable
  return "${DD_EXIT_PROVIDER}"
}

provider_inspect() {
  provider_check >/dev/null
  printf '{"provider":"docker-desktop","status":"READY","context":"%s","client_version":"%s","server_version":"%s","mutation":"none"}\n' \
    "$(dd_context)" "$(dd_client_version)" "$(dd_server_version)"
}

provider_stop() {
  printf 'provider=docker-desktop result=SKIPPED reason=not_project_owned mutation=none\n'
}
