---
task_id: P0-000
title: Replace with task title
status: planned
issue: null
pull_request: null
evaluated_commit: null
work_order: ../tasks/P0-000-work-order.md
evaluation_version: 1
verdict: null
---

# P0-000 평가서: 제목

## 1. 평가 목적

작업지시서의 Acceptance Criteria를 구현과 독립적으로 검증한다. 이 문서는 구현 전에 검증 방법까지 확정하고, 구현 후 결과와 evidence만 채운다.

## 2. 평가 대상 고정

- Work order version: 1
- Issue:
- PR:
- Evaluated commit SHA:
- 변경 범위:

commit SHA가 바뀌면 영향받는 평가 항목을 다시 실행한다.

## 3. Acceptance Criteria 검증표

| AC | 검증 방법 | 사전 예상 결과 | 결과 | Evidence |
|---|---|---|---|---|
| AC-1 | test/inspection | 예상 결과 | 미평가 | 실행 결과/파일 |
| AC-2 | test/inspection | 예상 결과 | 미평가 | 실행 결과/파일 |
| AC-3 | test/inspection | 예상 결과 | 미평가 | 실행 결과/파일 |

## 4. 필수 평가

| 평가 항목 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| Correctness | 모든 AC 충족 | 미평가 | |
| Scope | 제외 범위 침범 없음 | 미평가 | |
| Tests | 지정 및 영향 test 통과 | 미평가 | |
| Safety | 해당 안전 invariant 충족 | 미평가 | |
| Maintainability | package 책임과 명시적 의존성 유지 | 미평가 | |
| Documentation | 계약 변경 반영 | 미평가 | |

## 5. 평가 명령

```bash
# 작업지시서와 독립적으로 실행할 command
```

## 6. Negative/edge case

- 실패 입력 또는 경계 조건
- 취소/timeout/redaction 해당 여부

## 7. 회귀 범위

- 반드시 다시 실행할 기존 test
- 실행하지 않아도 되는 범위와 이유

## 8. 평가 결과

```text
Verdict: PASS | FAIL | INCONCLUSIVE

AC-1: 미평가
AC-2: 미평가
AC-3: 미평가
Scope: 미평가
Tests: 미평가
Safety: 미평가
Maintainability: 미평가
Documentation: 미평가
```

## 9. 실패 시 재작업 계약

- 실패한 AC:
- 재현 test:
- 허용 변경 파일:
- 변경 금지 범위:
- rework issue:

필수 평가 하나라도 FAIL이면 전체 verdict는 FAIL이다. 근거가 부족하면 INCONCLUSIVE이며 merge할 수 없다.

## 10. 최종 승인

- Evaluator:
- Evaluated at:
- Verdict:
- Evidence commit/artifact:

