---
task_id: ENV-002
title: "Tool version manifest와 read-only bootstrap"
status: backlog
size: M
milestone: Environment Foundation
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/48
branch: "chore/48-env-002-tool-manifest"
work_order_version: 1
evaluation_document: ../evaluations/ENV-002-evaluation.md
---

# ENV-002 작업지시서: Tool version manifest와 read-only bootstrap

## 목적

Tool version manifest와 read-only bootstrap을 독립적으로 구현하고 후속 환경 Task가 사용할 검증된 계약을 만든다.

## 참조

- [환경 자동화 스펙](../environment-automation-spec.md)
- [AI 환경 구축 Runbook](../ai-environment-runbook.md)
- [로컬 인프라 검증 계약](../local-environment-validation.md)
- [Issue #48](https://github.com/ch0992/rollout-proof/issues/48)

## 작업 범위

- `Brewfile`
- `mise.toml`
- `infra/local/tool-versions.yaml`
- `scripts/env/bootstrap.sh`

## 제외 범위

- 후속 ENV Task의 구현
- 사용자의 기존 Docker/kubeconfig/resource 변경
- acceptance criterion 밖의 편의 기능

## Acceptance Criteria

- [ ] AC-1: 필수 tool/version/checksum source가 한 곳에 정의된다.
- [ ] AC-2: 기본 bootstrap은 read-only plan이다.
- [ ] AC-3: APPLY=true 없이는 package를 설치하지 않는다.
- [ ] AC-4: Apple Silicon과 amd64 선택을 검증한다.

## 검증

- 변경 파일의 syntax와 link를 검사한다.
- targeted test 또는 inspection evidence를 남긴다.
- `git diff --check`를 통과한다.
- 안전/non-goal 위반이 없는지 확인한다.

## 형상관리

- Branch: `chore/48-env-002-tool-manifest`
- Commit prefix: `[ENV-002]`
- PR은 `Closes #48`와 두 문서 링크를 포함한다.
- 평가 PASS 전에는 merge하지 않는다.

