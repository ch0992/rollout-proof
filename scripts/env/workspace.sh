#!/usr/bin/env bash

set -euo pipefail

readonly EXIT_USAGE=2
readonly EXIT_TOOL=3
readonly EXIT_KUBERNETES=5
readonly EXIT_SAFETY=6
readonly MANAGED_BY_LABEL="app.kubernetes.io/managed-by=rollout-proof"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly REPO_ROOT
readonly KUBECONFIG_FILE="${REPO_ROOT}/.work/kubeconfig"
readonly TOOL_VERSIONS="${REPO_ROOT}/infra/local/tool-versions.yaml"

usage() {
  printf 'usage: %s <plan|init|verify|cleanup> --run-id <lowercase-id>\n' "${0##*/}" >&2
}

ACTION="${1:-plan}"
[[ $# -gt 0 ]] && shift
RUN_ID="${ROLLOUTPROOF_RUN_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      [[ $# -ge 2 ]] || { usage; exit "${EXIT_USAGE}"; }
      RUN_ID="$2"
      shift 2
      ;;
    *) usage; exit "${EXIT_USAGE}" ;;
  esac
done

case "${ACTION}" in plan|init|verify|cleanup) ;; *) usage; exit "${EXIT_USAGE}" ;; esac
[[ "${RUN_ID}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || { printf 'ERROR: invalid or missing run ID\n' >&2; exit "${EXIT_USAGE}"; }

readonly NAMESPACE="rolloutproof-test-${RUN_ID}"
readonly RUN_LABEL="rollout-proof.dev/run-id=${RUN_ID}"
readonly ARTIFACT_DIR="${REPO_ROOT}/.work/artifacts/environment/runs/${RUN_ID}"
readonly BEFORE_SNAPSHOT="${ARTIFACT_DIR}/before.env"
readonly AFTER_SNAPSHOT="${ARTIFACT_DIR}/after.env"

tool_version() {
  local tool="$1"
  awk -v tool="${tool}" '
    $0 == "  " tool ":" { in_tool = 1; next }
    in_tool && $0 ~ /^    version:/ {
      sub(/^    version:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
    in_tool && $0 ~ /^  [a-zA-Z0-9_-]+:/ { exit }
  ' "${TOOL_VERSIONS}"
}

KUBECTL_VERSION="$(tool_version kubectl)"
readonly KUBECTL_VERSION
KIND_VERSION="$(tool_version kind)"
readonly KIND_VERSION

kubectl_cmd() {
  [[ -f "${KUBECONFIG_FILE}" ]] || { printf 'ERROR: dedicated kubeconfig missing: %s\n' "${KUBECONFIG_FILE}" >&2; return "${EXIT_KUBERNETES}"; }
  if command -v mise >/dev/null 2>&1; then
    MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec "kubectl@${KUBECTL_VERSION}" -- kubectl --kubeconfig "${KUBECONFIG_FILE}" "$@"
  elif command -v kubectl >/dev/null 2>&1; then
    kubectl --kubeconfig "${KUBECONFIG_FILE}" "$@"
  else
    printf 'ERROR: kubectl is missing\n' >&2
    return "${EXIT_TOOL}"
  fi
}

kind_clusters() {
  if command -v mise >/dev/null 2>&1; then
    MISE_TRUSTED_CONFIG_PATHS="${REPO_ROOT}" mise exec "kind@${KIND_VERSION}" -- kind get clusters 2>/dev/null | sort | paste -sd, -
  elif command -v kind >/dev/null 2>&1; then
    kind get clusters 2>/dev/null | sort | paste -sd, -
  else
    printf 'unavailable'
  fi
}

global_context() {
  kubectl config current-context 2>/dev/null || printf '<unset>'
}

docker_context() {
  docker context show 2>/dev/null || printf '<unavailable>'
}

outside_namespaces() {
  kubectl_cmd get namespaces -o name | awk -v target="namespace/${NAMESPACE}" '$0 != target' | sort | paste -sd, -
}

snapshot() {
  local target="$1"
  mkdir -p "${ARTIFACT_DIR}"
  {
    printf 'global_context=%s\n' "$(global_context)"
    printf 'docker_context=%s\n' "$(docker_context)"
    printf 'kind_clusters=%s\n' "$(kind_clusters)"
    printf 'outside_namespaces=%s\n' "$(outside_namespaces)"
  } >"${target}"
}

verify_namespace_ownership() {
  local managed_by run_id
  managed_by="$(kubectl_cmd get namespace "${NAMESPACE}" -o 'jsonpath={.metadata.labels.app\.kubernetes\.io/managed-by}')"
  run_id="$(kubectl_cmd get namespace "${NAMESPACE}" -o 'jsonpath={.metadata.labels.rollout-proof\.dev/run-id}')"
  [[ "${managed_by}" == "rollout-proof" && "${run_id}" == "${RUN_ID}" ]]
}

case "${ACTION}" in
  plan)
    printf 'task=ENV-007 mode=plan run_id=%s namespace=%s kubeconfig=%s artifact_dir=%s\n' \
      "${RUN_ID}" "${NAMESPACE}" "${KUBECONFIG_FILE}" "${ARTIFACT_DIR}"
    printf 'result=NO_MUTATION init_requires=APPLY_TRUE cleanup_requires=ALLOW_CLEANUP_TRUE\n'
    ;;
  init)
    [[ "${APPLY:-false}" == "true" ]] || { printf 'ERROR: init requires APPLY=true\n' >&2; exit "${EXIT_SAFETY}"; }
    snapshot "${BEFORE_SNAPSHOT}"
    if ! kubectl_cmd get namespace "${NAMESPACE}" >/dev/null 2>&1; then
      kubectl_cmd create namespace "${NAMESPACE}" >/dev/null
    fi
    kubectl_cmd label namespace "${NAMESPACE}" "${MANAGED_BY_LABEL}" "${RUN_LABEL}" --overwrite >/dev/null
    verify_namespace_ownership || { printf 'ERROR: namespace ownership label verification failed\n' >&2; exit "${EXIT_SAFETY}"; }
    printf 'result=READY run_id=%s namespace=%s\n' "${RUN_ID}" "${NAMESPACE}"
    ;;
  verify)
    [[ -f "${BEFORE_SNAPSHOT}" ]] || { printf 'ERROR: before snapshot missing for run ID %s\n' "${RUN_ID}" >&2; exit "${EXIT_SAFETY}"; }
    verify_namespace_ownership || { printf 'ERROR: namespace missing or ownership labels mismatch\n' >&2; exit "${EXIT_SAFETY}"; }
    snapshot "${AFTER_SNAPSHOT}"
    if ! cmp -s "${BEFORE_SNAPSHOT}" "${AFTER_SNAPSHOT}"; then
      printf 'ERROR: isolation drift detected\n' >&2
      diff -u "${BEFORE_SNAPSHOT}" "${AFTER_SNAPSHOT}" >&2 || true
      exit "${EXIT_SAFETY}"
    fi
    printf 'result=PASS run_id=%s namespace=%s global_context=preserved docker_context=preserved unrelated=preserved\n' \
      "${RUN_ID}" "${NAMESPACE}"
    ;;
  cleanup)
    [[ "${ALLOW_CLEANUP:-false}" == "true" ]] || { printf 'ERROR: cleanup requires ALLOW_CLEANUP=true\n' >&2; exit "${EXIT_SAFETY}"; }
    if ! kubectl_cmd get namespace "${NAMESPACE}" >/dev/null 2>&1; then
      printf 'result=NO_CHANGE reason=namespace_absent run_id=%s\n' "${RUN_ID}"
      exit 0
    fi
    verify_namespace_ownership || { printf 'ERROR: refusing cleanup because ownership labels mismatch\n' >&2; exit "${EXIT_SAFETY}"; }
    kubectl_cmd delete namespace "${NAMESPACE}" --wait=true --timeout=60s >/dev/null
    printf 'result=DELETED run_id=%s namespace=%s selector="%s,%s"\n' \
      "${RUN_ID}" "${NAMESPACE}" "${MANAGED_BY_LABEL}" "${RUN_LABEL}"
    ;;
esac
