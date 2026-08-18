---
task_id: P0-033
title: "Readiness/Endpoint gap 결함 fixture"
status: draft
size: M
milestone: Phase 0
epic: P0-E6
issue: null
branch: "feat/<issue-number>-p0-033-endpoint-gap-fixture"
work_order_version: 1
evaluation_document: ../evaluations/P0-033-evaluation.md
---

# P0-033 작업지시서: Readiness/Endpoint gap 결함 fixture

## 1. 목적

Readiness/Endpoint gap 결함 fixture을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `TEST-E2E-003`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- 의도된 termination/readiness 결함
- 재현 parameter와 expected failure window

## 5. 제외 범위

- 무작위 chaos
- CNI-specific 설정

## 6. 예상 변경 파일

- `fixtures/endpoint-gap/deployment.yaml`
- `fixtures/endpoint-gap/service.yaml`
- `fixtures/endpoint-gap/app/main.go`
- `fixtures/endpoint-gap/README.md`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: 결함 원인이 manifest/app에 명시적이다.
- [ ] AC-2: 정상 fixture와 한 가지 결함 축만 다르다.
- [ ] AC-3: 반복 rollout에서 HTTP failure window가 발생한다.
- [ ] AC-4: README가 예상 lifecycle과 reset 방법을 설명한다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
go test ./fixtures/endpoint-gap/app/...
kubectl apply -f fixtures/endpoint-gap
kubectl rollout status deployment/rolloutproof-endpoint-gap --timeout=120s
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `feat/<issue-number>-p0-033-endpoint-gap-fixture`
- Commit prefix: `[P0-033]`
- PR title: `[P0-033] Readiness/Endpoint gap 결함 fixture`
- PR은 `Closes #<issue-number>` 및 작업지시서/평가서 링크를 포함한다.
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

