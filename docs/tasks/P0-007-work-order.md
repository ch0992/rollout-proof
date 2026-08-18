---
task_id: P0-007
title: "Real/Fake clock과 elapsed time 구현"
status: draft
size: S
milestone: Phase 0
epic: P0-E2
issue: null
branch: "feat/<issue-number>-p0-007-clock"
work_order_version: 1
evaluation_document: ../evaluations/P0-007-evaluation.md
---

# P0-007 작업지시서: Real/Fake clock과 elapsed time 구현

## 1. 목적

Real/Fake clock과 elapsed time 구현을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-EVENT-002`
- 엔지니어링 구현 스펙 §8.4 시간 측정
- 엔지니어링 구현 스펙 §13.1 Unit test

## 4. 작업 범위

- Clock 최소 interface
- real clock
- 수동 진행 fake clock
- UTC wall time와 elapsed 계산

## 5. 제외 범위

- scheduler timer API
- Kubernetes timestamp 보정
- event sequencing

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `internal/timeline/clock.go` | 생성 또는 수정 | Real/Fake clock과 elapsed time 구현 |
| `internal/timeline/clock_test.go` | 생성 또는 수정 | Real/Fake clock과 elapsed time 구현 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

domain test는 실제 `time.Sleep`을 사용하지 않는다. elapsed는 run 시작 monotonic 기준이며 음수가 될 수 없다.

## 8. Acceptance Criteria

- [ ] AC-1: real clock이 UTC wall time과 run-start elapsed를 제공한다.
- [ ] AC-2: fake clock을 test에서 결정적으로 전진시킬 수 있다.
- [ ] AC-3: fake clock test가 `time.Sleep` 없이 elapsed 값을 검증한다.
- [ ] AC-4: clock 역행 입력은 음수 elapsed를 노출하지 않는다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/timeline -run 'Test.*Clock'
rg -n 'time\.Sleep' internal/timeline/*_test.go && exit 1 || true
go test -race ./internal/timeline
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/<issue-number>-p0-007-clock`
- Commit prefix: `[P0-007]`
- PR title: `[P0-007] Real/Fake clock과 elapsed time 구현`
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

