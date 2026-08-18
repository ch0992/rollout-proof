---
task_id: ENV-008
title: "Local environment acceptance suite와 report"
status: completed
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/54
branch: "feat/54-env-008-env-verify"
work_order_version: 1
evaluation_document: ../evaluations/ENV-008-evaluation.md
---

# ENV-008 작업지시서: Local environment acceptance suite와 report

## 목적

Local environment acceptance suite와 report을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #54](https://github.com/ch0992/rollout-proof/issues/54)

## 작업 범위

- `scripts/env/verify.sh`
- `scripts/env/report.sh`
- `test/environment/`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: mandatory ENV check를 실행한다.
- [ ] AC-2: READY/FAIL/BLOCKED/INCONCLUSIVE를 구분한다.
- [ ] AC-3: JSON과 Markdown verdict가 일치한다.
- [ ] AC-4: secret redaction이 검증된다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/54-env-008-env-verify`
- Commit prefix: `[ENV-008]`
- PR은 `Closes #54`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
