# RolloutProof 로컬 개발 환경

> 상태: 0.1-draft  
> 기준 host: macOS MacBook  
> 관련 Issue: [#43](https://github.com/ch0992/rollout-proof/issues/43)  
> 호환성 계약: [Kubernetes Cluster 호환성](./cluster-compatibility.md)
> 테스트 계획: [테스트 전략 및 검증 계획](./test-strategy.md)
> 구축 후 검증: [로컬 개발 인프라 검증 계약](./local-environment-validation.md)

## 1. 결정

RolloutProof의 Mac 기본 개발 환경은 다음 topology로 고정한다.

```text
macOS
  └── Colima profile: rolloutproof
       └── Docker runtime
            └── kind cluster
                 ├── control-plane node
                 └── worker node
```

- 기본 container runtime VM은 **Colima + Docker runtime**이다.
- 기본 local Kubernetes는 **kind**다.
- Colima의 내장 Kubernetes(k3s)는 기본 환경에서 활성화하지 않는다.
- Docker Desktop은 동일한 kind workflow를 실행하는 지원 provider다.
- Podman/nerdctl은 kind upstream에서 지원하지만 Phase 0 필수 검증 대상은 아니다.
- local environment와 CI는 동일한 kind config 및 node image digest를 사용한다.

이 구조는 Mac runtime 선택과 Kubernetes distribution 선택을 분리한다. Colima 내장 k3s를 함께 활성화하면 `kubectl` context, network 및 image load 경로가 kind와 혼동되므로 canonical workflow에서는 금지한다.

## 2. 지원 Host

| 환경 | 등급 | 비고 |
|---|---|---|
| Apple Silicon Mac | Primary | 모든 PR 전 local workflow 기준 |
| Intel Mac | Supported | 동일 명령, native amd64 image 사용 |
| Linux amd64 GitHub Actions | CI Primary | version matrix와 release gate |
| Linux arm64 | Release build | E2E는 runner 가용성에 따라 nightly |
| Windows/WSL2 | Community | 초기 공식 개발환경에서 제외 |

macOS의 특정 patch version보다 tool version과 architecture를 `doctor` 결과에 기록한다. 공개 contributor 문서에는 지원 중인 macOS major version 두 개를 기준으로 명시하고 실제 CI가 없는 host는 보장하지 않는다.

## 3. 필수 도구

| 도구 | 용도 | Version 정책 |
|---|---|---|
| Go | build/test | 1.26 최신 patch |
| Homebrew | Mac 설치 | stable |
| Colima | Docker runtime VM | stable, project bootstrap에서 pin |
| Docker CLI | kind provider/build | Colima와 호환되는 stable |
| kind | local Kubernetes | project bootstrap에서 exact pin |
| kubectl | cluster inspection | API server ±1 minor |
| jq | test artifact 처리 | stable |
| Git/GitHub CLI | 형상관리 | stable |

초기 문서에서는 floating `latest`를 실행 계약으로 사용하지 않는다. `P0-000` 구현 시 `Brewfile`과 tool-version manifest에 exact version을 기록하고 Dependabot/Renovate와 별개의 환경 갱신 PR로 관리한다.

## 4. 설치 방식

Homebrew를 기본 bootstrap 경로로 사용한다.

```bash
brew install go colima docker kind kubectl jq
```

실제 repository에는 다음 command를 제공한다.

```bash
make dev-bootstrap     # 누락 도구와 version 안내, 자동 destructive 변경 없음
make dev-doctor        # host/runtime/tool/architecture 진단
make runtime-up        # 전용 Colima profile 시작
make cluster-up        # pinned kind cluster 시작
make cluster-status
make cluster-down      # RolloutProof 전용 kind cluster만 삭제
make runtime-down      # 전용 Colima profile 중지, 기본적으로 delete하지 않음
```

`dev-bootstrap`은 임의로 Homebrew package를 설치하거나 기존 Docker context를 바꾸지 않는다. 필요한 명령을 안내하고 사용자가 명시적으로 실행하도록 한다.

## 5. Colima Profile

project 전용 profile 이름은 `rolloutproof`다.

초기 권장 자원:

| 자원 | 기본값 |
|---|---:|
| CPU | 4 |
| Memory | 8 GiB |
| Disk | 60 GiB |
| Runtime | Docker |
| Kubernetes | Disabled |

개념적 실행 명령:

```bash
colima start rolloutproof \
  --runtime docker \
  --cpu 4 \
  --memory 8 \
  --disk 60
```

Apple Silicon에서는 native `arm64`를 사용한다. `amd64` emulation은 cross-architecture 검증을 위한 별도 opt-in profile에서만 사용한다.

기존 사용자의 default Colima profile이나 Docker Desktop context를 삭제·재구성하지 않는다. Make target은 현재 Docker context를 검사하고 예상 context가 아니면 명시적으로 실패한다.

## 6. kind Cluster

### 6.1 이름

- 기본 cluster 이름: `rolloutproof-dev`
- version matrix 이름: `rolloutproof-k134`, `rolloutproof-k135`, `rolloutproof-k136`
- context 이름: `kind-<cluster-name>`
- namespace: `rolloutproof-e2e-<run-id>`

### 6.2 Topology

기본은 control-plane 1개와 worker 1개다. single-node 환경보다 Pod scheduling, EndpointSlice 변화 및 node 간 network 경로를 현실적으로 관찰할 수 있기 때문이다.

HA control plane, multi-worker, 특정 CNI는 별도 scenario config로 제공한다. 기본 cluster에 모든 변형을 넣지 않는다.

### 6.3 Version

Kubernetes version은 kind node image tag와 SHA256 digest로 고정한다.

```yaml
nodes:
  - role: control-plane
    image: kindest/node:<version>@sha256:<digest>
  - role: worker
    image: kindest/node:<version>@sha256:<digest>
```

지원 minor의 최신 patch와 digest는 `test/e2e/kind/versions.yaml` 한 곳에서 관리한다. tag만 사용하지 않는다. minor patch 갱신은 compatibility matrix 전체를 통과해야 한다.

## 7. Kubeconfig 격리

local/E2E는 사용자의 기본 kubeconfig를 직접 수정하지 않는다.

- 생성 위치: repository 내부 ignored directory인 `.work/kubeconfig`
- 모든 test command는 명시적 `--kubeconfig` 또는 task 전용 환경변수를 사용한다.
- `kubectl config use-context`로 사용자 global current-context를 바꾸지 않는다.
- command 시작 시 context, server URL, cluster UID, namespace를 출력한다.
- context가 허용 prefix와 일치하지 않으면 local mutation test를 중단한다.

`.work` 밖이나 사용자 home을 cleanup target으로 사용하지 않는다.

## 8. Image Build와 Load

- fixture image는 native host architecture로 build한다.
- local registry 없이 `kind load docker-image --name <cluster>`를 기본으로 한다.
- image tag에 Task/commit SHA를 포함해 stale image 사용을 막는다.
- `imagePullPolicy: IfNotPresent`와 immutable local tag를 함께 사용한다.
- multi-arch release image 검증은 local kind test와 분리한다.

## 9. Network 접근

RolloutProof는 두 관측 위치를 구분한다.

1. **Host external probe**: Mac/CI runner에서 Ingress, NodePort, port-forward 또는 명시 URL로 요청한다.
2. **Cluster internal probe**: MVP-B에서 opt-in ephemeral resource가 Service/ClusterIP로 요청한다.

kind에서 host external probe의 기본 경로는 test harness가 관리하는 `kubectl port-forward`다. LoadBalancer 구현이나 cloud LB를 local 필수조건으로 만들지 않는다. port-forward 자체의 실패는 rollout failure와 별도 category로 기록해야 한다.

## 10. Local 작업 순서

```text
make dev-doctor
  → make runtime-up
  → make cluster-up K8S_MINOR=1.36
  → make fixture-load
  → make e2e-smoke
  → make cluster-down
```

실패 시 `make cluster-logs`가 kind log, object snapshot 및 RolloutProof artifact를 `.work/artifacts/<run-id>`에 보존한다.

## 11. Docker Desktop 대체 경로

Docker Desktop 사용자는 Colima를 시작하지 않고 Docker context를 명시한다.

```bash
ROLLOUTPROOF_CONTAINER_PROVIDER=docker \
ROLLOUTPROOF_DOCKER_CONTEXT=desktop-linux \
make cluster-up
```

kind config, node image, kubeconfig, fixture 및 test는 Colima 경로와 같아야 한다. provider-specific 분기는 runtime 시작/진단까지만 허용한다.

## 12. Doctor 계약

`make dev-doctor` 또는 향후 `rollout-proof dev doctor`는 다음을 출력한다.

- OS/version/architecture
- Go/kind/kubectl/Colima/Docker version
- 선택된 container provider와 Docker context
- Colima profile runtime 및 Kubernetes disabled 여부
- CPU/memory/disk allocation
- kind cluster/context
- Kubernetes server version
- required API discovery 결과
- current namespace와 mutation safety 상태

secret, kubeconfig credential 및 token은 출력하지 않는다. 결과는 bug report에 첨부 가능한 Markdown/JSON으로 저장할 수 있어야 한다.

## 13. 금지 사항

- default kubeconfig context를 암묵적으로 사용하지 않는다.
- cluster 이름 없이 모든 kind cluster를 삭제하지 않는다.
- default Colima profile을 자동 삭제하지 않는다.
- Docker Desktop 설치를 유일한 선택으로 강제하지 않는다.
- Colima k3s 결과를 kind matrix 결과로 기록하지 않는다.
- unpinned kind node image를 release evidence로 사용하지 않는다.
- local PASS만으로 cloud/on-prem compatibility를 주장하지 않는다.

## 14. Definition of Ready

다음이 구현되고 [로컬 개발 인프라 검증 계약](./local-environment-validation.md)이 PASS하면 개발환경이 Ready다.

1. Apple Silicon Mac에서 bootstrap/doctor/runtime-up/cluster-up/smoke/down이 재현된다.
2. Docker Desktop 경로에서 같은 kind smoke test가 통과한다.
3. kubeconfig와 artifact가 repository 격리 경로를 사용한다.
4. 다른 kind cluster와 Docker context를 훼손하지 않는다.
5. Kubernetes 1.34~1.36 node image digest가 manifest에 고정된다.
6. 명령과 예상 결과가 contributor 문서에 기록된다.

## 참고 자료

- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
- [Colima Installation](https://colima.run/docs/installation/)
- [Colima Runtimes](https://colima.run/docs/runtimes/)
- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
