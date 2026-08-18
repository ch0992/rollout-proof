---
task_id: P0-036
title: "Phase 0 결과와 Go/No-Go ADR"
status: backlog
size: S
milestone: Phase 0
epic: P0-E6
issue: https://github.com/ch0992/rollout-proof/issues/42
branch: "docs/42-p0-036-phase0-decision"
work_order_version: 1
evaluation_document: ../evaluations/P0-036-evaluation.md
---

# P0-036 작업지시서: Phase 0 결과와 Go/No-Go ADR

## 1. 목적

Phase 0 결과와 Go/No-Go ADR을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-DECISION-001`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- P0 gate별 evidence 요약
- parameter 결정과 미해결 risk
- Go/No-Go/Conditional decision

## 5. 제외 범위

- 새 code 구현
- 실패 결과 은폐

## 6. 예상 변경 파일

- `docs/experiments/phase-0-results.md`
- `docs/adr/0009-phase-0-go-no-go.md`
- `docs/README.md`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: 각 Phase 0 gate에 artifact evidence가 링크된다.
- [ ] AC-2: 성공/실패/INCONCLUSIVE run 수가 모두 기록된다.
- [ ] AC-3: 결정된 parameter와 근거가 있다.
- [ ] AC-4: 미달 기준은 후속 Task 또는 No-Go 이유로 연결된다.
- [ ] AC-5: 문서 인덱스에 결과와 ADR이 연결된다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
test -f docs/experiments/phase-0-results.md
test -f docs/adr/0009-phase-0-go-no-go.md
rg -n 'PASS|FAIL|INCONCLUSIVE|Go|No-Go' docs/adr/0009-phase-0-go-no-go.md
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `docs/42-p0-036-phase0-decision`
- Commit prefix: `[P0-036]`
- PR title: `[P0-036] Phase 0 결과와 Go/No-Go ADR`
- PR은 `Closes #42` 및 작업지시서/평가서 링크를 포함한다.
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

