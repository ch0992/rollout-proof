#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly PROVIDER="${REPO_ROOT}/scripts/env/provider.sh"

TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
trap 'rm -rf "${TMP_DIR}"' EXIT
mkdir -p "${TMP_DIR}/bin"
export COLIMA_HOME="${TMP_DIR}/state"
export MOCK_LOG="${TMP_DIR}/calls.log"

cat >"${TMP_DIR}/bin/colima" <<'MOCK'
#!/usr/bin/env bash
printf 'colima %s\n' "$*" >>"${MOCK_LOG}"
case "$1" in
  status) [[ -f "${COLIMA_HOME}/rolloutproof/running" ]] ;;
  start) touch "${COLIMA_HOME}/rolloutproof/running" ;;
  stop) rm -f "${COLIMA_HOME}/rolloutproof/running" ;;
  *) exit 99 ;;
esac
MOCK
cat >"${TMP_DIR}/bin/docker" <<'MOCK'
#!/usr/bin/env bash
printf 'docker context=%s args=%s\n' "${DOCKER_CONTEXT:-unset}" "$*" >>"${MOCK_LOG}"
[[ "${DOCKER_CONTEXT:-}" == "colima-rolloutproof" && "$1" == "info" ]]
MOCK
chmod +x "${TMP_DIR}/bin/colima" "${TMP_DIR}/bin/docker"
export PATH="${TMP_DIR}/bin:/usr/bin:/bin"

"${PROVIDER}" colima plan | grep -q 'START_REQUIRES_APPLY_TRUE'
set +e
"${PROVIDER}" colima start >/dev/null 2>&1
no_apply_code=$?
set -e
[[ ${no_apply_code} -eq 6 ]]

APPLY=true "${PROVIDER}" colima start >"${TMP_DIR}/start.out"
grep -q 'status=READY' "${TMP_DIR}/start.out"
grep -q '^kubernetes:$' "${COLIMA_HOME}/rolloutproof/colima.yaml"
grep -q 'enabled: false' "${COLIMA_HOME}/rolloutproof/colima.yaml"
grep -q '^autoActivate: false$' "${COLIMA_HOME}/rolloutproof/colima.yaml"

"${PROVIDER}" colima check >/dev/null
"${PROVIDER}" colima wait 0 >/dev/null
"${PROVIDER}" colima inspect | grep -q '"profile":"rolloutproof"'

mkdir -p "${COLIMA_HOME}/unrelated"
printf 'preserve\n' >"${COLIMA_HOME}/unrelated/marker"
set +e
"${PROVIDER}" colima stop >/dev/null 2>&1
no_stop_code=$?
set -e
[[ ${no_stop_code} -eq 6 ]]
ALLOW_STOP=true "${PROVIDER}" colima stop
grep -Fxq preserve "${COLIMA_HOME}/unrelated/marker"

if grep -Eq -- '--profile (default|unrelated)| delete |docker context use' "${MOCK_LOG}"; then
  printf 'adapter touched an unrelated target\n' >&2
  exit 1
fi

printf 'colima_test: PASS\n'
