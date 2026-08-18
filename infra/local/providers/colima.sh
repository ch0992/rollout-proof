#!/usr/bin/env bash

# Sourced by scripts/env/provider.sh. Only the rolloutproof profile is owned.

readonly COLIMA_EXIT_TOOL=3
readonly COLIMA_EXIT_PROVIDER=4
readonly COLIMA_EXIT_SAFETY=6
readonly COLIMA_PROFILE="rolloutproof"
readonly COLIMA_CONTEXT="colima-${COLIMA_PROFILE}"
readonly COLIMA_CONFIG_SOURCE="${REPO_ROOT}/infra/local/providers/colima.yaml"
readonly COLIMA_STATE_ROOT="${COLIMA_HOME:-${HOME}/.colima}"
readonly COLIMA_PROFILE_DIR="${COLIMA_STATE_ROOT}/${COLIMA_PROFILE}"
readonly COLIMA_CONFIG_TARGET="${COLIMA_PROFILE_DIR}/colima.yaml"

colima_cli() {
  colima "$@" --profile "${COLIMA_PROFILE}"
}

config_valid() {
  [[ -f "${COLIMA_CONFIG_SOURCE}" ]] || return 1
  grep -Eq '^runtime:[[:space:]]+docker$' "${COLIMA_CONFIG_SOURCE}" &&
    grep -Eq '^autoActivate:[[:space:]]+false$' "${COLIMA_CONFIG_SOURCE}" &&
    awk '
      /^kubernetes:/ { in_kubernetes = 1; next }
      in_kubernetes && /^[^ ]/ { exit }
      in_kubernetes && /^[[:space:]]+enabled:[[:space:]]+false$/ { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "${COLIMA_CONFIG_SOURCE}"
}

config_matches() {
  [[ -f "${COLIMA_CONFIG_TARGET}" ]] && cmp -s "${COLIMA_CONFIG_SOURCE}" "${COLIMA_CONFIG_TARGET}"
}

profile_running() {
  colima_cli status >/dev/null 2>&1
}

provider_check() {
  command -v colima >/dev/null 2>&1 || {
    printf 'provider=colima status=NOT_READY reason=tool_missing recovery="brew install colima"\n' >&2
    return "${COLIMA_EXIT_TOOL}"
  }
  config_valid || {
    printf 'provider=colima status=NOT_READY reason=invalid_project_config\n' >&2
    return "${COLIMA_EXIT_SAFETY}"
  }
  [[ -d "${COLIMA_PROFILE_DIR}" ]] || {
    printf 'provider=colima status=NOT_READY reason=profile_absent recovery="APPLY=true scripts/env/provider.sh colima start"\n' >&2
    return "${COLIMA_EXIT_PROVIDER}"
  }
  config_matches || {
    printf 'provider=colima status=NOT_READY reason=config_drift recovery="inspect %s; automatic overwrite is disabled"\n' "${COLIMA_CONFIG_TARGET}" >&2
    return "${COLIMA_EXIT_SAFETY}"
  }
  profile_running || {
    printf 'provider=colima status=NOT_READY reason=profile_stopped recovery="APPLY=true scripts/env/provider.sh colima start"\n' >&2
    return "${COLIMA_EXIT_PROVIDER}"
  }
  DOCKER_CONTEXT="${COLIMA_CONTEXT}" docker info >/dev/null 2>&1 || {
    printf 'provider=colima status=NOT_READY reason=daemon_unavailable context=%s\n' "${COLIMA_CONTEXT}" >&2
    return "${COLIMA_EXIT_PROVIDER}"
  }
  printf 'provider=colima status=READY profile=%s context=%s kubernetes=disabled\n' "${COLIMA_PROFILE}" "${COLIMA_CONTEXT}"
}

provider_plan() {
  printf 'provider=colima mode=plan profile=%s config=%s kubernetes=disabled auto_activate=false\n' \
    "${COLIMA_PROFILE}" "${COLIMA_CONFIG_SOURCE}"
  if provider_check >/dev/null 2>&1; then
    printf 'result=NO_CHANGE\n'
  elif [[ -d "${COLIMA_PROFILE_DIR}" && ! -f "${COLIMA_CONFIG_TARGET}" ]]; then
    printf 'result=DRIFT action=FAIL_WITHOUT_OVERWRITE\n'
  else
    printf 'result=START_REQUIRES_APPLY_TRUE\n'
  fi
}

provider_start() {
  [[ "${APPLY:-false}" == "true" ]] || { printf 'ERROR: Colima start requires APPLY=true\n' >&2; return "${COLIMA_EXIT_SAFETY}"; }
  command -v colima >/dev/null 2>&1 || { printf 'ERROR: Colima is missing; brew install colima\n' >&2; return "${COLIMA_EXIT_TOOL}"; }
  config_valid || { printf 'ERROR: project Colima config is invalid\n' >&2; return "${COLIMA_EXIT_SAFETY}"; }
  if [[ -d "${COLIMA_PROFILE_DIR}" ]]; then
    config_matches || { printf 'ERROR: existing rolloutproof profile config drift; refusing overwrite\n' >&2; return "${COLIMA_EXIT_SAFETY}"; }
  else
    mkdir -p "${COLIMA_PROFILE_DIR}"
    cp "${COLIMA_CONFIG_SOURCE}" "${COLIMA_CONFIG_TARGET}"
  fi
  if profile_running; then
    printf 'result=NO_CHANGE reason=already_running\n'
  else
    colima_cli start
  fi
  provider_check
}

provider_wait() {
  local timeout="${1:-120}" interval="${PROVIDER_WAIT_INTERVAL:-2}"
  [[ "${timeout}" =~ ^[0-9]+$ ]] || { printf 'ERROR: timeout must be an integer\n' >&2; return 2; }
  local deadline=$((SECONDS + timeout))
  while (( SECONDS <= deadline )); do
    if provider_check >/dev/null 2>&1; then provider_check; return 0; fi
    sleep "${interval}"
  done
  printf 'provider=colima status=NOT_READY reason=wait_timeout\n' >&2
  return "${COLIMA_EXIT_PROVIDER}"
}

provider_inspect() {
  provider_check >/dev/null
  printf '{"provider":"colima","status":"READY","profile":"%s","context":"%s","kubernetes":"disabled","config":"project-owned"}\n' \
    "${COLIMA_PROFILE}" "${COLIMA_CONTEXT}"
}

provider_stop() {
  [[ "${ALLOW_STOP:-false}" == "true" ]] || { printf 'ERROR: Colima stop requires ALLOW_STOP=true\n' >&2; return "${COLIMA_EXIT_SAFETY}"; }
  [[ -d "${COLIMA_PROFILE_DIR}" ]] || { printf 'result=NO_CHANGE reason=profile_absent\n'; return 0; }
  config_matches || { printf 'ERROR: ownership config mismatch; refusing stop\n' >&2; return "${COLIMA_EXIT_SAFETY}"; }
  if profile_running; then colima_cli stop; else printf 'result=NO_CHANGE reason=already_stopped\n'; fi
}
