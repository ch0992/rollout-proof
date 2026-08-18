---
task_id: ENV-006
title: "Digest-pinned kind cluster IaC"
status: completed
issue: https://github.com/ch0992/rollout-proof/issues/52
pull_request: https://github.com/ch0992/rollout-proof/pull/64
evaluated_commit: e9da9ced24bfd1da0dfdb6e5dd140a75d2bbbf40
work_order: ../tasks/ENV-006-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-006 평가서: Digest-pinned kind cluster IaC

## 평가 대상

- Issue: #52
- 허용 파일: `infra/local/kind/cluster.yaml`, `infra/local/kind/versions.yaml`, `scripts/env/kind.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 1.34~1.36 image digest가 고정된다. | PASS | kind v0.32.0 공식 release의 1.34.8/1.35.5/1.36.1 digest 고정 |
| AC-2 | rolloutproof-dev만 생성/재사용한다. | PASS | 실제 최초 생성 및 두 번째 apply에서 cluster 목록 불변·재사용 확인 |
| AC-3 | config drift 시 자동 삭제하지 않는다. | PASS | metadata fingerprint drift에서 exit 6, cluster 존재 및 목록 불변 확인 |
| AC-4 | control-plane 1과 worker 1이 Ready다. | PASS | 실제 1.36.1 노드 2개 Ready 및 kube-system Pods Running 확인 |

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
- image: Kubernetes `1.36.1` digest pin 사용
- nodes: `rolloutproof-dev-control-plane`과 `rolloutproof-dev-worker` 모두 Ready
- kube-system: CoreDNS, etcd, API server, controller, scheduler, kindnet, kube-proxy 모두 Running
- 두 번째 apply: 동일 cluster 재사용, cluster 목록 불변
- drift injection: exit `6`, 자동 삭제 없음, 원상복구 후 READY
- global kubeconfig current-context: 실행 전후 모두 unset
- dedicated kubeconfig: `.work/kubeconfig`
- 변경 파일은 평가 계약 허용 파일 3개와 일치하며 평가 기록 commit은 대상에서 제외한다.
