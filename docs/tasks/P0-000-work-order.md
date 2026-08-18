---
task_id: P0-000
title: "Mac 개발 및 Kubernetes 호환 환경 정의"
status: in_progress
size: M
milestone: Phase 0
epic: P0-E1
issue: https://github.com/ch0992/rollout-proof/issues/43
branch: "docs/43-p0-000-development-environment"
work_order_version: 1
evaluation_document: ../evaluations/P0-000-evaluation.md
---

# P0-000 작업지시서: Mac 개발 및 Kubernetes 호환 환경 정의

## 1. 목적

MacBook에서 재현 가능한 local Kubernetes 개발 환경과 on-prem/cloud Kubernetes 호환성 검증 경계를 구현 전에 확정한다.

## 2. 참조 계약

- Requirement ID: `ENG-ENV-001`, `TEST-COMPAT-001`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- [Issue 및 형상관리 Workflow](../version-control-workflow.md)
- [Issue #43](https://github.com/ch0992/rollout-proof/issues/43)

## 3. 작업 범위

- Mac 기본 container runtime 및 Kubernetes topology
- Apple Silicon/Intel 지원 경계
- tool version 및 resource 정책
- kubeconfig/context/artifact 격리
- kind 1.34~1.36 matrix
- actual on-prem/cloud compatibility layer와 안전 계약
- P0-031/P0-034 작업 계약 보강

## 4. 제외 범위

- Colima/kind 실제 설치와 script 구현
- cloud account와 cluster 생성
- 모든 CNI/service mesh 검증
- RolloutProof product code 구현

## 5. 예상 변경 파일

- `docs/development-environment.md`
- `docs/cluster-compatibility.md`
- `docs/implementation-spec.md`
- `docs/phase-0-task-breakdown.md`
- `docs/tasks/P0-031-work-order.md`
- `docs/evaluations/P0-031-evaluation.md`
- 문서 인덱스와 Task 상태

M Task 예외 사유: local topology와 실제 cluster compatibility는 서로의 test level과 지원 주장을 정의하므로 분리하면 계약이 상충할 가능성이 크다.

## 6. Acceptance Criteria

- [ ] AC-1: Mac 기본 환경이 Colima Docker runtime 위의 kind로 명시된다.
- [ ] AC-2: Colima 내장 k3s와 canonical kind 환경을 혼합하지 않는 규칙이 있다.
- [ ] AC-3: Apple Silicon, Intel 및 Docker Desktop 대체 경로가 구분된다.
- [ ] AC-4: Kubernetes 1.34~1.36 pinned node image matrix와 kubeconfig 격리가 정의된다.
- [ ] AC-5: on-prem, K3s/RKE2, EKS, GKE, AKS, OpenShift의 검증 등급과 주기가 구분된다.
- [ ] AC-6: 실제 cluster mutation test에 context/namespace/opt-in/cleanup 안전장치가 있다.
- [ ] AC-7: cloud SDK 없이 stable Kubernetes API capability를 사용하는 portability 원칙이 있다.

## 7. 검증 명령

```bash
rg -n 'Colima|Docker Desktop|kind|Apple Silicon|kubeconfig' docs/development-environment.md
rg -n 'EKS|GKE|AKS|RKE2|OpenShift|Supported|Release Tested' docs/cluster-compatibility.md
rg -n '1.34|1.35|1.36|ALLOW_MUTATION|stable Kubernetes API' docs/cluster-compatibility.md
git diff --check
```

## 8. 형상관리 계약

- Branch: `docs/43-p0-000-development-environment`
- Commit prefix: `[P0-000]`
- PR title: `[P0-000] Define Mac and Kubernetes compatibility environments`
- PR은 `Closes #43`과 작업지시서/평가서 링크를 포함한다.
- 평가서 PASS 전에는 merge하지 않는다.

