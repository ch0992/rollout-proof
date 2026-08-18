#!/usr/bin/env bash

# This file must be sourced so it can update and later restore the caller's shell.
if ! (return 0 2>/dev/null); then
  printf 'ERROR: source this file instead of executing it: source scripts/env/activate.sh\n' >&2
  exit 2
fi

if [ -n "${BASH_VERSION:-}" ]; then
  _rolloutproof_source="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _rolloutproof_source="${(%):-%x}"
else
  printf 'ERROR: supported shells are bash and zsh\n' >&2
  return 2
fi

_rolloutproof_root="$(cd "$(dirname "${_rolloutproof_source}")/../.." && pwd)"
_rolloutproof_kubeconfig="${_rolloutproof_root}/.work/kubeconfig"
_rolloutproof_expected_context="kind-rolloutproof-dev"

if [ ! -f "${_rolloutproof_kubeconfig}" ]; then
  printf 'ERROR: project kubeconfig is missing: %s\n' "${_rolloutproof_kubeconfig}" >&2
  printf 'RECOVERY: APPLY=true %s/scripts/env/kind.sh up --minor 1.36\n' "${_rolloutproof_root}" >&2
  unset _rolloutproof_source _rolloutproof_root _rolloutproof_kubeconfig _rolloutproof_expected_context
  return 5
fi

if ! command -v kubectl >/dev/null 2>&1; then
  printf 'ERROR: kubectl is not available on PATH\n' >&2
  unset _rolloutproof_source _rolloutproof_root _rolloutproof_kubeconfig _rolloutproof_expected_context
  return 3
fi

_rolloutproof_context="$(kubectl --kubeconfig "${_rolloutproof_kubeconfig}" config current-context 2>/dev/null)"
if [ "${_rolloutproof_context}" != "${_rolloutproof_expected_context}" ]; then
  printf 'ERROR: expected context %s, got %s\n' \
    "${_rolloutproof_expected_context}" "${_rolloutproof_context:-<unset>}" >&2
  unset _rolloutproof_source _rolloutproof_root _rolloutproof_kubeconfig _rolloutproof_expected_context _rolloutproof_context
  return 5
fi

if [ "${ROLLOUTPROOF_ENV_ACTIVE:-0}" != 1 ]; then
  if [ "${KUBECONFIG+x}" = x ]; then
    ROLLOUTPROOF_PREVIOUS_KUBECONFIG_SET=1
    ROLLOUTPROOF_PREVIOUS_KUBECONFIG="${KUBECONFIG}"
  else
    ROLLOUTPROOF_PREVIOUS_KUBECONFIG_SET=0
    ROLLOUTPROOF_PREVIOUS_KUBECONFIG=""
  fi
  if [ "${MISE_TRUSTED_CONFIG_PATHS+x}" = x ]; then
    ROLLOUTPROOF_PREVIOUS_MISE_TRUST_SET=1
    ROLLOUTPROOF_PREVIOUS_MISE_TRUST="${MISE_TRUSTED_CONFIG_PATHS}"
  else
    ROLLOUTPROOF_PREVIOUS_MISE_TRUST_SET=0
    ROLLOUTPROOF_PREVIOUS_MISE_TRUST=""
  fi
fi

KUBECONFIG="${_rolloutproof_kubeconfig}"
MISE_TRUSTED_CONFIG_PATHS="${_rolloutproof_root}${ROLLOUTPROOF_PREVIOUS_MISE_TRUST:+:${ROLLOUTPROOF_PREVIOUS_MISE_TRUST}}"
ROLLOUTPROOF_ENV_ACTIVE=1
export KUBECONFIG MISE_TRUSTED_CONFIG_PATHS ROLLOUTPROOF_ENV_ACTIVE
export ROLLOUTPROOF_PREVIOUS_KUBECONFIG_SET ROLLOUTPROOF_PREVIOUS_KUBECONFIG
export ROLLOUTPROOF_PREVIOUS_MISE_TRUST_SET ROLLOUTPROOF_PREVIOUS_MISE_TRUST

rolloutproof-env-deactivate() {
  if [ "${ROLLOUTPROOF_PREVIOUS_KUBECONFIG_SET:-0}" = 1 ]; then
    KUBECONFIG="${ROLLOUTPROOF_PREVIOUS_KUBECONFIG}"
    export KUBECONFIG
  else
    unset KUBECONFIG
  fi
  if [ "${ROLLOUTPROOF_PREVIOUS_MISE_TRUST_SET:-0}" = 1 ]; then
    MISE_TRUSTED_CONFIG_PATHS="${ROLLOUTPROOF_PREVIOUS_MISE_TRUST}"
    export MISE_TRUSTED_CONFIG_PATHS
  else
    unset MISE_TRUSTED_CONFIG_PATHS
  fi
  unset ROLLOUTPROOF_ENV_ACTIVE
  unset ROLLOUTPROOF_PREVIOUS_KUBECONFIG_SET ROLLOUTPROOF_PREVIOUS_KUBECONFIG
  unset ROLLOUTPROOF_PREVIOUS_MISE_TRUST_SET ROLLOUTPROOF_PREVIOUS_MISE_TRUST
  unset -f rolloutproof-env-deactivate 2>/dev/null || true
  printf 'RolloutProof environment deactivated\n'
}

printf 'RolloutProof environment active: context=%s kubeconfig=%s\n' \
  "${_rolloutproof_context}" "${KUBECONFIG}"
unset _rolloutproof_source _rolloutproof_root _rolloutproof_kubeconfig _rolloutproof_expected_context _rolloutproof_context
