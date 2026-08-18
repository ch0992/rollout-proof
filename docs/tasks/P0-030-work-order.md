---
task_id: P0-030
title: "Observe prototype command wiring"
status: backlog
size: M
milestone: Phase 0
epic: P0-E5
issue: https://github.com/ch0992/rollout-proof/issues/36
branch: "feat/36-p0-030-observe-prototype"
work_order_version: 1
evaluation_document: ../evaluations/P0-030-evaluation.md
---

# P0-030 작업지시서: Observe prototype command wiring

## 1. 목적

Observe prototype command wiring을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-APP-001`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- fake watch/probe adapter 기반 observe use case
- terminal/JSON output 선택
- timeout/cancel 전달

## 5. 제외 범위

- 실제 kube client wiring
- verdict/analyzer

## 6. 예상 변경 파일

- `internal/app/observe/run.go`
- `internal/app/observe/run_test.go`
- `internal/cli/observe.go`
- `internal/cli/observe_test.go`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: observe command가 target과 URL을 validation한다.
- [ ] AC-2: fake adapter event가 terminal과 JSON에 동일하게 반영된다.
- [ ] AC-3: timeout/cancel이 pipeline까지 전파된다.
- [ ] AC-4: adapter 오류가 non-zero exit category로 전달된다.
- [ ] AC-5: test가 실제 network/cluster를 요구하지 않는다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
go test ./internal/app/observe ./internal/cli -run TestObserve
go test -race ./internal/app/observe
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `feat/36-p0-030-observe-prototype`
- Commit prefix: `[P0-030]`
- PR title: `[P0-030] Observe prototype command wiring`
- PR은 `Closes #36` 및 작업지시서/평가서 링크를 포함한다.
- 평가서 PASS와 required CI PASS 전에는 merge하지 않는다.

## 12. 완료 보고

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```

