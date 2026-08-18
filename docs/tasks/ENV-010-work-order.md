---
task_id: ENV-010
title: "Linux CI kind matrix와 provider portability"
status: backlog
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/56
branch: "ci/56-env-010-linux-matrix"
work_order_version: 1
evaluation_document: ../evaluations/ENV-010-evaluation.md
---

# ENV-010 작업지시서: Linux CI kind matrix와 provider portability

## 목적

Linux CI kind matrix와 provider portability을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #56](https://github.com/ch0992/rollout-proof/issues/56)

## 작업 범위

- `.github/workflows/environment.yml`
- `test/environment/ci.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: Linux Docker에서 공통 kind IaC를 사용한다.
- [ ] AC-2: 1.34~1.36 matrix가 실행된다.
- [ ] AC-3: artifact와 checksum을 보존한다.
- [ ] AC-4: Mac provider 분기가 core test에 침투하지 않는다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `ci/56-env-010-linux-matrix`
- Commit prefix: `[ENV-010]`
- PR은 `Closes #56`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
