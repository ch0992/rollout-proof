---
task_id: ENV-007
title: "Kubeconfig, namespace와 artifact 격리"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/53
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-007-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-007 평가서: Kubeconfig, namespace와 artifact 격리

## 평가 대상

- Issue: #53
- 허용 파일: `scripts/env/workspace.sh`, `test/environment/isolation_test.sh`, `.gitignore`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | kubeconfig가 .work에 생성된다. | 미평가 | |
| AC-2 | global current-context가 보존된다. | 미평가 | |
| AC-3 | test namespace 밖 mutation이 없다. | 미평가 | |
| AC-4 | cleanup이 run ID와 label로 제한된다. | 미평가 | |

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

