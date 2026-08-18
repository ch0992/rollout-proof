---
task_id: P0-000
title: "Mac 개발 및 Kubernetes 호환 환경 정의"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/43
pull_request: null
evaluated_commit: null
work_order: ../tasks/P0-000-work-order.md
evaluation_version: 3
verdict: null
---

# P0-000 평가서: Mac 개발 및 Kubernetes 호환 환경 정의

## 1. 평가 목적

환경 문서가 특정 Mac runtime이나 cloud provider에 과도하게 결합되지 않으면서 재현 가능한 local 기준과 실제 cluster 검증 안전성을 제공하는지 평가한다.

## 2. Acceptance Criteria 검증표

| AC | 검증 방법 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|---|
| AC-1 | topology inspection | Colima Docker → kind가 유일한 primary 경로 | 미평가 | |
| AC-2 | negative rule inspection | Colima k3s 혼합 금지와 이유 명시 | 미평가 | |
| AC-3 | host/provider matrix | Apple Silicon/Intel/Docker Desktop 구분 | 미평가 | |
| AC-4 | version/safety inspection | 3 minor, digest pin, kubeconfig 격리 | 미평가 | |
| AC-5 | policy/evidence review | on-prem/cloud 지원 상태와 테스트 evidence 상태 분리 | 미평가 | |
| AC-6 | mutation threat review | explicit context/namespace/opt-in/cleanup 모두 존재 | 미평가 | |
| AC-7 | dependency review | provider SDK 없는 API capability 원칙 | 미평가 | |
| AC-8 | document responsibility review | 환경/호환성/테스트가 별도 문서이고 중복 책임 없음 | 미평가 | |
| AC-9 | test contract inspection | L0~L4, gate, flaky, evidence, cleanup 정의 | 미평가 | |
| AC-10 | environment acceptance review | static부터 cleanup까지 단계와 mandatory 판정 존재 | 미평가 | |
| AC-11 | command/report contract review | env-verify, check ID, exit code, JSON/Markdown evidence 정의 | 미평가 | |

## 3. 독립 평가 명령

```bash
rg -n 'Colima|Docker Desktop|kind|Apple Silicon|kubeconfig' docs/development-environment.md
rg -n 'EKS|GKE|AKS|RKE2|OpenShift|Supported|Release Tested' docs/cluster-compatibility.md
rg -n '1.34|1.35|1.36|stable Kubernetes API|Required Capability' docs/cluster-compatibility.md
rg -n 'L0|L1|L2|L3|L4|PR Test Gate|Release Test Gate|Flaky Test|Evidence|ALLOW_MUTATION' docs/test-strategy.md
rg -n 'ENV-STATIC|ENV-RUNTIME|ENV-K8S|ENV-NET|ENV-ISOLATION|env-verify|Exit Code|Evidence Artifact' docs/local-environment-validation.md
git diff --check
```

## 4. Mandatory Rubric

| 항목 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| Correctness | 공식 kind/Colima/Kubernetes 동작과 모순 없음 | 미평가 | |
| Reproducibility | tool/topology/version/context가 명확함 | 미평가 | |
| Portability | provider 이름이 core code 분기를 요구하지 않음 | 미평가 | |
| Safety | 실제 cluster 오작동 방지 조건이 있음 | 미평가 | |
| Scope | 설치 script나 product code를 구현하지 않음 | 미평가 | |
| Traceability | Issue, work order, evaluation, PR이 연결됨 | 미평가 | |

## 5. Negative Review

- default kubeconfig를 사용해도 된다고 해석될 문장이 없는지 확인한다.
- local kind PASS를 모든 cloud 지원 증거로 주장하지 않는지 확인한다.
- cleanup target이 전체 cluster/runtime가 될 수 없는지 확인한다.
- Docker Desktop 구매/설치를 필수로 만들지 않는지 확인한다.

## 6. 판정

```text
Verdict: PASS | FAIL | INCONCLUSIVE
AC-1..AC-7: 미평가
Correctness: 미평가
Reproducibility: 미평가
Portability: 미평가
Safety: 미평가
Scope: 미평가
Traceability: 미평가
```
