---
task_id: ENV-010
title: "Linux CI kind matrix와 provider portability"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/56
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-010-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-010 평가서: Linux CI kind matrix와 provider portability

## 평가 대상

- Issue: #56
- 허용 파일: `.github/workflows/environment.yml`, `test/environment/ci.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | Linux Docker에서 공통 kind IaC를 사용한다. | 미평가 | |
| AC-2 | 1.34~1.36 matrix가 실행된다. | 미평가 | |
| AC-3 | artifact와 checksum을 보존한다. | 미평가 | |
| AC-4 | Mac provider 분기가 core test에 침투하지 않는다. | 미평가 | |

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

