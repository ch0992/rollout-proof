---
task_id: ENV-007
title: "Kubeconfig, namespace와 artifact 격리"
status: completed
issue: https://github.com/ch0992/rollout-proof/issues/53
pull_request: https://github.com/ch0992/rollout-proof/pull/66
evaluated_commit: 14a1e4b4624b047d54ec8ff513142cfd984a475c
work_order: ../tasks/ENV-007-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-007 평가서: Kubeconfig, namespace와 artifact 격리

## 평가 대상

- Issue: #53
- 허용 파일: `scripts/env/workspace.sh`, `test/environment/isolation_test.sh`, `.gitignore`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | kubeconfig가 .work에 생성된다. | PASS | 모든 kubectl 호출이 `.work/kubeconfig`를 명시하고 artifact도 `.work` 아래 생성 |
| AC-2 | global current-context가 보존된다. | PASS | 실제 테스트 전후 모두 unset으로 동일 |
| AC-3 | test namespace 밖 mutation이 없다. | PASS | namespace 목록, Docker context, kind cluster snapshot 전후 동일 |
| AC-4 | cleanup이 run ID와 label로 제한된다. | PASS | opt-in, 정확한 namespace, managed-by와 run-id label 검증 후 삭제 확인 |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | PASS |
| Scope | non-goal 침범 없음 | PASS |
| Safety | 기존 환경과 secret 보호 | PASS |
| Idempotency | 해당 변경의 반복 실행 안전 | PASS |
| Traceability | Issue, work order, PR, SHA 연결 | PASS |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.

최종 판정: **PASS**

## 실행 Evidence

- `bash -n`, `shellcheck`, `git diff --check`: PASS
- `test/environment/isolation_test.sh`: 실제 cluster에서 PASS
- opt-in 없는 init/cleanup: exit `6`
- global context: unset → unset
- Docker context: `desktop-linux` → `desktop-linux`
- kind clusters: `rolloutproof-dev` 보존
- test 전후 namespace: default 및 system namespace 목록 동일, test namespace cleanup 완료
- artifact: `.work/artifacts/environment/runs/<run-id>` 아래로 제한
- 변경 파일은 허용된 3개와 일치하며 평가 기록 commit은 대상에서 제외한다.
