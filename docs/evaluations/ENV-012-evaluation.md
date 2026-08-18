---
task_id: ENV-012
title: "Environment Make entrypoints와 clean-room rehearsal"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/78
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-012-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-012 평가서: Environment Make entrypoints와 clean-room rehearsal

## 평가 대상

- Issue: #78
- 구현 후 evaluated commit을 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | check/plan 무변경 | 미평가 | |
| AC-2 | mutation 안전 계약 보존 | 미평가 | |
| AC-3 | 동일 run ID report | 미평가 | |
| AC-4 | Make 계약 테스트 | 미평가 | |
| AC-5 | clean-room 및 멱등성 | 미평가 | |
| AC-6 | unrelated 상태 보존 | 미평가 | |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | 미평가 |
| Scope | P0-002와 사용자 환경을 침범하지 않음 | 미평가 |
| Safety | exact target과 opt-in 유지 | 미평가 |
| Idempotency | 두 번째 apply 변경 없음 | 미평가 |
| Traceability | Issue, 문서, PR, SHA, artifact 연결 | 미평가 |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.
