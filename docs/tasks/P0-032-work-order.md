---
task_id: P0-032
title: "정상 Rollout fixture"
status: backlog
size: M
milestone: Phase 0
epic: P0-E6
issue: https://github.com/ch0992/rollout-proof/issues/38
branch: "feat/38-p0-032-normal-fixture"
work_order_version: 1
evaluation_document: ../evaluations/P0-032-evaluation.md
---

# P0-032 작업지시서: 정상 Rollout fixture

## 1. 목적

정상 Rollout fixture을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `TEST-E2E-002`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- readiness/graceful shutdown 정상 app
- Deployment/Service와 repeatable revision update

## 5. 제외 범위

- 결함 주입
- production image publishing

## 6. 예상 변경 파일

- `fixtures/normal/deployment.yaml`
- `fixtures/normal/service.yaml`
- `fixtures/normal/app/main.go`
- `fixtures/normal/README.md`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: fixture가 health와 backend identity endpoint를 제공한다.
- [ ] AC-2: readiness 전 traffic을 받지 않는다.
- [ ] AC-3: SIGTERM 후 graceful drain을 수행한다.
- [ ] AC-4: revision update가 deterministic하다.
- [ ] AC-5: kind에서 rollout이 Available 상태로 완료된다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
go test ./fixtures/normal/app/...
kubectl apply -f fixtures/normal
kubectl rollout status deployment/rolloutproof-normal --timeout=120s
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `feat/38-p0-032-normal-fixture`
- Commit prefix: `[P0-032]`
- PR title: `[P0-032] 정상 Rollout fixture`
- PR은 `Closes #38` 및 작업지시서/평가서 링크를 포함한다.
- 평가서 PASS와 required CI PASS 전에는 merge하지 않는다.

## 12. 완료 보고

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```

