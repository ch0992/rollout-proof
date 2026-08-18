---
task_id: ENV-002
title: "Tool version manifest와 read-only bootstrap"
status: completed
issue: https://github.com/ch0992/rollout-proof/issues/48
pull_request: https://github.com/ch0992/rollout-proof/pull/58
evaluated_commit: 4170ccf294e87be1af16de2f2dac2b8692567a69
work_order: ../tasks/ENV-002-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-002 평가서: Tool version manifest와 read-only bootstrap

## 평가 대상

- Issue: #48
- 허용 파일: `Brewfile`, `mise.toml`, `infra/local/tool-versions.yaml`, `scripts/env/bootstrap.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 필수 tool/version/checksum source가 한 곳에 정의된다. | PASS | `tool-versions.yaml`에 mise, Go, kind, kubectl 버전 및 공식 source 정의 |
| AC-2 | 기본 bootstrap은 read-only plan이다. | PASS | 실제 arm64 환경에서 2회 실행 결과 동일하고 worktree 변경 없음 |
| AC-3 | APPLY=true 없이는 package를 설치하지 않는다. | PASS | 기본 실행은 명령 출력 후 `PLAN_ONLY`; mock apply에서만 brew/mise 호출 확인 |
| AC-4 | Apple Silicon과 amd64 선택을 검증한다. | PASS | 실제 `darwin_arm64`와 mock `darwin_amd64`가 각각 대응 checksum source를 선택 |

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

- `bash -n scripts/env/bootstrap.sh`: PASS
- `shellcheck scripts/env/bootstrap.sh`: PASS
- `git diff --check`: PASS
- 기본 plan 2회 결과 동일, worktree mutation 없음: PASS
- `APPLY=true` mock 실행에서 `brew bundle`, pinned `mise install`, 버전별 `mise exec`만 호출: PASS
- arm64/amd64 공식 checksum URL 6개 접근 및 architecture 선택: PASS
- 변경 파일은 평가 계약의 허용 파일 4개와 일치: PASS
- 실제 package 설치는 안전 계약에 따라 이 평가에서 수행하지 않았다.
- 평가 기록 commit은 evaluated commit에서 제외한다.
