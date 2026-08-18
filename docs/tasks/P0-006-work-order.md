---
task_id: P0-006
title: "Event domain type 정의"
status: draft
size: S
milestone: Phase 0
epic: P0-E2
issue: null
branch: "feat/<issue-number>-p0-006-event-domain-types"
work_order_version: 1
evaluation_document: ../evaluations/P0-006-evaluation.md
---

# P0-006 작업지시서: Event domain type 정의

## 1. 목적

Event domain type 정의을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-EVENT-001`
- 엔지니어링 구현 스펙 §9.1 Event 규칙

## 4. 작업 범위

- Source, Kind, ObjectRef, Event type
- typed payload marker
- constructor validation

## 5. 제외 범위

- JSON report DTO
- event sequencing
- Kubernetes object 변환

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `internal/timeline/event.go` | 생성 또는 수정 | Event domain type 정의 |
| `internal/timeline/event_test.go` | 생성 또는 수정 | Event domain type 정의 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

domain event는 생성 후 변경하지 않는 value로 취급한다. payload에 `map[string]any`를 허용하지 않고 허용 type을 compile-time interface로 제한한다.

## 8. Acceptance Criteria

- [ ] AC-1: Event가 sequence, wall time, elapsed time, source, kind, object ref, typed payload를 표현한다.
- [ ] AC-2: 임의 `map[string]any` payload를 public API가 받지 않는다.
- [ ] AC-3: 필수 field가 없는 event 생성은 typed error를 반환한다.
- [ ] AC-4: unit test가 유효/무효 constructor 경계를 검증한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/timeline -run 'Test.*Event'
go vet ./internal/timeline
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/<issue-number>-p0-006-event-domain-types`
- Commit prefix: `[P0-006]`
- PR title: `[P0-006] Event domain type 정의`
- PR 본문: `Closes #<issue-number>`와 작업지시서/평가서 링크
- merge 조건: 평가서 PASS와 required CI PASS

## 13. 완료 보고 형식

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```

