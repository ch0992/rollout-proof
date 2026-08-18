---
task_id: P0-009
title: "v1alpha1 최소 Report DTO 정의"
status: backlog
size: S
milestone: Phase 0
epic: P0-E2
issue: https://github.com/ch0992/rollout-proof/issues/15
branch: "feat/15-p0-009-report-v1alpha1"
work_order_version: 1
evaluation_document: ../evaluations/P0-009-evaluation.md
---

# P0-009 작업지시서: v1alpha1 최소 Report DTO 정의

## 1. 목적

v1alpha1 최소 Report DTO 정의을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-REPORT-001`
- 제품 스펙 §13 Report schema
- 엔지니어링 구현 스펙 §12 Report와 파일 I/O
- ADR-0001 API identifier 보류

## 4. 작업 범위

- 최소 report envelope
- domain Event에서 DTO 변환
- UTC RFC3339Nano/elapsed serialization
- golden JSON

## 5. 제외 범위

- finding/verdict 전체 schema
- JSONL 분리
- Markdown/JUnit renderer

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `internal/report/v1alpha1/types.go` | 생성 또는 수정 | v1alpha1 최소 Report DTO 정의 |
| `internal/report/v1alpha1/convert.go` | 생성 또는 수정 | v1alpha1 최소 Report DTO 정의 |
| `internal/report/v1alpha1/report_test.go` | 생성 또는 수정 | v1alpha1 최소 Report DTO 정의 |
| `internal/report/v1alpha1/testdata/minimal.golden.json` | 생성 또는 수정 | v1alpha1 최소 Report DTO 정의 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

domain type을 직접 marshal하지 않는다. provisional schema identifier는 상수 한 곳에서만 관리하고 ADR-0001의 보류 상태를 주석으로 연결한다.

## 8. Acceptance Criteria

- [ ] AC-1: 최소 report가 schema version, run metadata, ordered timeline을 포함한다.
- [ ] AC-2: domain Event가 명시적 mapping layer를 통해 DTO로 변환된다.
- [ ] AC-3: timestamp는 UTC RFC3339Nano, elapsed는 정수 nanoseconds로 직렬화된다.
- [ ] AC-4: golden JSON test가 public field 변경을 탐지한다.
- [ ] AC-5: provisional API identifier가 한 상수에만 존재한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/report/v1alpha1
go test ./internal/report/v1alpha1 -run TestMinimalReportGolden
rg -n 'rollout-proof\.io' internal/report/v1alpha1
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/15-p0-009-report-v1alpha1`
- Commit prefix: `[P0-009]`
- PR title: `[P0-009] v1alpha1 최소 Report DTO 정의`
- PR 본문: `Closes #15`와 작업지시서/평가서 링크
- merge 조건: 평가서 PASS와 required CI PASS

## 13. 완료 보고 형식

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```

