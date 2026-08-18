---
task_id: P0-000
title: Replace with task title
status: draft
size: S
milestone: Phase 0
epic: P0-E0
issue: null
branch: "feat/<issue-number>-p0-000-short-name"
work_order_version: 1
evaluation_document: ../evaluations/P0-000-evaluation.md
---

# P0-000 작업지시서: 제목

## 1. 목적

이 Task가 만들어야 하는 단일 결과를 설명한다.

## 2. 선행조건

- 완료되어야 하는 Task/ADR
- 필요한 tool 및 fixture

## 3. 참조 계약

- Requirement ID:
- 제품 스펙 heading:
- 구현 스펙 heading:
- ADR:

## 4. 작업 범위

- 구현할 항목

## 5. 제외 범위

- 구현하지 않을 항목

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `path` | 생성/수정 | 설명 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 이슈 분할을 검토한다.

## 7. 구현 계약

interface, 입력, 출력, 오류, 동시성 및 안전성 조건을 구체적으로 정의한다.

## 8. Acceptance Criteria

- [ ] AC-1: Given/When/Then
- [ ] AC-2: 관측 가능한 조건
- [ ] AC-3: 오류/경계 조건

## 9. 구현 절차

1. 실패하는 test 또는 검증 fixture를 만든다.
2. 최소 구현을 추가한다.
3. targeted test를 통과시킨다.
4. 영향 범위를 검증한다.

## 10. 검증 명령

```bash
# command
```

예상 결과를 명시한다.

## 11. 산출물

- source/test/artifact
- 평가서에 제공할 evidence

## 12. 형상관리 계약

- Issue: 생성 후 URL 기록
- Branch: `feat/<issue-number>-p0-000-short-name`
- Commit prefix: `[P0-000]`
- PR title: `[P0-000] 제목`
- PR은 Issue를 `Closes #<number>`로 연결한다.
- 평가서는 PR head commit SHA를 기록한다.

## 13. 완료 보고 형식

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```

