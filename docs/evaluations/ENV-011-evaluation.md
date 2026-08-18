---
task_id: ENV-011
title: "Project shell activation과 kubeconfig UX"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/76
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-011-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-011 평가서: Project shell activation과 kubeconfig UX

## 평가 대상

- Issue: #76
- 구현 후 evaluated commit을 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 절대경로 kubeconfig | 미평가 | |
| AC-2 | 기존 shell 환경 복원 | 미평가 | |
| AC-3 | 오류 경로 fail-fast | 미평가 | |
| AC-4 | shell 회귀 테스트 | 미평가 | |
| AC-5 | 사용법 문서화 | 미평가 | |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | 미평가 |
| Scope | shell profile과 cluster를 변경하지 않음 | 미평가 |
| Safety | 기존 환경 보존 및 명시적 source | 미평가 |
| Idempotency | 반복 활성화와 비활성화 안전 | 미평가 |
| Traceability | Issue, 문서, PR, SHA 연결 | 미평가 |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.
