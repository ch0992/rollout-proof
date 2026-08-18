---
task_id: ENV-009
title: "멱등성, cleanup과 failure recovery 검증"
status: completed
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/55
branch: "test/55-env-009-idempotency-cleanup"
work_order_version: 1
evaluation_document: ../evaluations/ENV-009-evaluation.md
---

# ENV-009 작업지시서: 멱등성, cleanup과 failure recovery 검증

## 목적

멱등성, cleanup과 failure recovery 검증을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #55](https://github.com/ch0992/rollout-proof/issues/55)

## 작업 범위

- `test/environment/idempotency_test.sh`
- `test/environment/cleanup_test.sh`
- `test/environment/failure_test.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [x] AC-1: 두 번째 apply 변경이 0이다.
- [x] AC-2: cleanup opt-in 없이는 삭제하지 않는다.
- [x] AC-3: failure injection을 탐지한다.
- [x] AC-4: unrelated resource가 보존된다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `test/55-env-009-idempotency-cleanup`
- Commit prefix: `[ENV-009]`
- PR은 `Closes #55`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
