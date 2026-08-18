---
task_id: P0-018
title: "ADR-0004 LIST/WATCH supervisor 결정"
status: backlog
size: XS
milestone: Phase 0
epic: P0-E3
issue: https://github.com/ch0992/rollout-proof/issues/24
branch: "docs/24-p0-018-adr-watch"
work_order_version: 1
evaluation_document: ../evaluations/P0-018-evaluation.md
---

# P0-018 작업지시서: ADR-0004 LIST/WATCH supervisor 결정

## 1. 목적

ADR-0004 LIST/WATCH supervisor 결정을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 산출물을 만든다.

## 2. 선행조건

- [Phase 0 dependency graph](../phase-0-task-breakdown.md)의 선행 Task가 PASS 상태여야 한다.
- Issue URL과 base commit을 작업 전에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-ARCH-004`
- [엔지니어링 구현 스펙](../implementation-spec.md)
- 관련 세부 section은 Issue 생성 시 requirement와 함께 고정한다.

## 4. 작업 범위

- direct LIST/WATCH 선택과 informer 대안 비교
- EOF/410/gap 정책 기록

## 5. 제외 범위

- 구현 코드 변경
- 분석 confidence 공식

## 6. 예상 변경 파일

- `docs/adr/0004-list-watch-supervisor.md`
- `docs/README.md`

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. Acceptance Criteria

- [ ] AC-1: Context/Decision/Alternatives/Consequences가 있다.
- [ ] AC-2: initial LIST 후 WATCH 순서를 명시한다.
- [ ] AC-3: 410 gap을 숨기지 않는 정책을 명시한다.
- [ ] AC-4: 문서 인덱스에서 연결된다.

## 8. 구현 절차

1. 실패 test, fixture 또는 inspection check를 먼저 준비한다.
2. 예상 파일 범위에서 최소 구현을 수행한다.
3. targeted 검증과 race/static 검사를 실행한다.
4. 제외 범위 침범과 dependency 증가를 확인한다.
5. AC별 evidence와 commit SHA를 평가서에 전달한다.

## 9. 검증 명령

```bash
test -f docs/adr/0004-list-watch-supervisor.md
rg -n 'Context|Decision|Alternatives|Consequences|410' docs/adr/0004-list-watch-supervisor.md
```

## 10. 산출물

- 지정 source/test/document와 검증 결과
- AC별 evidence와 평가 대상 commit SHA

## 11. 형상관리 계약

- Branch: `docs/24-p0-018-adr-watch`
- Commit prefix: `[P0-018]`
- PR title: `[P0-018] ADR-0004 LIST/WATCH supervisor 결정`
- PR은 `Closes #24` 및 작업지시서/평가서 링크를 포함한다.
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

