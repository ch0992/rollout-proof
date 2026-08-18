---
task_id: P0-009
title: "v1alpha1 최소 Report DTO 정의"
status: planned
issue: null
pull_request: null
evaluated_commit: null
work_order: ../tasks/P0-009-work-order.md
evaluation_version: 1
verdict: null
---

# P0-009 평가서: v1alpha1 최소 Report DTO 정의

## 1. 평가 목적

[P0-009 작업지시서](../tasks/P0-009-work-order.md)의 계약을 구현 설명과 독립적으로 검증한다. 검증 방법과 PASS 조건은 구현 전에 고정하며 구현 후에는 결과와 evidence만 기록한다.

## 2. 평가 대상 고정

- Work order version: 1
- Requirement ID: `ENG-REPORT-001`
- Issue: 생성 후 기록
- PR: 생성 후 기록
- Evaluated commit SHA: 구현 후 기록
- 허용 주요 파일: `internal/report/v1alpha1/types.go`, `internal/report/v1alpha1/convert.go`, `internal/report/v1alpha1/report_test.go`, `internal/report/v1alpha1/testdata/minimal.golden.json`

commit SHA나 작업지시서 version이 바뀌면 영향받는 항목을 재평가한다.

## 3. Acceptance Criteria 검증표

| AC | 검증 방법 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|---|
| AC-1 | `go test ./internal/report/v1alpha1` 및 관련 code inspection | 최소 report가 schema version, run metadata, ordered timeline을 포함한다. | 미평가 | |
| AC-2 | `go test ./internal/report/v1alpha1 -run TestMinimalReportGolden` 및 관련 code inspection | domain Event가 명시적 mapping layer를 통해 DTO로 변환된다. | 미평가 | |
| AC-3 | `rg -n 'rollout-proof\.io' internal/report/v1alpha1` 및 관련 code inspection | timestamp는 UTC RFC3339Nano, elapsed는 정수 nanoseconds로 직렬화된다. | 미평가 | |
| AC-4 | `rg -n 'rollout-proof\.io' internal/report/v1alpha1` 및 관련 code inspection | golden JSON test가 public field 변경을 탐지한다. | 미평가 | |
| AC-5 | `rg -n 'rollout-proof\.io' internal/report/v1alpha1` 및 관련 code inspection | provisional API identifier가 한 상수에만 존재한다. | 미평가 | |

## 4. 필수 평가

| 항목 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| Correctness | 모든 AC가 PASS | 미평가 | |
| Scope | 제외 범위 구현과 무관한 변경 없음 | 미평가 | |
| Tests | 지정 command와 영향 package test PASS | 미평가 | |
| Safety | 오류/취소/출력/파일 안전 조건 위반 없음 | 미평가 | |
| Maintainability | package 책임 유지, 전역 상태와 불필요한 추상화 없음 | 미평가 | |
| Documentation | 계약 또는 결정 변경이 해당 문서에 반영됨 | 미평가 | |

## 5. 평가 명령

```bash
go test ./internal/report/v1alpha1
go test ./internal/report/v1alpha1 -run TestMinimalReportGolden
rg -n 'rollout-proof\.io' internal/report/v1alpha1
```

평가자는 구현자가 첨부한 결과를 복사하지 않고 clean working tree 또는 PR commit에서 다시 실행한다.

## 6. Negative/edge case

- Acceptance Criteria의 실패/경계 조건을 최소 1개 실행한다.
- error가 silent success로 처리되지 않는지 확인한다.
- 해당하지 않는 보안 항목은 근거와 함께 N/A로 표시한다.

## 7. 회귀 범위

- 변경 package의 전체 unit test를 실행한다.
- public type, CLI 또는 artifact가 변경되면 consumer/golden test를 실행한다.
- 전체 repository test는 merge gate에서 실행한다.

## 8. 평가 결과

```text
Verdict: PASS | FAIL | INCONCLUSIVE

AC-1: 미평가
AC-2: 미평가
AC-3: 미평가
AC-4: 미평가
AC-5: 미평가
Scope: 미평가
Tests: 미평가
Safety: 미평가
Maintainability: 미평가
Documentation: 미평가
```

## 9. 실패 시 재작업 계약

- 실패한 AC만 별도 목록으로 고정한다.
- 실패를 재현하는 test를 먼저 commit한다.
- 허용 변경 파일은 실패와 직접 관련된 파일로 축소한다.
- 같은 접근의 재작업은 최대 2회이며 이후 설계 검토로 전환한다.

## 10. 최종 승인

- Evaluator:
- Evaluated at:
- Verdict:
- Evidence commit/artifact:

