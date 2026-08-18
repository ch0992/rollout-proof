---
task_id: ENV-012
title: "Environment Make entrypoints와 clean-room rehearsal"
status: completed
size: M
milestone: Environment Foundation Follow-up
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/78
branch: "feat/78-env-012-make-rehearsal"
work_order_version: 1
evaluation_document: ../evaluations/ENV-012-evaluation.md
---

# ENV-012 작업지시서: Environment Make entrypoints와 clean-room rehearsal

## 목적

환경 자동화 문서의 공통 Make 명령을 실제 진입점으로 구현하고, 프로젝트 소유 환경을 초기화한 뒤 문서만으로 재구축되는지 검증한다.

## 작업 범위

- 환경 관련 Make target
- Make target 계약 테스트
- Runbook 실행 명령과 evidence 연결
- `rolloutproof-dev` clean-room 재구축 리허설

## 제외 범위

- P0-002의 제품 build/test/lint target
- Docker Desktop 설치·설정·종료
- 다른 kind cluster, container, image 또는 global kubeconfig 변경
- shell profile 변경

## Acceptance Criteria

- [x] AC-1: `env-check`와 `env-plan`이 mutation 없이 실행된다.
- [x] AC-2: apply와 cleanup target이 기존 opt-in 및 소유권 검사를 보존한다.
- [x] AC-3: `env-verify`와 `env-report`가 동일 run ID evidence를 사용한다.
- [x] AC-4: Make target 계약 테스트가 실제 환경 변경 없이 통과한다.
- [x] AC-5: clean-room 재구축과 두 번째 apply 멱등성이 검증된다.
- [x] AC-6: global kubeconfig와 unrelated Docker 자원이 보존된다.

## 검증 명령

```bash
test/environment/make_targets_test.sh
make env-check
make env-plan
make cluster-down ALLOW_DELETE=true
make env-check
make env-plan
make env-bootstrap APPLY=true
make runtime-up
make cluster-up K8S_MINOR=1.36
make env-verify RUN_ID=env012-rehearsal
make env-report
make cluster-up K8S_MINOR=1.36
```

## 형상관리

- Issue: #78
- Branch: `feat/78-env-012-make-rehearsal`
- Commit prefix: `[ENV-012]`
- 평가 PASS 전에는 merge하지 않는다.
