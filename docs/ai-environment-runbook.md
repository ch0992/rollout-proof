# AI 로컬 환경 구축 Runbook

> 상태: 0.1-draft
> 자동화 계약: [환경 자동화 스펙](./environment-automation-spec.md)

## 1. 현재 Mac 기준

- architecture: Apple Silicon arm64
- provider: Docker Desktop
- Docker context: `desktop-linux`
- existing Kubernetes context: 없음
- Colima: 사용하지 않음
- project cluster: `rolloutproof-dev`
- kubeconfig: `.work/kubeconfig`

## 개발 shell 활성화

클러스터 구축 후 어느 디렉터리에서든 저장소의 절대경로로 활성화 스크립트를 source한다.

```bash
source /Users/yg/workspace/rollout-proof/scripts/env/activate.sh
kubectl get pods -A
rolloutproof-env-deactivate
```

스크립트는 기존 `KUBECONFIG`와 mise trust 설정을 보존하고 비활성화할 때 복원한다. 사용자 `.zshrc`나 global kubeconfig current-context는 변경하지 않는다.

`export KUBECONFIG="$PWD/.work/kubeconfig"`는 현재 디렉터리가 저장소가 아닐 경우 잘못된 경로를 만든다. 특히 홈 디렉터리에서 이 명령을 사용하면 kubectl이 설정을 읽지 못하고 `localhost:8080`으로 fallback할 수 있으므로 사용하지 않는다.

이 값은 초기 inventory이며 AI는 매 실행 시 다시 검사한다.

## 2. 실행 순서

```text
1. 작업지시서/평가서 확인
2. make env-check
3. make env-plan
4. 변경 예정 사항 보고
5. 승인된 apply
6. provider verify
7. kind cluster apply
8. make env-verify
9. make env-report
10. 평가서에 evidence 연결
```

## 3. 중단 조건

- Docker context가 예상값과 다름
- global kubeconfig context가 변경됨
- cluster 이름이 `rolloutproof-*`가 아님
- `.work` 밖 cleanup이 필요함
- disk/memory가 최소 조건 미달
- unpinned binary 또는 kind node image
- secret이 output에 포함됨
- 같은 check가 두 번 연속 실패함

중단 시 자동 reset하지 않고 실패 check ID, 관측 상태, 안전한 recovery command를 보고한다.

## 4. 설치 정책

- `env-check`와 `env-plan`은 설치하지 않는다.
- package 설치는 작업지시서의 명시적 범위와 `APPLY=true`가 필요하다.
- Docker Desktop은 AI가 제거·재설치하지 않는다.
- 설치 후 version과 checksum을 다시 검증한다.

## 5. Cluster 구축 정책

- dedicated kubeconfig를 명시한다.
- digest-pinned kind node image를 사용한다.
- create 전에 같은 이름 cluster의 config drift를 확인한다.
- 기존 cluster가 같으면 재사용하고 다르면 중단한다.
- fixture는 전용 namespace와 run ID label을 사용한다.

## 6. 성공 보고

```text
Environment verdict: READY
Provider/context:
Cluster/version/digest:
Kubeconfig category:
Mandatory checks:
Isolation result:
Idempotency result:
Artifacts:
Commit SHA:
```

## 7. 실패 보고

```text
Environment verdict: FAIL | INCONCLUSIVE
Failed check IDs:
Observed state:
Expected state:
Changes already applied:
Unrelated resources preserved:
Recovery commands:
Approval required:
```
