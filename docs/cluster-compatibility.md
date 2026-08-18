# RolloutProof Kubernetes Cluster 호환성 계약

> 상태: 0.1-draft  
> 목적: local kind에서 개발한 RolloutProof가 on-premises와 managed cloud Kubernetes에서 provider 종속 없이 동작하도록 하는 계약

## 1. 호환성 원칙

RolloutProof core는 Kubernetes distribution이나 cloud provider가 아니라 **Kubernetes API capability**를 기준으로 동작한다.

- cloud SDK를 core dependency로 추가하지 않는다.
- node, CNI 또는 load balancer에 직접 접속하지 않는다.
- stable Kubernetes API와 kubeconfig/client-go 인증을 사용한다.
- cluster에 controller, CRD 또는 daemonset을 설치하지 않는다.
- provider를 이름으로 allowlist하지 않고 API discovery와 RBAC preflight로 판정한다.
- 지원 주장과 실제 검증 범위를 분리해 표시한다.

## 2. 호환성 등급

| 등급 | 의미 |
|---|---|
| Supported | 명시된 Kubernetes version과 required API를 만족하면 bug를 지원 대상으로 취급 |
| Continuously Tested | PR/nightly 자동 matrix에서 반복 검증 |
| Release Tested | release candidate마다 실제 distribution에서 smoke 검증 |
| Expected Compatible | 표준 API 기준으로 동작해야 하나 아직 반복 검증되지 않음 |
| Unsupported | 필요한 API/version/RBAC 조건을 만족하지 않음 |

문서와 CLI는 `Supported`를 `Tested`로 오해하게 표현하지 않는다.

## 3. Version 범위

최초 지원 범위는 Kubernetes 1.34, 1.35, 1.36이다. Kubernetes upstream의 최근 세 minor 지원 정책에 맞춰 갱신한다.

- client-go는 지원 하한인 `v0.34.x`에 정렬한다.
- stable API만 compile-time dependency로 사용한다.
- 각 minor 최신 patch를 기본 matrix로 사용한다.
- 새 minor 추가 시 가장 오래된 minor 제거는 별도 compatibility release note로 알린다.
- EOL cluster는 명시적으로 best-effort이며 regression gate가 아니다.

## 4. Required API

Read-only external gate에 필요한 최소 capability:

| API | Resource | Verb |
|---|---|---|
| `apps/v1` | deployments | get, list, watch |
| `apps/v1` | replicasets | get, list, watch |
| `v1` | pods | get, list, watch |
| `v1` | services | get, list |
| `discovery.k8s.io/v1` | endpointslices | get, list, watch |
| `events.k8s.io/v1` 또는 fallback | events | get, list, watch |
| `authorization.k8s.io/v1` | selfsubjectaccessreviews | create |

CLI는 실행 전 API discovery와 RBAC을 검사하고 다음 중 하나로 판정한다.

- `compatible`: 필요한 API와 권한이 모두 있음
- `degraded`: optional Event API 등이 없어 제한된 evidence로 실행 가능
- `incompatible`: 핵심 resource/API가 없음
- `forbidden`: 필요한 read 권한이 없음

distribution 이름만 보고 호환성을 판정하지 않는다.

## 5. Distribution Matrix

### 5.1 지속 자동 검증

| 환경 | Version | 주기 | 목적 |
|---|---|---|---|
| kind/Linux | 1.34, 1.35, 1.36 | nightly/merge gate | API/version regression |
| kind/macOS Colima | 대표 최신 minor | contributor smoke | Mac workflow |
| kind/macOS Docker Desktop | 대표 최신 minor | release 전 수동 | provider portability |

### 5.2 Release 검증 목표

| 유형 | 초기 대상 | 검증 주기 |
|---|---|---|
| Upstream/on-prem style | kubeadm 또는 유사 conformant cluster | release candidate |
| Lightweight/on-prem | K3s 또는 RKE2 | release candidate 또는 월간 |
| AWS managed | EKS | minor release |
| Google managed | GKE | minor release |
| Azure managed | AKS | minor release |
| Enterprise distribution | OpenShift | compatibility report 확보 시 |

모든 provider를 모든 PR에서 실행하지 않는다. PR은 deterministic kind matrix를 사용하고 실제 provider는 release compatibility suite와 community report로 보완한다.

## 6. Test Layer

```text
L0 Domain
  외부 cluster 없음: state machine, analyzer, report

L1 API Contract
  fake API server: LIST/WATCH/410/RBAC/discovery

L2 Local Distribution
  kind 1.34~1.36: 실제 Deployment/Pod/EndpointSlice

L3 Distribution Smoke
  K3s/RKE2/kubeadm/OpenShift: API와 lifecycle 차이

L4 Managed Cloud
  EKS/GKE/AKS: auth, network, admission, LB 차이
```

상위 layer가 하위 layer를 대체하지 않는다. provider test 실패를 domain unit test로 우회하지 않는다.

## 7. Portable Implementation 규칙

- object 관계는 이름 prefix가 아닌 selector, ownerReference와 UID로 연결한다.
- EndpointSlice address type과 nil condition 의미를 보존한다.
- Kubernetes Event가 누락되거나 TTL로 사라질 수 있음을 전제로 한다.
- resourceVersion을 cluster 간 또는 resource 간 전역 sequence로 취급하지 않는다.
- watch reconnect와 410 relist를 정상 운영 조건으로 처리한다.
- admission controller가 unknown annotation/mutation을 적용할 수 있음을 허용한다.
- Service type LoadBalancer가 존재한다고 가정하지 않는다.
- Ingress controller, service mesh, CNI의 존재를 기본 전제로 하지 않는다.
- auth provider 실행과 token refresh는 client-go kubeconfig plugin에 위임한다.
- proxy, custom CA, SNI 및 exec credential을 `rest.Config`에서 보존한다.

## 8. Network 차이 검증

HTTP continuity 결과는 다음 경로에 따라 달라질 수 있다.

- kube-proxy iptables/IPVS/nftables
- eBPF dataplane(Cilium 등)
- cloud VPC-native dataplane
- service mesh sidecar/ambient mode
- Ingress/Gateway/L4 load balancer
- external DNS/CDN

RolloutProof는 경로를 자동으로 같은 것으로 간주하지 않는다. report에 probe origin, target URL, resolved address, protocol, connection profile과 가능한 network metadata를 기록한다.

초기 matrix:

1. kind 기본 network
2. Cilium kind scenario
3. 실제 managed cloud 기본 dataplane
4. service mesh 없음

service mesh는 지원 범위를 별도 scenario로 확장하기 전까지 `Expected Compatible`로 표시한다.

## 9. 실제 Cluster Test 안전 계약

실제 on-prem/cloud cluster test는 다음 입력이 없으면 시작하지 않는다.

- 명시적 kubeconfig 경로
- 명시적 context
- 명시적 test namespace
- `ROLLOUTPROOF_E2E_ALLOW_MUTATION=true`
- run ID와 cleanup label

추가 규칙:

- `default`, `kube-system` 및 기존 application namespace를 사용하지 않는다.
- cluster-scoped resource를 생성하지 않는다.
- namespace 생성 전 cluster identity와 server URL을 출력한다.
- fixture resource에는 `app.kubernetes.io/managed-by=rollout-proof`와 `rolloutproof-test-run=<run-id>` label을 함께 사용한다.
- cleanup은 label과 namespace가 모두 일치하는 resource만 대상으로 한다.
- TTL과 수동 cleanup command를 artifact에 기록한다.
- production으로 표시된 context는 별도 `--allow-production-test` 없이는 mutation test를 거부한다.

read-only `observe` compatibility smoke는 mutation opt-in 없이 기존 사용자가 지정한 Deployment에 수행할 수 있지만, request rate와 대상 URL을 명시해야 한다.

## 10. Provider Credential

- AWS/GCP/Azure SDK를 RolloutProof binary에 포함하지 않는다.
- EKS/GKE/AKS 인증은 사용자의 kubeconfig exec plugin과 client-go가 처리한다.
- CI credential은 GitHub OIDC와 short-lived cloud role을 사용한다.
- long-lived kubeconfig/token을 repository나 artifact에 저장하지 않는다.
- credential 오류는 Kubernetes incompatibility와 구분한다.

## 11. Compatibility Suite

모든 실제 cluster에서 같은 black-box suite를 실행한다.

1. server version과 API discovery
2. read-only RBAC preflight
3. 정상 Deployment rollout
4. Pod/ReplicaSet/EndpointSlice watch
5. external new-connection probe
6. external keep-alive probe
7. watch reconnect/gap 가능한 범위 검증
8. report schema와 redaction 검증
9. fixture cleanup

결과 artifact:

```text
distribution
kubernetesVersion
architecture
apiCapabilities
networkProfile
authMethodCategory
testCommit
toolVersion
scenarioResults
knownLimitations
```

## 12. Compatibility Report

검증 결과는 `docs/compatibility/<distribution>/<version>.md`에 다음 상태로 기록한다.

- PASS: 필수 scenario 전체 통과
- PARTIAL: core는 통과했지만 optional evidence/network scenario 제한
- FAIL: required API 또는 core scenario 실패
- UNTESTED: 추론만 가능하고 evidence 없음

사용자 bug report에는 `dev doctor`와 `cluster compatibility check` 결과를 첨부하도록 한다. credential과 endpoint query는 redaction한다.

## 13. Release Gate

초기 release의 최소 gate:

1. kind 1.34~1.36 전체 PASS
2. Apple Silicon + Colima 최신 minor smoke PASS
3. Docker Desktop 최신 minor smoke PASS
4. 서로 다른 실제 distribution 두 종류 이상 PASS
5. managed cloud 하나 이상 PASS
6. 미검증 provider는 Supported/Expected Compatible을 명확히 구분

EKS/GKE/AKS 모두를 `Release Tested`로 표시하려면 같은 release commit으로 세 환경에서 suite를 실행해야 한다.

## 14. 비목표

- Kubernetes conformance test 자체를 재구현하지 않는다.
- 모든 CNI/service mesh 조합을 보장하지 않는다.
- cloud cluster를 RolloutProof가 생성하거나 관리하지 않는다.
- provider load balancer 장애의 root cause를 자동 확정하지 않는다.
- unsupported Kubernetes version의 동작을 보장하지 않는다.

## 참고 자료

- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [client-go](https://github.com/kubernetes/client-go)
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
