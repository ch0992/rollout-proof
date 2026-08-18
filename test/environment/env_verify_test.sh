#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly RUN_ID="env008-$$"
readonly ARTIFACT_DIR="${REPO_ROOT}/.work/artifacts/environment/${RUN_ID}"
readonly SECRET_MARKER="env008-secret-must-not-leak"

TEST_SECRET="${SECRET_MARKER}" "${REPO_ROOT}/scripts/env/verify.sh" --run-id "${RUN_ID}" >"${REPO_ROOT}/.work/env008-test.out"

grep -q '"overallVerdict":"READY"' "${ARTIFACT_DIR}/environment-report.json"
grep -q '"exitCode":0' "${ARTIFACT_DIR}/environment-report.json"
# Backticks are literal Markdown delimiters.
# shellcheck disable=SC2016
grep -q 'Verdict: `READY`' "${ARTIFACT_DIR}/environment-report.md"
grep -q 'ENV-K8S-003' "${ARTIFACT_DIR}/environment-report.json"

if rg -F "${SECRET_MARKER}" "${ARTIFACT_DIR}"; then
  printf 'secret marker leaked into report\n' >&2
  exit 1
fi

write_fixture_metadata() {
  local dir="$1"
  mkdir -p "${dir}"
  cat >"${dir}/metadata.env" <<'META'
run_id=fixture
commit=fixture
started_at=2026-08-18T00:00:00Z
finished_at=2026-08-18T00:00:01Z
host_os=test
architecture=arm64
go_version=1.26.2
kind_version=0.32.0
kubectl_version=1.36.3
docker_context=desktop-linux
server_version=v1.36.1
META
}

for verdict in BLOCKED INCONCLUSIVE; do
  verdict_lower="$(printf '%s' "${verdict}" | tr '[:upper:]' '[:lower:]')"
  fixture_dir="${REPO_ROOT}/.work/artifacts/environment/env008-${verdict_lower}-$$"
  write_fixture_metadata "${fixture_dir}"
  printf 'ENV-FIXTURE-001\t%s\t10\tfixture status\t-\n' "${verdict}" >"${fixture_dir}/verification.tsv"
  set +e
  "${REPO_ROOT}/scripts/env/report.sh" "${fixture_dir}" >/dev/null
  fixture_code=$?
  set -e
  [[ ${fixture_code} -eq 10 ]]
  grep -q "\"overallVerdict\":\"${verdict}\"" "${fixture_dir}/environment-report.json"
done

fixture_dir="${REPO_ROOT}/.work/artifacts/environment/env008-fail-$$"
write_fixture_metadata "${fixture_dir}"
printf 'ENV-FIXTURE-FAIL\tFAIL\t5\tfixture failure\trecover fixture\n' >"${fixture_dir}/verification.tsv"
set +e
"${REPO_ROOT}/scripts/env/report.sh" "${fixture_dir}" >/dev/null
fixture_code=$?
set -e
[[ ${fixture_code} -eq 5 ]]
grep -q '"overallVerdict":"FAIL"' "${fixture_dir}/environment-report.json"

printf 'env_verify_test: PASS\n'
