---
task_id: P0-035
title: "10회 반복 재현 harness"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/41
pull_request: null
evaluated_commit: null
work_order: ../tasks/P0-035-work-order.md
evaluation_version: 1
verdict: null
---

# P0-035 평가서: 10회 반복 재현 harness

## 1. 평가 계약

[작업지시서](../tasks/P0-035-work-order.md)의 검증 방법과 PASS 조건은 구현 전에 고정한다. 구현 후에는 결과와 evidence만 기록한다.

## 2. 평가 대상

- Work order version: 1
- Requirement ID: `TEST-E2E-005`
- Issue/PR/commit SHA: 구현 후 기록
- 허용 주요 파일: `test/e2e/repeat.sh`, `test/e2e/repeat_test.go`, `docs/experiments/phase-0-results.md`

## 3. Acceptance Criteria 검증표

| AC | 검증 방법 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|---|
| AC-1 | command + 관련 inspection | 정확히 요청한 count만큼 독립 run을 수행한다. | 미평가 | |
| AC-2 | command + 관련 inspection | run별 exit/result/artifact 경로를 보존한다. | 미평가 | |
| AC-3 | command + 관련 inspection | 정상 누락률과 결함 탐지율을 계산한다. | 미평가 | |
| AC-4 | command + 관련 inspection | 실패 run을 자동으로 PASS까지 retry하지 않는다. | 미평가 | |

## 4. 필수 평가

| 항목 | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| Correctness | 모든 AC PASS | 미평가 | |
| Scope | 제외 범위 침범 없음 | 미평가 | |
| Tests | targeted/affected test PASS | 미평가 | |
| Safety | 해당 오류·취소·보안 invariant 충족 | 미평가 | |
| Maintainability | 책임 분리, 불필요한 전역/추상화 없음 | 미평가 | |
| Documentation | 외부 계약/결정 변경 반영 | 미평가 | |

## 5. 독립 평가 명령

```bash
go test ./test/e2e -run TestRepeatHarness
test/e2e/repeat.sh --scenario normal --count 10
test/e2e/repeat.sh --scenario endpoint-gap --count 10
```

평가자는 PR commit에서 명령을 다시 실행하고 성공 요약이 아닌 exit code와 artifact를 증거로 남긴다.

## 6. Negative 및 회귀 검사

- 최소 하나의 실패/경계 조건을 재현한다.
- error가 success로 바뀌거나 evidence가 silent drop되지 않는지 확인한다.
- 변경 package 전체 test를 실행하고 repository 전체 test는 merge gate에서 실행한다.

## 7. 판정 기록

```text
Verdict: PASS | FAIL | INCONCLUSIVE
AC-1: 미평가
AC-2: 미평가
AC-3: 미평가
AC-4: 미평가
Scope: 미평가
Tests: 미평가
Safety: 미평가
Maintainability: 미평가
Documentation: 미평가
```

## 8. 실패 시 재작업

실패 AC, 재현 test, 허용 파일과 변경 금지 범위를 고정한다. 동일 접근의 재작업은 최대 2회이며 이후 설계 검토로 전환한다.

## 9. 최종 승인

- Evaluator:
- Evaluated at:
- Evaluated commit:
- Verdict:
- Evidence artifact:

