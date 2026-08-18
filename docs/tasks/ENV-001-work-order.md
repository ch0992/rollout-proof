---
task_id: ENV-001
title: "환경 자동화 계약, AI runbook과 AGENTS.md"
status: in_progress
size: S
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/47
branch: "docs/47-env-001-automation-contract"
work_order_version: 1
evaluation_document: ../evaluations/ENV-001-evaluation.md
---

# ENV-001 작업지시서: 환경 자동화 계약, AI runbook과 AGENTS.md

## 목적

환경 자동화 계약, AI runbook과 AGENTS.md을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #47](https://github.com/ch0992/rollout-proof/issues/47)

## 작업 범위

- `AGENTS.md`
- `docs/environment-automation-spec.md`
- `docs/ai-environment-runbook.md`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: AI 시작·중단·안전 규칙이 명시된다.
- [ ] AC-2: check/plan/apply/verify/cleanup mode가 분리된다.
- [ ] AC-3: Docker Desktop/Colima provider interface가 정의된다.
- [ ] AC-4: Issue, branch, 평가 계약이 연결된다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `docs/47-env-001-automation-contract`
- Commit prefix: `[ENV-001]`
- PR은 `Closes #47`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
