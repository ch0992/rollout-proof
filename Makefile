SHELL := /bin/bash
.DEFAULT_GOAL := help

CONTAINER_PROVIDER ?= docker-desktop
K8S_MINOR ?= 1.36
RUN_ID ?=
APPLY ?= false
ALLOW_DELETE ?= false
LAST_ENV_RUN := .work/last-environment-run-id

.PHONY: help env-check env-plan env-bootstrap runtime-up cluster-up cluster-down env-verify env-report

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

env-check: ## Inspect tool and provider readiness without mutation
	@scripts/env/bootstrap.sh
	@scripts/env/dev-doctor.sh --format json --provider "$(CONTAINER_PROVIDER)"

env-plan: ## Show tool, provider, and cluster changes without mutation
	@scripts/env/bootstrap.sh
	@scripts/env/provider.sh "$(CONTAINER_PROVIDER)" plan
	@scripts/env/kind.sh plan --minor "$(K8S_MINOR)"

env-bootstrap: ## Install pinned tools when APPLY=true
	@APPLY="$(APPLY)" scripts/env/bootstrap.sh

runtime-up: ## Ensure the selected container provider is ready
	@APPLY="$(APPLY)" scripts/env/provider.sh "$(CONTAINER_PROVIDER)" start
	@scripts/env/provider.sh "$(CONTAINER_PROVIDER)" wait

cluster-up: ## Create or reuse the owned kind cluster
	@APPLY=true scripts/env/kind.sh up --minor "$(K8S_MINOR)"

cluster-down: ## Delete the owned kind cluster when ALLOW_DELETE=true
	@ALLOW_DELETE="$(ALLOW_DELETE)" scripts/env/kind.sh down --minor "$(K8S_MINOR)"

env-verify: ## Verify the environment and preserve the report run ID
	@run_id="$(RUN_ID)"; \
	if [[ -z "$${run_id}" ]]; then run_id="verify-$$(date -u +%Y%m%d%H%M%S)"; fi; \
	scripts/env/verify.sh --run-id "$${run_id}"; \
	mkdir -p "$(dir $(LAST_ENV_RUN))"; \
	printf '%s\n' "$${run_id}" >"$(LAST_ENV_RUN)"; \
	printf 'last_environment_run_id=%s\n' "$${run_id}"

env-report: ## Re-render the most recently verified environment report
	@test -f "$(LAST_ENV_RUN)" || { printf 'ERROR: no verified environment run; run make env-verify first\n' >&2; exit 2; }
	@run_id="$$(cat "$(LAST_ENV_RUN)")"; \
	test -n "$${run_id}" || { printf 'ERROR: last environment run ID is empty\n' >&2; exit 2; }; \
	scripts/env/report.sh ".work/artifacts/environment/$${run_id}"
