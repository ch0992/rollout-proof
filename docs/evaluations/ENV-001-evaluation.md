---
task_id: ENV-001
title: "환경 자동화 계약, AI runbook과 AGENTS.md"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/47
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-001-work-order.md
evaluation_version: 2
verdict: null
---

# ENV-001 평가서: 환경 자동화 계약, AI runbook과 AGENTS.md

## 평가 대상

- Issue: #47
- 허용 파일: ENV-001 작업지시서 v2의 `작업 범위`에 열거된 파일
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | AI 시작·중단·안전 규칙이 명시된다. | 미평가 | |
| AC-2 | check/plan/apply/verify/cleanup mode가 분리된다. | 미평가 | |
| AC-3 | Docker Desktop/Colima provider interface가 정의된다. | 미평가 | |
| AC-4 | Issue, branch, 평가 계약이 연결된다. | 미평가 | |

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
