# RolloutProof Kubernetes Cluster 호환성 정책

> 상태: 0.2-draft
> 책임: 제품이 지원하는 Kubernetes 범위와 portability 조건 정의
> 테스트 방법과 실행 주기: [테스트 전략 및 검증 계획](./test-strategy.md)

## 1. 문서 경계

이 문서는 다음 질문에 답한다.

> RolloutProof는 어떤 Kubernetes cluster를 어떤 조건에서 지원하는가?

local cluster를 어떻게 만드는지는 [Mac 로컬 개발 환경](./development-environment.md), 그 지원 주장을 어떻게 증명하는지는 [테스트 전략 및 검증 계획](./test-strategy.md)에서 다룬다.

## 2. 호환성 원칙

RolloutProof core는 Kubernetes distribution이나 cloud provider 이름이 아니라 **Kubernetes API capability**를 기준으로 동작한다.

- cloud SDK를 core dependency로 추가하지 않는다.
- node, CNI 또는 load balancer에 직접 접속하지 않는다.
- stable Kubernetes API와 kubeconfig/client-go 인증을 사용한다.
- cluster에 controller, CRD 또는 daemonset을 설치하지 않는다.
- provider allowlist 대신 API discovery와 RBAC preflight를 사용한다.
- 지원 범위와 실제 검증 완료 범위를 별도로 공개한다.

## 3. 호환성 상태

| 상태 | 제품 의미 |
|---|---|
| Supported | version/API/RBAC 조건을 만족하며 발견된 문제를 제품 bug로 취급 |
| Expected Compatible | 표준 API상 호환되지만 해당 distribution evidence가 부족함 |
| Degraded | 실행 가능하지만 optional evidence 또는 network path가 제한됨 |
| Unsupported | required API/version 조건을 만족하지 않음 |

`Continuously Tested`, `Release Tested`, `Untested`는 제품 지원 상태가 아니라 테스트 evidence 상태이며 테스트 문서에서 정의한다.

## 4. Kubernetes Version

최초 지원 범위는 Kubernetes 1.34, 1.35, 1.36이다.

- Kubernetes upstream의 최근 세 minor 지원 정책을 따른다.
- client-go는 지원 하한인 `v0.34.x`와 정렬한다.
- stable API만 compile-time dependency로 사용한다.
- 각 minor 최신 patch를 기본 대상으로 한다.
- EOL cluster는 best-effort이며 regression 수정 보장 대상이 아니다.
- 지원 minor 변경은 release note와 compatibility report에 기록한다.

## 5. Required Capability

Read-only external gate의 최소 요구사항:

| API | Resource | Verb | 필수 여부 |
|---|---|---|---|
| `apps/v1` | deployments | get, list, watch | 필수 |
| `apps/v1` | replicasets | get, list, watch | 필수 |
| `v1` | pods | get, list, watch | 필수 |
| `v1` | services | get, list | 조건부 |
| `discovery.k8s.io/v1` | endpointslices | get, list, watch | 필수 |
| `events.k8s.io/v1` | events | get, list, watch | 선택 |
| `v1` | events fallback | get, list, watch | 선택 |
| `authorization.k8s.io/v1` | selfsubjectaccessreviews | create | preflight 권장 |

실행 전 판정:

- `compatible`: required API와 권한이 모두 있음
- `degraded`: optional Event API 등이 없어 제한된 evidence로 실행 가능
- `incompatible`: required API가 없음
- `forbidden`: 필요한 read 권한이 없음

## 6. Distribution 정책

| 유형 | 대상 | 초기 정책 |
|---|---|---|
| Local/upstream | kind | Supported |
| On-prem conformant | kubeadm 및 표준 conformant cluster | Supported |
| Lightweight | K3s, RKE2 | Expected Compatible, evidence 축적 후 Supported |
| AWS managed | EKS | Supported 조건 후보, release evidence 필요 |
| Google managed | GKE | Supported 조건 후보, release evidence 필요 |
| Azure managed | AKS | Supported 조건 후보, release evidence 필요 |
| Enterprise | OpenShift | Expected Compatible, SCC/Route 차이 별도 기록 |

distribution 이름만으로 PASS나 FAIL을 결정하지 않는다. required capability를 충족하면 실행을 허용하고, 검증되지 않은 조합은 evidence 상태를 명시한다.

## 7. Portable Implementation 규칙

- object 관계는 selector, ownerReference와 UID로 연결한다.
- 이름 prefix를 resource 관계의 근거로 사용하지 않는다.
- EndpointSlice address type과 nil condition 의미를 보존한다.
- Kubernetes Event 누락과 TTL 만료를 허용한다.
- resourceVersion을 resource/cluster 간 전역 sequence로 취급하지 않는다.
- watch EOF, reconnect와 410 relist를 운영 조건으로 처리한다.
- admission controller의 defaulting/mutation을 허용한다.
- LoadBalancer, Ingress, Gateway 또는 service mesh 존재를 가정하지 않는다.
- exec credential, proxy, custom CA와 SNI 설정을 `rest.Config`에서 보존한다.
- auth provider token refresh는 client-go kubeconfig plugin에 위임한다.

## 8. Network Portability

다음 구현 차이가 continuity 결과에 영향을 줄 수 있다.

- kube-proxy iptables, IPVS, nftables
- eBPF dataplane
- cloud VPC-native dataplane
- Ingress, Gateway와 L4 load balancer
- service mesh sidecar/ambient mode
- external DNS와 CDN

report는 probe origin, target, resolved address, protocol과 connection profile을 기록한다. 서로 다른 network path의 결과를 동일한 조건으로 합치지 않는다.

service mesh와 advanced Gateway는 별도 evidence가 확보되기 전까지 `Expected Compatible`이다.

## 9. 인증과 Provider 경계

- AWS/GCP/Azure SDK를 RolloutProof binary에 넣지 않는다.
- EKS/GKE/AKS 인증은 kubeconfig exec plugin과 client-go가 처리한다.
- long-lived credential을 report나 diagnostic bundle에 저장하지 않는다.
- credential 오류와 Kubernetes incompatibility를 다른 error category로 분류한다.
- CI cloud 인증은 short-lived identity를 사용해야 한다.

## 10. Production 안전 조건

- Production의 기본 mode는 read-only `observe` 또는 external `gate`다.
- mutation이 필요한 internal probe/fixture는 명시적 opt-in이 필요하다.
- namespace와 target workload를 명시하지 않은 mutation을 허용하지 않는다.
- cluster-scoped resource 설치를 기본 요구사항으로 만들지 않는다.
- request rate, URL과 probe origin을 report에 남긴다.

구체적인 E2E context guard와 cleanup 규칙은 테스트 계획을 따른다.

## 11. 호환성 공개 방식

distribution/version 조합마다 다음을 별도로 공개한다.

- 제품 호환성 상태: Supported/Expected Compatible/Degraded/Unsupported
- 테스트 evidence 상태: Continuous/Release/Community/Untested
- 실행한 commit과 RolloutProof version
- Kubernetes version과 architecture
- network/auth category
- 알려진 제한사항

compatibility report 형식과 PASS 기준은 테스트 문서에서 정의한다.

## 12. 비목표

- Kubernetes conformance suite를 재구현하지 않는다.
- 모든 CNI/service mesh 조합을 보장하지 않는다.
- cloud cluster를 생성하거나 관리하지 않는다.
- provider load balancer 장애의 root cause를 자동 확정하지 않는다.
- unsupported Kubernetes version을 지원한다고 주장하지 않는다.

## 참고 자료

- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [client-go](https://github.com/kubernetes/client-go)
