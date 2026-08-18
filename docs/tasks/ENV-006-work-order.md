---
task_id: ENV-006
title: "Digest-pinned kind cluster IaC"
status: backlog
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/52
branch: "feat/52-env-006-kind-iac"
work_order_version: 1
evaluation_document: ../evaluations/ENV-006-evaluation.md
---

# ENV-006 작업지시서: Digest-pinned kind cluster IaC

## 목적

Digest-pinned kind cluster IaC을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #52](https://github.com/ch0992/rollout-proof/issues/52)

## 작업 범위

- `infra/local/kind/cluster.yaml`
- `infra/local/kind/versions.yaml`
- `scripts/env/kind.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: 1.34~1.36 image digest가 고정된다.
- [ ] AC-2: rolloutproof-dev만 생성/재사용한다.
- [ ] AC-3: config drift 시 자동 삭제하지 않는다.
- [ ] AC-4: control-plane 1과 worker 1이 Ready다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/52-env-006-kind-iac`
- Commit prefix: `[ENV-006]`
- PR은 `Closes #52`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.

