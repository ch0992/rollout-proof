#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2

[[ $# -eq 1 ]] || { printf 'usage: %s <artifact-dir>\n' "${0##*/}" >&2; exit "${EXIT_USAGE}"; }
readonly ARTIFACT_DIR="$1"
readonly RESULTS="${ARTIFACT_DIR}/verification.tsv"
readonly METADATA="${ARTIFACT_DIR}/metadata.env"
readonly JSON_REPORT="${ARTIFACT_DIR}/environment-report.json"
readonly MD_REPORT="${ARTIFACT_DIR}/environment-report.md"

[[ -f "${RESULTS}" && -f "${METADATA}" ]] || { printf 'ERROR: verification input missing\n' >&2; exit "${EXIT_USAGE}"; }

meta() {
  local key="$1"
  awk -F= -v key="${key}" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "${METADATA}"
}

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\t'/\\t}
  printf '%s' "${value}"
}

failed_count="$(awk -F '\t' '$2 == "FAIL" { count++ } END { print count+0 }' "${RESULTS}")"
blocked_count="$(awk -F '\t' '$2 == "BLOCKED" { count++ } END { print count+0 }' "${RESULTS}")"
inconclusive_count="$(awk -F '\t' '$2 == "INCONCLUSIVE" { count++ } END { print count+0 }' "${RESULTS}")"

if [[ "${failed_count}" -gt 0 ]]; then
  OVERALL="FAIL"
  EXIT_CODE="$(awk -F '\t' '$2 == "FAIL" { print $3; exit }' "${RESULTS}")"
elif [[ "${inconclusive_count}" -gt 0 ]]; then
  OVERALL="INCONCLUSIVE"
  EXIT_CODE=10
elif [[ "${blocked_count}" -gt 0 ]]; then
  OVERALL="BLOCKED"
  EXIT_CODE=10
else
  OVERALL="READY"
  EXIT_CODE=0
fi
readonly OVERALL EXIT_CODE

checks_json=""
failed_json=""
blocked_json=""
recovery_json=""
while IFS=$'\t' read -r check_id status code message recovery; do
  [[ -n "${check_id}" ]] || continue
  item="{\"id\":\"$(json_escape "${check_id}")\",\"status\":\"$(json_escape "${status}")\",\"exitCode\":${code},\"message\":\"$(json_escape "${message}")\"}"
  checks_json+="${checks_json:+,}${item}"
  [[ "${status}" == "FAIL" ]] && failed_json+="${failed_json:+,}\"$(json_escape "${check_id}")\""
  [[ "${status}" == "BLOCKED" ]] && blocked_json+="${blocked_json:+,}\"$(json_escape "${check_id}")\""
  [[ -n "${recovery}" && "${recovery}" != "-" ]] && recovery_json+="${recovery_json:+,}\"$(json_escape "${recovery}")\""
done <"${RESULTS}"

verification_checksum="$(shasum -a 256 "${RESULTS}" | awk '{print $1}')"

cat >"${JSON_REPORT}" <<JSON
{"schemaVersion":1,"runId":"$(json_escape "$(meta run_id)")","commit":"$(json_escape "$(meta commit)")","startedAt":"$(json_escape "$(meta started_at)")","finishedAt":"$(json_escape "$(meta finished_at)")","hostOS":"$(json_escape "$(meta host_os)")","architecture":"$(json_escape "$(meta architecture)")","toolVersions":{"go":"$(json_escape "$(meta go_version)")","kind":"$(json_escape "$(meta kind_version)")","kubectl":"$(json_escape "$(meta kubectl_version)")"},"containerProvider":"docker-desktop","context":"$(json_escape "$(meta docker_context)")","clusterName":"rolloutproof-dev","serverVersion":"$(json_escape "$(meta server_version)")","kubeconfigPathCategory":"project-work-dir","checks":[${checks_json}],"overallVerdict":"${OVERALL}","exitCode":${EXIT_CODE},"failedChecks":[${failed_json}],"blockedChecks":[${blocked_json}],"recoveryCommands":[${recovery_json}],"artifactChecksums":{"verification.tsv":"${verification_checksum}"}}
JSON

{
  printf '# RolloutProof environment report\n\n'
  # Backticks are intentional Markdown delimiters.
  # shellcheck disable=SC2016
  printf -- '- Run ID: `%s`\n- Commit: `%s`\n- Verdict: `%s`\n- Exit code: `%s`\n- Provider/context: `docker-desktop/%s`\n- Cluster/server: `rolloutproof-dev/%s`\n\n' \
    "$(meta run_id)" "$(meta commit)" "${OVERALL}" "${EXIT_CODE}" "$(meta docker_context)" "$(meta server_version)"
  printf '## Checks\n\n| Check | Status | Message |\n|---|---|---|\n'
  while IFS=$'\t' read -r check_id status _ message _; do
    # Backticks are intentional Markdown delimiters.
    # shellcheck disable=SC2016
    printf '| `%s` | %s | %s |\n' "${check_id}" "${status}" "${message}"
  done <"${RESULTS}"
} >"${MD_REPORT}"

printf 'report_json=%s\nreport_markdown=%s\nverdict=%s\nexit_code=%s\n' "${JSON_REPORT}" "${MD_REPORT}" "${OVERALL}" "${EXIT_CODE}"
exit "${EXIT_CODE}"
