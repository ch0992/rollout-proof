# RolloutProof 오픈소스 벤치마킹

> 조사 기준일: 2026-08-18  
> 문서 목적: Kubernetes 관련 취업 포트폴리오용 오픈소스 주제를 검토하고, `rollout-proof`의 경쟁 프로젝트와 차별화 가능성을 정리한다.
> 현재 제품 방향: [문서 안내](./README.md), [초기 기획서](./initial-product-plan.md), [실제 효용성 평가](./utility-evaluation.md)

## 1. 조사 배경

Kubernetes 생태계에는 대시보드, YAML 린터, 보안 스캐너, 비용 분석기, Progressive Delivery 도구가 이미 다수 존재한다. 따라서 단순히 비슷한 기능을 하나 더 구현하기보다 다음 조건을 만족하는 프로젝트를 찾는 것을 목표로 했다.

- 실제 개발 및 운영 과정에서 반복적으로 사용할 수 있을 것
- Kubernetes API와 workload lifecycle에 대한 기술적 깊이를 보여줄 것
- 개인 또는 소규모 팀이 MVP를 완성할 수 있을 것
- 기존 오픈소스와 명확하게 구분되는 핵심 기능이 있을 것
- CLI와 CI/CD 양쪽에서 사용할 수 있을 것

여기서 "존재하지 않는 도구"는 절대적으로 증명하기 어렵다. 이 문서의 판단은 공개 GitHub 저장소, Kubernetes 공식 문서, CNCF 프로젝트 및 공개 프로젝트 문서를 검색한 결과를 기준으로 한다.

## 2. 최초 후보군 평가

| 순위 | 후보 | 개발 단계 활용 | 운영 단계 활용 | 도입 난이도 | 신규성 | 결론 |
|---|---|---:|---:|---:|---:|---|
| 1 | 무중단 Rollout 검증기 | 매우 높음 | 매우 높음 | 낮음 | 중상 | 최종 후보 |
| 2 | Admission Webhook 호환성 검증기 | 중상 | 높음 | 중상 | 높음 | 후속 후보 |
| 3 | HPA/KEDA What-if 시뮬레이터 | 중 | 높음 | 높음 | 중상 | 후속 후보 |
| 4 | CRD 실제 데이터 마이그레이션 검증기 | 낮음 | 특정 상황에서 높음 | 높음 | 중 | 보류 |
| 5 | Finalizer 교착 분석기 | 낮음 | 장애 발생 시 높음 | 중 | 매우 낮음 | 제외 |

### 2.1 Admission Webhook 호환성 검증기

여러 Mutating/Validating Admission Webhook이 함께 설치됐을 때 다음 문제를 자동 탐지하는 구상이다.

- 개별 및 전체 webhook 조합의 비멱등성
- webhook 호출 순서에 따른 결과 차이
- 한 webhook의 mutation이 다른 validation을 위반하는 문제
- timeout, TLS 오류 및 endpoint 장애 시 `failurePolicy` 동작
- webhook이 자기 자신의 Pod나 필수 add-on을 차단하는 의존성 순환
- Kubernetes minor version 업그레이드 전후 동작 차이

부분 경쟁 프로젝트로 Chainsaw, KUTTL, Kubebuilder `envtest`, Sieve가 있다. 그러나 이들은 범용 E2E 테스트 또는 controller 신뢰성 테스트 도구이고, 여러 admission webhook의 충돌과 집합적 멱등성을 자동 탐색하는 전용 도구는 확인하지 못했다.

신규성은 높지만 주 사용자가 플랫폼 엔지니어, Operator 개발자, 보안 플랫폼 팀으로 제한된다.

### 2.2 HPA/KEDA What-if 시뮬레이터

Prometheus 과거 metric을 재생해 현재와 후보 HPA/KEDA 설정의 동작을 비교하는 구상이다.

- replica 변화 비교
- scale-up 지연 및 scale-down 안정화 비교
- scaling event 횟수 비교
- 비용 및 SLO 영향 추정
- 후보 HPA YAML을 PR에서 검증

`hpademo`, SimKube, Predictive HPA 계열 프로젝트가 일부 영역을 담당한다. 차별화하려면 단순 HPA 공식 계산기가 아니라 `과거 Prometheus 데이터 재생 + 후보 YAML 비교 + 비용/SLO 리포트`까지 제공해야 한다.

문제의 경제적 가치는 크지만 workload 처리량 모델과 SLO 데이터가 필요해 도입 장벽과 결과 신뢰성 확보 난도가 높다.

### 2.3 CRD 실제 데이터 마이그레이션 검증기

단순 schema diff가 아니라 실제 Custom Resource와 conversion webhook을 임시 클러스터에서 검증하는 구상이다.

그러나 다음 기능이 이미 존재한다.

- `kro`의 CRD breaking/non-breaking schema 비교
- `cty`의 CRD schema validation 및 버전 비교
- Kubeconform의 Custom Resource schema 검증
- Kubernetes Storage Version Migrator
- Kubebuilder/controller-runtime의 conversion round-trip 테스트 패턴

차별화하려면 실제 객체 추출, 익명화, old/hub/new round-trip, semantic data loss, CEL/defaulting 변화, storage migration 및 rollback까지 다뤄야 한다. 구현 비용에 비해 독립적인 메시지가 약해 보류했다.

### 2.4 Finalizer 교착 분석기

`finalizer-doctor`가 거의 동일한 문제를 이미 해결한다.

- stuck `Terminating` 리소스 및 Namespace 진단
- block 중인 finalizer와 사라진 controller/APIService 식별
- orphan resource 정리
- dry-run 기본값
- 근거가 있을 때만 finalizer 제거
- Namespace `/finalize` subresource 처리

독립 프로젝트로 만들기보다는 기존 프로젝트에 dependency graph나 webhook 순환 탐지를 기여하는 편이 적합해 후보에서 제외했다.

## 3. RolloutProof 문제 정의

일반적인 Kubernetes 검증은 다음 명령으로 rollout 완료 여부를 확인한다.

```bash
kubectl rollout status deployment/api
```

하지만 이 명령은 Kubernetes가 Deployment rollout을 완료했는지만 알려준다. rollout 중 실제 사용자 요청이 실패했는지는 알려주지 않는다.

`rollout-proof`가 해결하려는 핵심 질문은 다음과 같다.

> Kubernetes Deployment의 rolling update 중 실제 사용자 요청이 손실되는가? 손실된다면 Pod 종료, readiness, EndpointSlice 및 애플리케이션 connection draining 중 어느 단계가 원인인가?

Kubernetes의 Pod 종료 과정에서는 여러 동작이 병렬로 진행된다.

1. Pod에 deletion timestamp가 설정된다.
2. kubelet이 `preStop` hook을 실행한다.
3. 애플리케이션 프로세스에 SIGTERM이 전달된다.
4. Control plane이 EndpointSlice에서 해당 Pod의 상태를 변경한다.
5. kube-proxy, CNI 또는 Service Mesh에 endpoint 변경이 전파된다.
6. 애플리케이션이 기존 connection과 요청을 drain한다.
7. grace period가 끝나면 남은 프로세스가 강제 종료된다.

설정상 Deployment가 Available 상태를 유지하더라도 이 과정 사이의 시간 차이로 5xx, timeout 또는 connection reset이 발생할 수 있다.

## 4. 직접 및 부분 경쟁 프로젝트

### 4.1 Kubeasy

[Kubeasy](https://kubeasy.dev/)는 Kubernetes 실습 challenge와 결과 검증을 위한 오픈소스 플랫폼이다. `triggered` validation에서 다음 동작을 제공한다.

- Deployment image 변경으로 rollout 실행
- HTTP load 생성
- rollout 후 Deployment Available 상태 확인
- 실패 Kubernetes Event 검사
- Pod 삭제 후 복구 검사
- HPA scale-up 검사

가장 가까운 부분 경쟁 기능은 [Triggered Validation](https://kubeasy.dev/docs/developer/validation-triggered)이다.

다만 공개 문서상 하나의 validation은 한 번에 하나의 trigger를 사용한다.

```yaml
trigger:
  type: rollout
```

또는 다음과 같이 load를 발생시킨다.

```yaml
trigger:
  type: load
```

따라서 rollout과 지속적인 HTTP traffic을 동시에 실행하고 요청 실패를 Pod lifecycle과 연관시키는 기능은 확인되지 않았다. Kubeasy의 주목적 역시 운영 CI 제품보다는 Kubernetes 교육 및 challenge 검증이다.

**기능 중복 추정: 30~40%**

### 4.2 Flagger

[Flagger](https://flagger.app/)는 CNCF/Flux 계열 Progressive Delivery Operator다.

주요 기능은 다음과 같다.

- Canary, A/B 및 Blue/Green 배포
- 점진적 traffic shifting
- HTTP/gRPC 성공률 및 latency 분석
- Prometheus 등 metric provider 연동
- acceptance/load test webhook
- 자동 promotion 및 rollback

실제 운영 목적은 매우 가깝지만 Flagger는 배포 전략 자체를 변경하고 제어한다. 반면 `rollout-proof`는 기존 일반 Deployment의 RollingUpdate를 변경하지 않고 검증하고 원인을 설명하는 도구를 지향한다.

**기능 중복 추정: 약 50%**

### 4.3 Argo Rollouts

[Argo Rollouts](https://github.com/argoproj/argo-rollouts)는 Rollout CRD를 통해 Canary와 Blue/Green 배포, metric 분석, experiment 및 자동 rollback을 제공한다.

다음 영역은 겹치지만 제품 역할이 다르다.

- 안전한 배포 판단
- 배포 중 metric 검사
- 실패 시 abort/rollback

Argo Rollouts는 일반 Deployment 대신 Rollout CRD 채택을 요구한다. 또한 기본 기능만으로 SIGTERM, EndpointSlice 변화, 요청별 오류를 하나의 lifecycle timeline으로 연결하지 않는다.

**기능 중복 추정: 약 40%**

### 4.4 k8s-traffic-bench

[k8s-traffic-bench](https://github.com/edgedelta/k8s-traffic-bench)는 Kubernetes 내부에서 k6 traffic을 발생시키고 다음을 측정한다.

- HTTP response time과 error rate
- Pod CPU 및 memory
- 단계별 load pattern
- HTML report

그러나 rollout을 직접 실행하거나 Pod lifecycle과 EndpointSlice 변화를 관찰하지 않는다. 성능 및 capacity testing 도구에 가깝다.

**기능 중복 추정: 약 25%**

### 4.5 KubeQA

[KubeQA](https://github.com/nomadx-ae/kubeqa)는 cluster health, chaos, compliance 및 deployment gate를 제공한다고 설명한다. 확인된 deployment gate의 중심 기능은 manifest와 image의 정적 검사다.

- readiness/liveness probe 존재 여부
- resource limit과 security context
- image vulnerability
- manifest diff
- policy/compliance

실제 rollout 중 traffic failure와 Pod lifecycle을 연결하는 기능은 확인되지 않았다. 조사 시점 기준 저장소 규모도 1 commit, 0 star로 초기 단계였다.

**기능 중복 추정: 약 10%**

### 4.6 Kubernetes Test Controller

[k8s-test-controller](https://srossross.github.io/k8s-test-controller/)는 rollout 이후 Kubernetes Job 형태의 E2E 테스트를 실행한다. 사용자가 테스트 컨테이너와 assertion을 직접 작성해야 하며, rollout lifecycle 자동 추적 및 HTTP 실패 상관분석은 제공하지 않는다.

**기능 중복 추정: 약 15%**

### 4.7 범용 조합 도구

| 도구 | 담당 영역 | RolloutProof 관점의 공백 |
|---|---|---|
| k6, Fortio, Vegeta | HTTP 부하 생성 | Kubernetes rollout과 Pod lifecycle 인식 없음 |
| `kubectl rollout status` | rollout 완료 확인 | 사용자 요청 실패 측정 없음 |
| Argo Rollouts | Progressive Delivery | 일반 Deployment lifecycle 진단이 아님 |
| Flagger | metric 기반 Canary | SIGTERM/EndpointSlice timeline 없음 |
| LitmusChaos, Chaos Mesh | Pod/network 장애 주입 | rollout 특화 원인 분석 없음 |
| Chainsaw, KUTTL | Kubernetes E2E 시나리오 | 테스트와 상관분석을 직접 작성해야 함 |
| k8s-traffic-bench | traffic 및 resource 측정 | rollout 관찰 없음 |
| Kubeasy | rollout/load trigger 및 상태 검증 | 동시 traffic과 lifecycle 분석 없음 |

## 5. 기능 비교표

| 기능 | Kubeasy | Flagger | Argo Rollouts | k8s-traffic-bench | RolloutProof 목표 |
|---|---:|---:|---:|---:|---:|
| 일반 Deployment 지원 | O | 부분 | X | O | O |
| rollout 직접 실행 | O | O | O | X | O |
| rollout 중 지속적 HTTP 요청 | 확인 안 됨 | O | 외부 분석 필요 | 독립 실행 가능 | O |
| 요청별 5xx/timeout/reset 기록 | X | 집계 metric | 집계 metric | 부분 | O |
| Pod lifecycle 추적 | 부분 | 부분 | 부분 | 부분 | O |
| SIGTERM 시점 추적 | X | X | X | X | O |
| EndpointSlice 변화 추적 | X | X | X | X | O |
| 요청 실패와 lifecycle event 상관분석 | X | X | X | X | O |
| 무중단 pass/fail | 간접 | O | 구성 필요 | X | O |
| 원인 및 수정 권고 | X | X | X | X | O |

## 6. 차별화 원칙

다음 수준에 머무르면 기존 도구 대비 신규성이 부족하다.

- rollout 중 단순히 `curl`을 반복 실행
- 전체 HTTP error rate만 출력
- `kubectl rollout status`를 감싸는 wrapper
- readiness probe나 `maxUnavailable` 존재 여부만 정적 검사
- k6 실행 결과를 그대로 보여주는 도구

독립 프로젝트로서 의미를 가지려면 다음 세 가지가 핵심이어야 한다.

### 6.1 Lifecycle timeline

다음 사건을 단일 시간축에 기록한다.

```text
12:00:00.000  rollout started
12:00:02.413  new pod created
12:00:05.210  new pod became Ready
12:00:05.214  new endpoint added
12:00:06.120  old pod deletion started
12:00:06.121  old application stopped accepting connections
12:00:09.874  old endpoint removed
12:00:09.900  old pod terminated
```

### 6.2 요청 실패와 Kubernetes event 상관분석

각 요청에 timestamp, 결과, latency 및 가능하면 backend Pod 식별자를 기록한다. 이를 Pod condition, deletion timestamp, EndpointSlice 변화와 결합한다.

```text
Failure window: 3.753s
Failed requests: 17

Likely cause:
The old application stopped accepting connections 3.7s before its
endpoint disappeared from the observed service-routing path.
```

### 6.3 실행 가능한 수정 권고

관찰된 증거를 바탕으로 다음과 같은 권고를 제공한다.

- readiness가 실제 서비스 준비보다 일찍 성공함
- 애플리케이션이 SIGTERM 직후 listener를 닫음
- `preStop` delay가 endpoint propagation보다 짧음
- `terminationGracePeriodSeconds`가 drain 시간보다 짧음
- replica 수와 `maxUnavailable` 조합이 가용성 목표를 충족하지 못함

초기 버전에서는 자동 YAML 수정 대신 근거가 포함된 권고만 제공한다.

## 7. 제품 포지셔닝

피해야 할 설명:

> Kubernetes에서 무중단 배포를 테스트하는 최초의 도구

기존 도구도 무중단 배포나 rollout 성공률을 검사하므로 이 표현은 정확하지 않다.

권장 설명:

> Kubernetes Deployment의 rolling update 중 발생하는 요청 손실을 Pod 종료, readiness, EndpointSlice 변화와 연계해 재현하고 원인을 설명하는 lifecycle verifier.

짧은 영문 설명:

> Evidence-driven zero-downtime verifier for Kubernetes Deployments.

또는:

> Correlate request failures with Pod and EndpointSlice lifecycle events during Kubernetes rolling updates.

## 8. 권장 MVP 범위

### 8.1 포함 범위

- Kubernetes `apps/v1` Deployment
- RollingUpdate strategy
- ClusterIP Service
- HTTP/1.1
- 단일 target URL 또는 Service
- kind 또는 staging cluster
- 기존 Deployment 관찰 모드
- image 변경을 통한 test rollout 모드
- 지속적인 HTTP request 발생
- 2xx/non-2xx, timeout, connection reset, latency 기록
- Deployment, ReplicaSet, Pod, Event, EndpointSlice watch
- terminal summary와 JSON 결과
- CI용 exit code

### 8.2 제외 범위

첫 MVP에는 다음을 넣지 않는다.

- Canary/Blue-Green 배포 제어
- 자동 rollback
- Service Mesh traffic shifting
- gRPC, WebSocket 및 long-lived streaming
- 멀티클러스터
- Prometheus 의존성
- cloud load balancer별 전파 분석
- AI 기반 원인 분석
- 자동 manifest 수정

### 8.3 권장 CLI 예시

관찰 모드:

```bash
rollout-proof inspect deployment/api \
  --service api \
  --port 8080
```

검증 모드:

```bash
rollout-proof verify deployment/api \
  --service api \
  --image api=myorg/api:v2 \
  --rps 20 \
  --duration 2m
```

예상 결과:

```text
Rollout verdict: FAILED

Requests
  total:               2,418
  non-2xx:                 9
  timeouts:                4
  connection resets:       2

Observed failure window
  started: 12:00:06.121
  ended:   12:00:09.874
  length:  3.753s

Likely cause
  The old pod stopped accepting connections before the service-routing
  path finished removing its endpoint.

Evidence
  - old pod deletion started at 12:00:06.120
  - first request failure at 12:00:06.121
  - endpoint removal observed at 12:00:09.874
```

## 9. 주요 기술 및 검증 위험

### 9.1 SIGTERM 관찰

Kubernetes API만으로 컨테이너 내부 프로세스가 SIGTERM을 받은 정확한 시점을 직접 확인하기 어렵다. 다음 방식을 검토해야 한다.

- 애플리케이션 로그에 signal event 기록
- 선택적 sidecar 또는 test agent
- eBPF 기반 signal 관찰
- Pod deletion/preStop event를 근사치로 사용하고 정확도 수준 표시

MVP에서는 확인 가능한 API event와 애플리케이션 응답 변화를 중심으로 하고, SIGTERM 시점은 optional instrumentation으로 두는 것이 안전하다.

### 9.2 실제 backend Pod 식별

HTTP 응답이 어떤 Pod에서 왔는지 알려면 애플리케이션의 협조가 필요할 수 있다.

- 응답 header에 Pod name 삽입
- downward API로 Pod name 전달
- optional echo sidecar/proxy
- Service Mesh 또는 access log 활용

MVP에서는 backend 식별 없이도 전체 실패 window를 계산하고, backend attribution은 선택 기능으로 둘 수 있다.

### 9.3 네트워크 구현 차이

kube-proxy iptables/IPVS, eBPF CNI, Ingress 및 Service Mesh에 따라 endpoint 전파 시간이 다르다. 따라서 결과에는 환경 정보를 함께 기록해야 한다.

- Kubernetes version
- CNI 및 kube-proxy mode
- Service/Ingress 경로
- 테스트 요청 발생 위치
- node topology

### 9.4 안전성

운영 클러스터에서 image 변경이나 rollout restart는 상태 변경 작업이다. 기본값은 read-only inspect 또는 dry-run이어야 하며, 실제 rollout은 명시적 옵션으로만 실행해야 한다.

## 10. 최종 판단

재검색 결과 다음 결론을 내렸다.

- 무중단 rollout 자체를 테스트하는 도구는 이미 존재한다.
- rollout 중 HTTP 성공률을 측정하는 기능도 Flagger와 기타 도구에서 제공한다.
- 일반 Deployment의 RollingUpdate를 대상으로 요청 실패를 Pod 종료 및 EndpointSlice lifecycle과 자동 상관분석하는 전용 오픈소스는 확인하지 못했다.
- 따라서 `rollout-proof`는 "또 하나의 배포 도구"가 아니라 "기존 배포의 무중단 특성을 증거로 검증하는 lifecycle 진단기"여야 한다.

프로젝트 진행 조건은 다음과 같다.

1. 지속적인 traffic과 rollout을 동시에 관찰할 것
2. Kubernetes resource watch를 이용해 lifecycle timeline을 생성할 것
3. 단순 error count가 아니라 실패 window와 원인 근거를 제공할 것
4. 일반 Deployment에서 추가 controller 없이 동작할 것
5. CLI와 CI 양쪽에서 사용할 수 있을 것

이 조건을 충족하면 기존 프로젝트와 충분히 구분되며, Kubernetes API, networking, workload lifecycle, observability 및 신뢰성 테스트 역량을 보여주는 취업 포트폴리오로도 가치가 있다.

## 11. 참고 자료

### Kubernetes 공식 자료

- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Explore Termination Behavior for Pods and Their Endpoints](https://kubernetes.io/docs/tutorials/services/pods-and-endpoint-termination-flow/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Admission Webhook Good Practices](https://kubernetes.io/docs/concepts/cluster-administration/admission-webhooks-good-practices/)
- [Storage Version Migration](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/storage-version-migration/)

### 경쟁 및 인접 프로젝트

- [Kubeasy](https://kubeasy.dev/)
- [Kubeasy Triggered Validation](https://kubeasy.dev/docs/developer/validation-triggered)
- [Flagger](https://flagger.app/)
- [Argo Rollouts](https://github.com/argoproj/argo-rollouts)
- [k8s-traffic-bench](https://github.com/edgedelta/k8s-traffic-bench)
- [KubeQA](https://github.com/nomadx-ae/kubeqa)
- [Kubernetes Test Controller](https://srossross.github.io/k8s-test-controller/)
- [Sieve](https://github.com/sieve-project/sieve)
- [SimKube](https://simkube.dev/)
- [finalizer-doctor](https://github.com/alexremn/finalizer-doctor)
- [kro CRD compatibility package](https://pkg.go.dev/github.com/kubernetes-sigs/kro/pkg/graph/crd/compat)

### 기반 테스트 도구

- [Grafana k6](https://grafana.com/oss/k6/)
- [Chainsaw](https://github.com/kyverno/chainsaw)
- [KUTTL](https://github.com/kudobuilder/kuttl)
- [LitmusChaos](https://github.com/litmuschaos/litmus)
- [Chaos Mesh](https://github.com/chaos-mesh/chaos-mesh)
