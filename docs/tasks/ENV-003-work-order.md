---
task_id: ENV-003
title: "Container provider adapter와 dev-doctor"
status: completed
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/49
branch: "feat/49-env-003-provider-doctor"
work_order_version: 1
evaluation_document: ../evaluations/ENV-003-evaluation.md
---

# ENV-003 작업지시서: Container provider adapter와 dev-doctor

## 목적

Container provider adapter와 dev-doctor을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #49](https://github.com/ch0992/rollout-proof/issues/49)

## 작업 범위

- `scripts/env/provider.sh`
- `scripts/env/dev-doctor.sh`
- `test/environment/doctor_test.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [x] AC-1: 공통 provider interface가 구현된다.
- [x] AC-2: doctor가 secret 없이 JSON/Markdown 상태를 출력한다.
- [x] AC-3: missing/incompatible 상태가 typed exit code다.
- [x] AC-4: 실제 환경을 수정하지 않는다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/49-env-003-provider-doctor`
- Commit prefix: `[ENV-003]`
- PR은 `Closes #49`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
