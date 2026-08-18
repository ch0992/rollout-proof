---
task_id: ENV-010
title: "Linux CI kind matrix와 provider portability"
status: evaluated
issue: https://github.com/ch0992/rollout-proof/issues/56
pull_request: https://github.com/ch0992/rollout-proof/pull/74
evaluated_commit: 7fbdd37d9a0b6f0f6371bb34c78e18507bebeaef
work_order: ../tasks/ENV-010-work-order.md
evaluation_version: 1
verdict: PASS
---

# ENV-010 평가서: Linux CI kind matrix와 provider portability

## 평가 대상

- Issue: #56
- 허용 파일: `.github/workflows/environment.yml`, `test/environment/ci.sh`
- Evaluated commit: `7fbdd37d9a0b6f0f6371bb34c78e18507bebeaef`
- GitHub Actions: [run 32187590702](https://github.com/ch0992/rollout-proof/actions/runs/32187590702)

## Acceptance 검증

| AC | PASS 조건 | 결과 | Evidence |
|---|---|---|---|
| AC-1 | Linux Docker에서 공통 kind IaC를 사용한다. | PASS | Ubuntu runner에서 `test/environment/ci.sh`가 `infra/local/kind/cluster.yaml`과 `versions.yaml`을 사용해 각 클러스터를 생성했다. |
| AC-2 | 1.34~1.36 matrix가 실행된다. | PASS | run 32187590702의 `Kubernetes 1.34`, `1.35`, `1.36` job이 모두 성공했고 각 보고서가 실제 server version을 기록했다. |
| AC-3 | artifact와 checksum을 보존한다. | PASS | `environment-kubernetes-1.34`~`1.36` artifact 3개를 내려받아 `shasum -a 256 -c checksums.sha256` 6건이 모두 OK였다. |
| AC-4 | Mac provider 분기가 core test에 침투하지 않는다. | PASS | `rg 'docker-desktop|colima|Darwin|macOS' test/environment/ci.sh` 결과가 없으며 CI core는 Docker API와 공통 kind IaC만 요구한다. |

## Mandatory Rubric

| 항목 | PASS 조건 | 결과 |
|---|---|---|
| Correctness | AC 전체 충족 | PASS — AC-1~4 전체 PASS |
| Scope | non-goal 침범 없음 | PASS — 구현 파일 2개와 본 평가 기록만 변경 |
| Safety | 기존 환경과 secret 보호 | PASS — 전용 kubeconfig와 정확한 cluster name을 사용하고 `ALLOW_DELETE=true`일 때만 삭제 |
| Idempotency | 해당 변경의 반복 실행 안전 | PASS — 기존 정확한 이름의 cluster는 kubeconfig만 재수출하고 cleanup은 정확한 대상만 삭제 |
| Traceability | Issue, work order, PR, SHA 연결 | PASS — Issue #56, 작업지시서, PR #74, evaluated SHA, Actions run 연결 |

## 판정

**PASS.** 모든 Acceptance Criteria와 Mandatory Rubric을 충족했다.

## 재현 명령

```bash
bash -n test/environment/ci.sh
shellcheck test/environment/ci.sh
for minor in 1.34 1.35 1.36; do
  test/environment/ci.sh plan --minor "${minor}"
done
rg 'docker-desktop|colima|Darwin|macOS' test/environment/ci.sh
gh run view 32187590702
gh run download 32187590702 --dir <temporary-directory>
find <temporary-directory> -name checksums.sha256 \
  -exec sh -c 'cd "$(dirname "$1")" && shasum -a 256 -c checksums.sha256' _ {} \;
git diff --check
```
