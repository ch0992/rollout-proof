---
task_id: ENV-004
title: "Docker Desktop runtime 검증 adapter"
status: completed
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/50
branch: "feat/50-env-004-docker-desktop"
work_order_version: 2
evaluation_document: ../evaluations/ENV-004-evaluation.md
---

# ENV-004 작업지시서: Docker Desktop runtime 검증 adapter

## 목적

Docker Desktop runtime 검증 adapter을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #50](https://github.com/ch0992/rollout-proof/issues/50)

## 작업 범위

- `infra/local/providers/docker-desktop.sh`
- `scripts/env/provider.sh`의 adapter 경로 연결 검증
- `test/environment/docker_desktop_test.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: desktop-linux context와 daemon을 검증한다.
- [ ] AC-2: Docker Desktop 설정을 변경하지 않는다.
- [ ] AC-3: unavailable 상태에 recovery 안내가 있다.
- [ ] AC-4: 기존 container/image를 삭제하지 않는다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `feat/50-env-004-docker-desktop`
- Commit prefix: `[ENV-004]`
- PR은 `Closes #50`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.
