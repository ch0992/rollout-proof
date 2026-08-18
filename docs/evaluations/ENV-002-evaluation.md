---
task_id: ENV-002
title: "Tool version manifest와 read-only bootstrap"
status: planned
issue: https://github.com/ch0992/rollout-proof/issues/48
pull_request: null
evaluated_commit: null
work_order: ../tasks/ENV-002-work-order.md
evaluation_version: 1
verdict: null
---

# ENV-002 평가서: Tool version manifest와 read-only bootstrap

## 평가 대상

- Issue: #48
- 허용 파일: `Brewfile`, `mise.toml`, `infra/local/tool-versions.yaml`, `scripts/env/bootstrap.sh`
- evaluated commit은 구현 후 고정한다.

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | 필수 tool/version/checksum source가 한 곳에 정의된다. | 미평가 | |
| AC-2 | 기본 bootstrap은 read-only plan이다. | 미평가 | |
| AC-3 | APPLY=true 없이는 package를 설치하지 않는다. | 미평가 | |
| AC-4 | Apple Silicon과 amd64 선택을 검증한다. | 미평가 | |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | 미평가 |
| Scope | non-goal 침범 없음 | 미평가 |
| Safety | 기존 환경과 secret 보호 | 미평가 |
| Idempotency | 해당 변경의 반복 실행 안전 | 미평가 |
| Traceability | Issue, work order, PR, SHA 연결 | 미평가 |

## 판정

필수 항목 하나라도 FAIL이면 전체 FAIL이다. evidence가 부족하면 INCONCLUSIVE이며 merge하지 않는다.

