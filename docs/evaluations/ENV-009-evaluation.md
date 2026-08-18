---
task_id: ENV-009
title: "멱등성, cleanup과 failure recovery 검증"
status: completed
issue: https://github.com/ch0992/rollout-proof/issues/55
pull_request: https://github.com/ch0992/rollout-proof/pull/70
evaluated_commit: 5b6085cd9920eec51213b38aec0556d759a75a21
work_order: ../tasks/ENV-009-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-009 평가서: 멱등성, cleanup과 failure recovery 검증

## 평가 대상

- Issue: #55
- 허용 파일: `test/environment/idempotency_test.sh`, `test/environment/cleanup_test.sh`, `test/environment/failure_test.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 두 번째 apply 변경이 0이다. | PASS | cluster/container/node UID와 context snapshot이 두 apply 전후 동일 |
| AC-2 | cleanup opt-in 없이는 삭제하지 않는다. | PASS | opt-in 없는 cleanup exit 6 및 target namespace 존속 확인 |
| AC-3 | failure injection을 탐지한다. | PASS | config fingerprint drift와 ownership mismatch 모두 exit 6으로 탐지 |
| AC-4 | unrelated resource가 보존된다. | PASS | target cleanup 전후 unrelated namespace UID와 cluster 목록 동일 |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | PASS |
| Scope | non-goal 침범 없음 | PASS |
| Safety | 기존 환경과 secret 보호 | PASS |
| Idempotency | 해당 변경의 반복 실행 안전 | PASS |
| Traceability | Issue, work order, PR, SHA 연결 | PASS |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.

최종 판정: **PASS**

## 실행 Evidence

- `bash -n`, `shellcheck`, `git diff --check`: PASS
- `idempotency_test.sh`: PASS
- `cleanup_test.sh`: PASS
- `failure_test.sh`: PASS
- 공유 cluster metadata 때문에 세 test는 순차 실행하며 병렬 실행하지 않는다.
- 테스트 전후 `rolloutproof-dev`는 control-plane 1, worker 1 READY
- 반복 cleanup은 `NO_CHANGE`, failure injection 후 metadata/namespace 원상복구 확인
- 변경 파일은 평가 계약 허용 파일 3개와 일치하며 평가 기록 commit은 대상에서 제외한다.
