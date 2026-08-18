---
task_id: ENV-008
title: "Local environment acceptance suite와 report"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/54
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-008-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-008 평가서: Local environment acceptance suite와 report

## 평가 대상

- Issue: #54
- 허용 파일: `scripts/env/verify.sh`, `scripts/env/report.sh`, `test/environment/`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | mandatory ENV check를 실행한다. | 미평가 | |
| AC-2 | READY/FAIL/BLOCKED/INCONCLUSIVE를 구분한다. | 미평가 | |
| AC-3 | JSON과 Markdown verdict가 일치한다. | 미평가 | |
| AC-4 | secret redaction이 검증된다. | 미평가 | |

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

