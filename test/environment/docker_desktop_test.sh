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

cat >"${TMP_DIR}/bin/docker" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DOCKER_CALL_LOG}"
case "$1 $2" in
  "version --format") printf '29.1.2\n' ;;
  "context show") printf '%s\n' "${MOCK_DOCKER_CONTEXT:-desktop-linux}" ;;
  "info --format") [[ "${MOCK_DAEMON_READY:-true}" == "true" ]] && printf '29.1.2\n' || exit 1 ;;
  *) exit 99 ;;
esac
MOCK
chmod +x "${TMP_DIR}/bin/docker"

export PATH="${TMP_DIR}/bin:/usr/bin:/bin"
export DOCKER_CALL_LOG="${TMP_DIR}/docker-calls.log"
touch "${DOCKER_CALL_LOG}"

"${PROVIDER}" docker-desktop check >"${TMP_DIR}/check.out"
grep -q 'status=READY' "${TMP_DIR}/check.out"
grep -q 'context=desktop-linux' "${TMP_DIR}/check.out"

"${PROVIDER}" docker-desktop plan >"${TMP_DIR}/plan.out"
grep -q 'mutation=none' "${TMP_DIR}/plan.out"
grep -q 'result=NO_CHANGE' "${TMP_DIR}/plan.out"

"${PROVIDER}" docker-desktop wait 0 >"${TMP_DIR}/wait.out"
grep -q 'status=READY' "${TMP_DIR}/wait.out"

"${PROVIDER}" docker-desktop inspect >"${TMP_DIR}/inspect.json"
grep -q '"context":"desktop-linux"' "${TMP_DIR}/inspect.json"
grep -q '"mutation":"none"' "${TMP_DIR}/inspect.json"

"${PROVIDER}" docker-desktop stop >"${TMP_DIR}/stop.out"
grep -q 'result=SKIPPED' "${TMP_DIR}/stop.out"

set +e
MOCK_DOCKER_CONTEXT=default "${PROVIDER}" docker-desktop check >"${TMP_DIR}/mismatch.out" 2>"${TMP_DIR}/mismatch.err"
mismatch_code=$?
MOCK_DAEMON_READY=false "${PROVIDER}" docker-desktop check >"${TMP_DIR}/daemon.out" 2>"${TMP_DIR}/daemon.err"
daemon_code=$?
set -e

[[ ${mismatch_code} -eq 4 ]]
[[ ${daemon_code} -eq 4 ]]
grep -q 'select the desktop-linux Docker context manually' "${TMP_DIR}/mismatch.err"
grep -q 'open Docker Desktop' "${TMP_DIR}/daemon.err"

if grep -Eq '(^| )(rm|rmi|prune|context use|system prune)( |$)' "${DOCKER_CALL_LOG}"; then
  printf 'unexpected mutating Docker command\n' >&2
  exit 1
fi

printf 'docker_desktop_test: PASS\n'
