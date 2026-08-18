#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

TEST_REPO="${TMP_DIR}/repo"
mkdir -p "${TEST_REPO}/scripts/env" "${TEST_REPO}/.work" "${TMP_DIR}/home" "${TMP_DIR}/bin"
cp "${ROOT_DIR}/scripts/env/activate.sh" "${TEST_REPO}/scripts/env/activate.sh"

cat >"${TEST_REPO}/.work/kubeconfig" <<'EOF'
apiVersion: v1
kind: Config
clusters:
  - name: rolloutproof-dev
    cluster:
      server: https://127.0.0.1:65535
contexts:
  - name: kind-rolloutproof-dev
    context:
      cluster: rolloutproof-dev
      user: rolloutproof-dev
current-context: kind-rolloutproof-dev
users:
  - name: rolloutproof-dev
    user: {}
EOF

cat >"${TMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
kubeconfig=""
if [[ "${1:-}" == --kubeconfig ]]; then kubeconfig="$2"; shift 2; fi
[[ "${1:-}" == config && "${2:-}" == current-context ]] || exit 2
awk '/^current-context:/ { print $2; exit }' "${kubeconfig}"
EOF
chmod +x "${TMP_DIR}/bin/kubectl"

run_shell_test() {
  local shell_bin="$1"
  # The command is intentionally expanded by the child shell, not this test shell.
  # shellcheck disable=SC2016
  HOME="${TMP_DIR}/home" PATH="${TMP_DIR}/bin:${PATH}" "${shell_bin}" -c '
    set -eu
    cd "$HOME"
    export KUBECONFIG=/original/kubeconfig
    export MISE_TRUSTED_CONFIG_PATHS=/original/trust
    . "$1"
    [ "$KUBECONFIG" = "$2/.work/kubeconfig" ]
    [ "$MISE_TRUSTED_CONFIG_PATHS" = "$2:/original/trust" ]
    . "$1"
    rolloutproof-env-deactivate
    [ "$KUBECONFIG" = /original/kubeconfig ]
    [ "$MISE_TRUSTED_CONFIG_PATHS" = /original/trust ]
    [ "${ROLLOUTPROOF_ENV_ACTIVE:-0}" = 0 ]
  ' _ "${TEST_REPO}/scripts/env/activate.sh" "${TEST_REPO}"
}

run_shell_test bash
if command -v zsh >/dev/null 2>&1; then run_shell_test zsh; fi

HOME="${TMP_DIR}/home" PATH="${TMP_DIR}/bin:${PATH}" bash -c '
  set -eu
  unset KUBECONFIG MISE_TRUSTED_CONFIG_PATHS
  . "$1"
  rolloutproof-env-deactivate
  [ "${KUBECONFIG+x}" != x ]
  [ "${MISE_TRUSTED_CONFIG_PATHS+x}" != x ]
' _ "${TEST_REPO}/scripts/env/activate.sh"

sed 's/current-context: kind-rolloutproof-dev/current-context: unexpected-context/' \
  "${TEST_REPO}/.work/kubeconfig" >"${TEST_REPO}/.work/kubeconfig.invalid"
mv "${TEST_REPO}/.work/kubeconfig.invalid" "${TEST_REPO}/.work/kubeconfig"
if HOME="${TMP_DIR}/home" PATH="${TMP_DIR}/bin:${PATH}" bash -c '. "$1"' _ "${TEST_REPO}/scripts/env/activate.sh"; then
  printf 'expected invalid context to fail\n' >&2
  exit 1
fi

rm "${TEST_REPO}/.work/kubeconfig"
if HOME="${TMP_DIR}/home" PATH="${TMP_DIR}/bin:${PATH}" bash -c '. "$1"' _ "${TEST_REPO}/scripts/env/activate.sh"; then
  printf 'expected missing kubeconfig to fail\n' >&2
  exit 1
fi

if bash "${TEST_REPO}/scripts/env/activate.sh" >/dev/null 2>&1; then
  printf 'expected direct execution to fail\n' >&2
  exit 1
fi

printf 'activate_test: PASS\n'
