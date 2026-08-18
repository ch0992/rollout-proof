---
task_id: ENV-009
title: "멱등성, cleanup과 failure recovery 검증"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/55
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-009-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-009 평가서: 멱등성, cleanup과 failure recovery 검증

## 평가 대상

- Issue: #55
- 허용 파일: `test/environment/idempotency_test.sh`, `test/environment/cleanup_test.sh`, `test/environment/failure_test.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 두 번째 apply 변경이 0이다. | 미평가 | |
| AC-2 | cleanup opt-in 없이는 삭제하지 않는다. | 미평가 | |
| AC-3 | failure injection을 탐지한다. | 미평가 | |
| AC-4 | unrelated resource가 보존된다. | 미평가 | |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | 미평가 |
| Scope | non-goal 침범 없음 | 미평가 |
| Safety | 기존 환경과 secret 보호 | 미평가 |
| Idempotency | 해당 변경의 반복 실행 안전 | 미평가 |
| Traceability | Issue, work order, PR, SHA 연결 | 미평가 |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.
