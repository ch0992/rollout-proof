---
task_id: ENV-005
title: "Colima runtime 대체 adapter"
status: ready
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/51
branch: "feat/51-env-005-colima-provider"
work_order_version: 1
evaluation_document: ../evaluations/ENV-005-evaluation.md
---

# ENV-005 작업지시서: Colima runtime 대체 adapter

## 목적

Colima runtime 대체 adapter을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #51](https://github.com/ch0992/rollout-proof/issues/51)

## 작업 범위

- `scripts/env/providers/colima.sh`
- `infra/local/providers/colima.yaml`
- `test/environment/colima_test.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: rolloutproof profile만 소유한다.
- [ ] AC-2: 내장 Kubernetes가 disabled다.
- [ ] AC-3: 다른 profile을 변경하지 않는다.
- [ ] AC-4: Docker provider와 같은 interface를 구현한다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/51-env-005-colima-provider`
- Commit prefix: `[ENV-005]`
- PR은 `Closes #51`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
