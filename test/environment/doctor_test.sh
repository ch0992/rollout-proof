#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly DOCTOR="${REPO_ROOT}/scripts/env/dev-doctor.sh"
readonly PROVIDER="${REPO_ROOT}/scripts/env/provider.sh"

TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/bin" "${TMP_DIR}/adapters"

cat >"${TMP_DIR}/bin/docker" <<'MOCK'
#!/usr/bin/env bash
case "$1 $2" in
  "version --format") printf '29.1.2\n' ;;
  "context show") printf 'desktop-linux\n' ;;
  "info --format") printf '29.1.2\n' ;;
  *) exit 99 ;;
esac
MOCK
chmod +x "${TMP_DIR}/bin/docker"

cat >"${TMP_DIR}/adapters/docker-desktop.sh" <<'MOCK'
provider_check() { printf 'check:%s\n' "${1:-none}"; }
provider_plan() { printf 'plan\n'; }
provider_start() { printf 'start\n'; }
provider_wait() { printf 'wait\n'; }
provider_inspect() { printf 'inspect\n'; }
provider_stop() { printf 'stop\n'; }
MOCK

PATH="${TMP_DIR}/bin:/usr/bin:/bin" "${DOCTOR}" --format json --provider docker-desktop >"${TMP_DIR}/doctor.json"
grep -q '"verdict":"READY"' "${TMP_DIR}/doctor.json"
grep -q '"context":"desktop-linux"' "${TMP_DIR}/doctor.json"

PATH="${TMP_DIR}/bin:/usr/bin:/bin" "${DOCTOR}" --format markdown --provider docker-desktop >"${TMP_DIR}/doctor.md"
# Backticks are literal Markdown delimiters.
# shellcheck disable=SC2016
grep -q 'Verdict: `READY`' "${TMP_DIR}/doctor.md"

set +e
PATH="/usr/bin:/bin" "${DOCTOR}" --provider docker-desktop >"${TMP_DIR}/missing.json"
missing_code=$?
"${DOCTOR}" --provider invalid >"${TMP_DIR}/invalid.out" 2>"${TMP_DIR}/invalid.err"
invalid_code=$?
set -e
[[ ${missing_code} -eq 3 ]]
[[ ${invalid_code} -eq 2 ]]
grep -q '"reason":"tool_missing"' "${TMP_DIR}/missing.json"

for operation in check plan start wait inspect stop; do
  PROVIDER_ADAPTER_DIR="${TMP_DIR}/adapters" "${PROVIDER}" docker-desktop "${operation}" >/dev/null
done

printf 'doctor_test: PASS\n'
