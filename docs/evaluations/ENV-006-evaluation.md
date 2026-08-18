---
task_id: ENV-006
title: "Digest-pinned kind cluster IaC"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/52
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-006-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-006 평가서: Digest-pinned kind cluster IaC

## 평가 대상

- Issue: #52
- 허용 파일: `infra/local/kind/cluster.yaml`, `infra/local/kind/versions.yaml`, `scripts/env/kind.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 1.34~1.36 image digest가 고정된다. | 미평가 | |
| AC-2 | rolloutproof-dev만 생성/재사용한다. | 미평가 | |
| AC-3 | config drift 시 자동 삭제하지 않는다. | 미평가 | |
| AC-4 | control-plane 1과 worker 1이 Ready다. | 미평가 | |

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
