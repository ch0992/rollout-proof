---
task_id: ENV-007
title: "Kubeconfig, namespace와 artifact 격리"
status: backlog
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/53
branch: "feat/53-env-007-environment-isolation"
work_order_version: 1
evaluation_document: ../evaluations/ENV-007-evaluation.md
---

# ENV-007 작업지시서: Kubeconfig, namespace와 artifact 격리

## 목적

Kubeconfig, namespace와 artifact 격리을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #53](https://github.com/ch0992/rollout-proof/issues/53)

## 작업 범위

- `scripts/env/workspace.sh`
- `test/environment/isolation_test.sh`
- `.gitignore`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: kubeconfig가 .work에 생성된다.
- [ ] AC-2: global current-context가 보존된다.
- [ ] AC-3: test namespace 밖 mutation이 없다.
- [ ] AC-4: cleanup이 run ID와 label로 제한된다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/53-env-007-environment-isolation`
- Commit prefix: `[ENV-007]`
- PR은 `Closes #53`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.

