#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAKEFILE="${ROOT_DIR}/Makefile"

required_targets=(env-check env-plan env-bootstrap runtime-up cluster-up cluster-down env-verify env-report)
for target in "${required_targets[@]}"; do
  grep -Eq "^${target}:" "${MAKEFILE}" || { printf 'missing target: %s\n' "${target}" >&2; exit 1; }
done

plan_output="$(make -C "${ROOT_DIR}" --dry-run env-check env-plan)"
grep -q 'scripts/env/bootstrap.sh' <<<"${plan_output}"
grep -q 'scripts/env/dev-doctor.sh' <<<"${plan_output}"
grep -q 'scripts/env/provider.sh.* plan' <<<"${plan_output}"
grep -q 'scripts/env/kind.sh plan' <<<"${plan_output}"
if grep -Eq 'APPLY=true.*(bootstrap|provider)' <<<"${plan_output}"; then
  printf 'read-only target leaked apply opt-in\n' >&2
  exit 1
fi

# Make variables are intentionally matched literally.
# shellcheck disable=SC2016
grep -q 'APPLY="$(APPLY)" scripts/env/bootstrap.sh' "${MAKEFILE}"
# shellcheck disable=SC2016
grep -q 'ALLOW_DELETE="$(ALLOW_DELETE)" scripts/env/kind.sh down' "${MAKEFILE}"
grep -q 'APPLY=true scripts/env/kind.sh up' "${MAKEFILE}"
grep -q 'last-environment-run-id' "${MAKEFILE}"

help_output="$(make -C "${ROOT_DIR}" help)"
for target in "${required_targets[@]}"; do grep -q "${target}" <<<"${help_output}"; done

printf 'make_targets_test: PASS\n'
