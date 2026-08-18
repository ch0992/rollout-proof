---
task_id: P0-021
title: "New-connection HTTP transport"
status: draft
size: S
milestone: Phase 0
epic: P0-E4
issue: null
branch: "feat/<issue-number>-p0-021-new-connection"
work_order_version: 1
evaluation_document: ../evaluations/P0-021-evaluation.md
---

# P0-021 작업지시서: New-connection HTTP transport

## 1. 목적

New-connection HTTP transport을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-PROBE-003`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- DisableKeepAlives transport profile
- request별 새 연결 증거

## 5. 제외 범위

- keep-alive pool
- HTTP/2 지원

## 6. 예상 변경 파일

- `internal/probe/transport/new.go`
- `internal/probe/transport/new_test.go`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: 연속 요청에서 connection reuse가 0이다.
- [ ] AC-2: HTTP/1.1으로 protocol이 고정된다.
- [ ] AC-3: request context 취소가 socket을 종료한다.
- [ ] AC-4: httptest listener가 새 connection 수를 검증한다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
go test ./internal/probe/transport -run TestNewConnection
go test -race ./internal/probe/transport
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `feat/<issue-number>-p0-021-new-connection`
- Commit prefix: `[P0-021]`
- PR title: `[P0-021] New-connection HTTP transport`
- PR은 `Closes #<issue-number>` 및 작업지시서/평가서 링크를 포함한다.
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

