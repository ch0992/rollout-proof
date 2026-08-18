---
task_id: ENV-003
title: "Container provider adapter와 dev-doctor"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/49
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-003-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-003 평가서: Container provider adapter와 dev-doctor

## 평가 대상

- Issue: #49
- 허용 파일: `scripts/env/provider.sh`, `scripts/env/dev-doctor.sh`, `test/environment/doctor_test.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 공통 provider interface가 구현된다. | 미평가 | |
| AC-2 | doctor가 secret 없이 JSON/Markdown 상태를 출력한다. | 미평가 | |
| AC-3 | missing/incompatible 상태가 typed exit code다. | 미평가 | |
| AC-4 | 실제 환경을 수정하지 않는다. | 미평가 | |

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
