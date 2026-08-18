---
task_id: ENV-012
title: "Environment Make entrypoints와 clean-room rehearsal"
status: evaluated
issue: https://github.com/ch0992/rollout-proof/issues/78
pull_request: https://github.com/ch0992/rollout-proof/pull/79
evaluated_commit: 6db24a77ddbbaf2f2db5dddbd7d98ca1e64715e3
work_order: ../tasks/ENV-012-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-012 평가서: Environment Make entrypoints와 clean-room rehearsal

## 평가 대상

- Issue: #78
- Evaluated commit: `6db24a77ddbbaf2f2db5dddbd7d98ca1e64715e3`
- GitHub Actions: [run 32189630005](https://github.com/ch0992/rollout-proof/actions/runs/32189630005)
- Local rehearsal run ID: `env012-rehearsal`

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | check/plan 무변경 | PASS | `make env-check`, `make env-plan`이 plan/READY만 출력했고 삭제 후 plan은 `CREATE_REQUIRES_APPLY_TRUE`를 반환했다. |
| AC-2 | mutation 안전 계약 보존 | PASS | bootstrap은 `APPLY`, cleanup은 `ALLOW_DELETE`를 전달하며 cluster create는 명시적 `cluster-up` target에서만 실행된다. |
| AC-3 | 동일 run ID report | PASS | `env-verify RUN_ID=env012-rehearsal` 후 `env-report`가 같은 artifact directory와 READY/0을 반환했다. |
| AC-4 | Make 계약 테스트 | PASS | `make_targets_test: PASS`, shellcheck 및 bash syntax PASS |
| AC-5 | clean-room 및 멱등성 | PASS | owned cluster 삭제, kubeconfig 부재 확인, 1+1 node 재생성 후 두 번째 apply에서 node UID가 동일했다. |
| AC-6 | unrelated 상태 보존 | PASS | global context는 전후 `<unset>`, `rolloutproof-dev-*`를 제외한 container name/ID 목록은 동일했다. |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | PASS — AC-1~6 전체 PASS |
| Scope | P0-002와 사용자 환경을 침범하지 않음 | PASS — environment target만 추가, 제품 target과 shell profile 미변경 |
| Safety | exact target과 opt-in 유지 | PASS — ownership metadata가 일치한 `rolloutproof-dev`만 삭제 |
| Idempotency | 두 번째 apply 변경 없음 | PASS — node UID와 topology 유지 |
| Traceability | Issue, 문서, PR, SHA, artifact 연결 | PASS — Issue #78, 작업지시서, PR #79, SHA, run 및 checksum 연결 |

## 판정

**PASS.** 모든 Acceptance Criteria와 Mandatory Rubric을 충족했다.

## Artifact checksum

```text
3101a506ef93a72d789aa6c3c6390a89ac79f207b3f1ffe7ed5bd14018ec732a  verification.tsv
b5da371d2426d33227950e62a6347484f1f730174e9961d2b454e3807d05c60b  environment-report.json
8efc1db5c733acd74c9f6cfcbdd6c291b61e0595b5bb51a44968433953549df5  environment-report.md
```

## 추가 회귀 검증

- `test/environment/activate_test.sh`: PASS
- `test/environment/idempotency_test.sh`: PASS
- `test/environment/cleanup_test.sh`: PASS
- 실제 홈 디렉터리 zsh 활성화·2 node 조회·비활성화: PASS
- Linux Kubernetes 1.34, 1.35, 1.36: PASS
