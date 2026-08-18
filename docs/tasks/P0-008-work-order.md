---
task_id: P0-008
title: "단일 Event sequencer 구현"
status: backlog
size: S
milestone: Phase 0
epic: P0-E2
issue: https://github.com/ch0992/rollout-proof/issues/14
branch: "feat/14-p0-008-event-sequencer"
work_order_version: 1
evaluation_document: ../evaluations/P0-008-evaluation.md
---

# P0-008 작업지시서: 단일 Event sequencer 구현

## 1. 목적

단일 Event sequencer 구현을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-EVENT-003`
- 엔지니어링 구현 스펙 §9.2 Ordering
- 엔지니어링 구현 스펙 §9.3 Backpressure

## 4. 작업 범위

- 단일 소유 goroutine sequencer
- strictly increasing sequence
- context 취소와 channel 종료
- bounded input

## 5. 제외 범위

- disk persistence
- producer retry
- success event aggregation

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `internal/timeline/sequencer.go` | 생성 또는 수정 | 단일 Event sequencer 구현 |
| `internal/timeline/sequencer_test.go` | 생성 또는 수정 | 단일 Event sequencer 구현 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

sequence 발급자는 하나의 goroutine이어야 한다. input은 bounded이며 취소 후 producer가 영구 block되지 않아야 한다.

## 8. Acceptance Criteria

- [ ] AC-1: 첫 event부터 sequence가 단조 증가하고 중복되지 않는다.
- [ ] AC-2: 여러 producer의 동시 입력에서도 race 없이 모든 수락 event가 한 번 출력된다.
- [ ] AC-3: context 취소 시 goroutine과 output channel이 종료된다.
- [ ] AC-4: buffer capacity가 constructor에서 유효성 검증된다.
- [ ] AC-5: race detector가 통과한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/timeline -run 'Test.*Sequencer'
go test -race ./internal/timeline
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/14-p0-008-event-sequencer`
- Commit prefix: `[P0-008]`
- PR title: `[P0-008] 단일 Event sequencer 구현`
- PR 본문: `Closes #14`와 작업지시서/평가서 링크
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

