---
task_id: P0-026
title: "Watch와 Probe producer를 Event bus에 연결"
status: backlog
size: M
milestone: Phase 0
epic: P0-E5
issue: https://github.com/ch0992/rollout-proof/issues/32
branch: "feat/32-p0-026-event-bus-wiring"
work_order_version: 1
evaluation_document: ../evaluations/P0-026-evaluation.md
---

# P0-026 작업지시서: Watch와 Probe producer를 Event bus에 연결

## 1. 목적

Watch와 Probe producer를 Event bus에 연결을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-EVENT-004`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- producer lifecycle orchestration
- 공통 event bus와 취소/close 순서

## 5. 제외 범위

- CLI rendering
- analyzer

## 6. 예상 변경 파일

- `internal/app/observe/pipeline.go`
- `internal/app/observe/pipeline_test.go`
- `internal/timeline/bus.go`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: watch와 probe event가 하나의 output stream에 도달한다.
- [ ] AC-2: 한 producer 오류가 root context를 취소한다.
- [ ] AC-3: channel close 순서가 send-on-closed panic을 만들지 않는다.
- [ ] AC-4: bounded drain 후 종료한다.
- [ ] AC-5: race detector가 통과한다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
go test ./internal/app/observe ./internal/timeline
go test -race ./internal/app/observe ./internal/timeline
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `feat/32-p0-026-event-bus-wiring`
- Commit prefix: `[P0-026]`
- PR title: `[P0-026] Watch와 Probe producer를 Event bus에 연결`
- PR은 `Closes #32` 및 작업지시서/평가서 링크를 포함한다.
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

