# RolloutProof 실제 효용성 평가

> 문서 상태: Revision 3 — 9/10 Target Assessment  
> 평가일: 2026-08-18  
> 관련 문서: [문서 안내](./README.md), [제품 스펙](./product-spec.md), [초기 기획서](./initial-product-plan.md), [오픈소스 벤치마킹](./benchmarking.md)

## 1. 평가 목적

이 문서는 `rollout-proof`의 기능적 완성도가 아니라 실제 개발 및 운영 환경에서의 사용 가능성을 평가한다.

평가 기준은 다음과 같다.

- 해결하려는 문제가 실제로 발생하는가?
- 어느 사용자가 어떤 시점에 반복 사용할 것인가?
- 기존 도구를 조합하는 방식보다 충분히 편리한가?
- 수집할 수 있는 증거만으로 신뢰할 수 있는 판정이 가능한가?
- CI/CD에 추가할 비용보다 얻는 가치가 큰가?
- 독립 오픈소스로 유지할 수 있는 명확한 경계가 있는가?

## 2. 요약 결론

`rollout-proof`의 실제 효용성은 **조건부로 높음**으로 평가한다.

가장 강한 초기 사용처는 다음과 같다.

> Local, Preview 또는 Staging에서 일반 Kubernetes Deployment의 graceful shutdown 회귀를 능동 검증하고, Production에서는 기존 rollout을 읽기 전용으로 관찰하는 단일 CLI.

특히 애플리케이션 runtime, HTTP server, readiness probe 또는 shutdown 설정 변경이 RollingUpdate 중 요청 손실을 발생시키는지 확인하는 용도는 기존 단위 테스트나 `kubectl rollout status`로 대체하기 어렵다.

반면 다음 약속은 현재 기술 범위에서 과도하다.

> 모든 Kubernetes 무중단 문제의 정확한 근본 원인을 자동 판정한다.

EndpointSlice API 변경 시점은 실제 kube-proxy, CNI 또는 Service Mesh data plane 반영 시점과 다를 수 있다. 또한 Kubernetes API만으로 정확한 SIGTERM 전달 시점과 실패 요청을 처리한 backend Pod를 항상 알 수 없다.

따라서 제품은 절대적인 인과관계보다 관측 결과, 시간적 상관관계, 가능한 설명과 신뢰도를 제공해야 한다.

실행 환경을 staging으로 제한하지 않는다. 제한해야 하는 것은 환경이 아니라 작업의 위험도다. 상태를 변경하는 `verify`는 통제된 환경을 우선하고, read-only `gate`와 `observe`는 Production까지 지원한다. 설치는 단일 binary로 유지하고, In-cluster probe는 필요할 때만 생성되는 ephemeral Pod로 분리한다.

| 모드 | 상태 변경 | Traffic | 주요 환경 | 평가 |
|---|---:|---:|---|---|
| `gate` | 없음 | 선택적 Synthetic | Staging, Production, 모든 CD 환경 | 새 revision 전체 관찰 |
| `verify` | 있음 | Synthetic | Local, Preview, Staging, 격리된 Canary | 통제된 능동 검증 |
| `observe` | 없음 | 선택적 Synthetic | Staging, Production | 진행 중 rollout 관찰 |
| `analyze` | 없음 | 기존 telemetry | 모든 환경, 사후 분석 | Rollout과 실제 장애의 상관분석 |

Core 강화안이 구현되는 시점의 예상 효용성은 **8.5/10**이다. 여기에 policy profile, multi-probe, CI artifact, GitHub Action, `explain`, report diff가 안정적으로 제공되면 목표 효용성은 **9.0/10**이다.

다만 전체 강화안을 한 번에 구현하면 범위가 커진다. 이를 MVP-A Core, MVP-A Adoption, In-cluster MVP-B, 비교·협업 기능으로 나누는 것이 이 평가의 전제다.

9점은 더 많은 Kubernetes 영역을 지원한다는 뜻이 아니다. 다음 세 가지가 충족되는 상태를 의미한다.

1. 첫 설치와 첫 실행이 매우 간단하다.
2. Release마다 반복 사용할 이유가 있다.
3. 결과를 비교하고 공유하며 다음 조치로 연결할 수 있다.

## 3. 문제의 실재성

Kubernetes에서는 Pod termination, EndpointSlice 상태 변경, kube-proxy/CNI 반영 및 애플리케이션 connection draining이 하나의 원자적 작업으로 처리되지 않는다. 이 과정의 시간 차이로 rollout 중 짧은 요청 실패가 발생할 수 있다.

공개 사례에서도 다음 문제가 확인된다.

- Pod 삭제 후 endpoint 제거가 3~10초 지연되며 transient connection failure가 발생한 사례
- Pod IP로 직접 접근할 때는 정상이지만 Service를 통하면 connection reset이 발생한 사례
- 종료된 Pod가 Service EndpointSlice에 남은 사례
- persistent connection과 Pod graceful termination 사이의 처리 문제

따라서 프로젝트가 해결하려는 문제는 가상이 아니라 실제 운영 문제다.

다만 모든 Kubernetes 사용자가 빈번하게 경험하는 문제는 아니다. 다음 조건에서 발생 가능성이 높다.

- 짧은 rollout이 자주 수행됨
- 요청량이 많아 짧은 failure window도 노출됨
- replica가 적음
- 애플리케이션의 graceful shutdown이 부실함
- long-lived connection이나 처리 시간이 긴 요청이 있음
- Ingress, Service Mesh, CNI 등 routing 계층이 복잡함

## 4. 사용처별 효용성

### 4.1 Local, Preview 및 Staging Rollout 회귀 테스트

**효용성: 9/10**

가장 현실적이고 가치가 높은 사용처다.

다음과 같은 변경 이후 무중단 특성이 퇴행했는지 확인할 수 있다.

- Spring Boot, Node.js, Go runtime 또는 framework 변경
- HTTP server 변경
- graceful shutdown 구현 변경
- readiness/startup probe 변경
- `preStop` 추가 또는 제거
- `terminationGracePeriodSeconds` 변경
- Deployment RollingUpdate strategy 변경

예상 결과:

```text
Previous version: PASS
Candidate version: FAIL

Regression:
12 connections were reset after the old Pod began terminating.
```

이 시나리오는 명확한 입력, 반복 가능한 실행, 명확한 PASS/FAIL을 제공하므로 CI와 release 검증에 적합하다.

### 4.2 플랫폼 표준 및 애플리케이션 템플릿 검증

**효용성: 8/10**

플랫폼 팀이 제공하는 공통 Deployment template, Helm chart 또는 애플리케이션 scaffold가 무중단 조건을 만족하는지 검증할 수 있다.

대표적인 검증 fixture:

- 정상 graceful shutdown
- SIGTERM 직후 listener 종료
- 실제 준비보다 빠른 readiness
- grace period 부족
- replica 1개와 위험한 `maxUnavailable`
- long-running request 종료

이 fixture들은 회귀 테스트, 문서 예제, 사용자 데모로도 활용할 수 있다.

### 4.3 CI/CD Quality Gate

**효용성: 8/10**

단일 binary와 안정적인 exit code를 제공하면 release pipeline에 쉽게 연결할 수 있다.

```yaml
- name: Verify zero-downtime rollout
  run: |
    rollout-proof verify deployment/api \
      --service api \
      --image api=${CANDIDATE_IMAGE} \
      --max-errors 0
```

다만 모든 PR마다 실제 클러스터와 workload를 실행하면 비용과 시간이 커질 수 있다. 초기 권장 실행 시점은 다음과 같다.

- Release candidate 생성 시
- Staging 배포 시
- Runtime/framework 변경 시
- Probe 또는 lifecycle 설정 변경 시
- 정기적인 배포 신뢰성 테스트

### 4.4 Production을 포함한 기존 CD 시스템의 관찰 도구

**효용성: 8/10**

`observe` 모드가 안정적으로 동작하면 Argo CD, Flux, Helm 및 사내 CD 시스템과 결합할 수 있다.

장점:

- 배포 방식을 변경하지 않음
- 새로운 CRD나 controller가 필요 없음
- 기존 Deployment를 그대로 관찰
- Deployment patch 권한 없이 Production에서 사용 가능
- In-cluster Service와 external URL 중 검증 경로를 선택 가능

한계:

- 외부 rollout 시작 시점을 안정적으로 감지해야 함
- CI 작업과 rollout timing을 맞춰야 함
- 실제 production traffic 대신 synthetic traffic을 사용함

Production에서는 판정 언어를 능동 검증과 구분한다.

```text
DEGRADATION OBSERVED

The external probe recorded 15 failures during the rollout.
```

이는 기존 Deployment를 변경하지 않으면서 Production rollout의 서비스 연속성을 기록할 수 있다는 점에서 staging 전용 도구보다 실제 활용 범위가 넓다.

### 4.5 운영 중 일반 장애 분석

**효용성: 5/10**

운영 중 발생한 502나 timeout이 항상 rollout 때문인 것은 아니다.

가능한 다른 원인:

- Ingress 또는 cloud load balancer
- Service Mesh
- DNS
- Node 또는 CNI
- Application dependency
- Database
- Connection pool
- Client-side timeout

따라서 `rollout-proof`는 rollout과 시간적으로 겹치는 문제를 분석하는 데 적합하며 범용 Kubernetes 장애 분석기로 확장하면 안 된다.

### 4.6 외부 사용자 경로 검증

**효용성: 경로에 따라 4~8/10**

ClusterIP를 대상으로 실행하면 다음 경로를 검증한다.

```text
In-cluster Probe → ClusterIP Service → Pod
```

하지만 실제 사용자는 다음 경로를 사용할 수 있다.

```text
Client
  → Cloud Load Balancer
  → Ingress/Gateway
  → Service Mesh
  → Service
  → Pod
```

ClusterIP 검증 성공은 전체 외부 경로의 무중단을 보장하지 않는다. 모든 결과에 검증 경로와 제외된 계층을 명시해야 한다.

```text
Verified path:
  in-cluster probe → ClusterIP Service → Pod

Not verified:
  external load balancer, ingress, service mesh
```

## 5. 기존 방식 대비 효용

현재 유사한 검증을 수행하려면 일반적으로 다음 도구를 수동으로 조합해야 한다.

```text
k6/Fortio/Vegeta
+ kubectl rollout
+ kubectl get pod --watch
+ kubectl get endpointslice --watch
+ kubectl events
+ 로그 timestamp 정렬
+ 수동 원인 분석
```

`rollout-proof`의 핵심 가치는 완전히 새로운 측정 기술보다는 이 과정을 하나의 재현 가능한 workflow로 통합하는 것이다.

| 기존 방식 | RolloutProof |
|---|---|
| 여러 도구를 수동 연결 | 단일 명령 |
| 요청과 Kubernetes event가 분리됨 | 통합 timeline |
| 사람이 timestamp를 비교 | 자동 상관분석 |
| 팀마다 다른 shell script | 공통 report schema |
| CI 판정 기준이 제각각 | 표준 PASS/FAIL/INCONCLUSIVE |
| 재현 절차가 문서에 의존 | Fixture와 명령으로 재현 |

이 통합은 독립 오픈소스로서 충분한 사용자 가치를 가질 수 있다.

### 5.1 효용성을 높이는 핵심 기능

| 우선순위 | 기능 | 효용 증가 | 구현 부담 | 단계 |
|---:|---|---:|---:|---|
| 1 | `gate --wait-for-revision` | 매우 높음 | 중 | MVP-A Core |
| 2 | External URL agentless probe | 높음 | 낮음 | MVP-A Core |
| 3 | 새 연결/Keep-Alive profile | 매우 높음 | 중 | MVP-A Core |
| 4 | 관측 범위와 confidence | 높음 | 중 | MVP-A Core |
| 5 | Production 안전 기본값 | 높음 | 낮음 | MVP-A Core |
| 6 | Service/port zero-config discovery | 매우 높음 | 중 | MVP-B |
| 7 | Internal/External 동시 probe | 매우 높음 | 중상 | MVP-B |
| 8 | Ephemeral probe 자동 정리 | 높음 | 중상 | MVP-B |
| 9 | Policy profile 및 multi-probe | 매우 높음 | 중 | MVP-A Adoption |
| 10 | Live timeline과 `explain` | 높음 | 낮음~중 | MVP-A Core |
| 11 | GitHub Action, Markdown, JUnit | 매우 높음 | 중 | MVP-A Adoption |
| 12 | `report diff` | 매우 높음 | 중 | 비교·협업 단계 |
| 13 | Redacted 진단 bundle | 높음 | 중 | 비교·협업 단계 |
| 14 | Prometheus/OTel 연동 | 중상 | 높음 | 선택적 확장 |

### 5.2 설치 효용

사용자가 체감하는 설치 비용은 구현 복잡도와 분리한다.

기본 설치:

```bash
brew install rollout-proof
```

기본 실행:

```bash
rollout-proof gate deployment/api \
  --url https://api.example.com/health \
  --wait-for-revision 5m
```

기본 기능에는 Helm, CRD, controller, database, Prometheus가 필요하지 않다. 이 조건을 지키지 못하면 초기 도입 편의성 점수를 낮춰야 한다.

### 5.3 Internal Probe의 실질적 비용

ClusterIP를 검사하려면 CLI가 클러스터 내부에서 실행되거나 임시 probe Pod가 필요하다. 임시 Pod를 생성하는 방식은 별도 설치는 아니지만 read-only도 아니다.

| 방식 | 추가 설치 | Kubernetes mutation | Production 기본값 |
|---|---:|---:|---:|
| External probe | 없음 | 없음 | 권장 |
| 기존 In-cluster runner | 없음 | 없음 | 권장 |
| Ephemeral probe Pod | 없음 | Pod 생성·삭제 | 명시적 허용 |
| 상시 Agent | 필요 | 있음 | 초기 미지원 |

따라서 Agentless external probe를 MVP-A로 먼저 검증하고, Internal probe는 사용자 요구와 운영 안전성을 확인한 후 MVP-B로 추가하는 것이 효용 대비 구현 부담이 가장 낮다.

## 6. 핵심 기술적 한계

### 6.1 EndpointSlice와 실제 Data Plane의 차이

가장 중요한 기술적 위험이다.

```text
EndpointSlice API 변경
        ↓
Watch event 전달
        ↓
kube-proxy/CNI 처리
        ↓
iptables/IPVS/eBPF rule 변경
        ↓
실제 신규 연결에 반영
```

MVP가 관찰하는 것은 주로 EndpointSlice API 상태와 요청 결과다. 중간 data plane 적용 시점을 직접 관찰하지 못한다.

따라서 다음 표현은 피한다.

> EndpointSlice 제거가 늦어 요청이 실패했다.

권장 표현:

> 요청 실패가 Pod termination 이후 시작되어 관찰된 EndpointSlice 변경 시점 전후까지 지속됐다. Endpoint 또는 data-plane 전파 지연과 일치하는 패턴이다.

제품 용어는 `Root Cause`보다 다음을 사용한다.

- Observation
- Correlation
- Finding
- Likely Explanation
- Confidence

### 6.2 정확한 SIGTERM 전달 시점

Pod deletion timestamp는 SIGTERM 전달 시점과 같지 않다. `preStop`이 존재하면 SIGTERM은 hook 실행 이후 전달된다.

Kubernetes API만으로 정확한 signal 전달 시점을 항상 알 수 없으므로 MVP는 다음처럼 표현한다.

```text
Pod deletion observed:       12:00:06.120
SIGTERM delivery:            unknown
Container termination seen:  12:00:09.700
```

정확한 signal 관찰은 선택적 instrumentation, sidecar 또는 eBPF 확장으로 검토한다.

### 6.3 Backend Pod 식별

Service 응답만으로 요청을 처리한 Pod를 항상 알 수 없다.

Backend attribution이 없으면 다음 수준의 상관관계만 제공할 수 있다.

```text
A request failed while Pod A was terminating.
```

다음과 같은 확정적 표현은 할 수 없다.

```text
Pod A processed and failed this request.
```

선택적으로 응답 헤더 규약을 지원할 수 있다.

```http
X-Rollout-Proof-Pod: api-5c79d6f9b4-7tjv2
```

그러나 이를 필수 요구사항으로 만들면 도입성이 떨어지므로 attribution은 선택 기능으로 둔다.

### 6.4 테스트 커버리지의 한계

테스트에서 오류가 없었다고 모든 traffic pattern에서 무중단임을 증명할 수 없다.

- RPS가 낮으면 짧은 failure window를 놓칠 수 있음
- HTTP/1.1 테스트가 HTTP/2 또는 gRPC 특성을 대표하지 않음
- Short request가 long-lived connection 문제를 발견하지 못함
- 특정 node 또는 zone에서만 발생하는 문제를 놓칠 수 있음
- Keep-alive 설정에 따라 새 connection 문제를 놓칠 수 있음

따라서 판정은 반드시 테스트 조건과 함께 제공한다.

```text
PASS

No failures were observed under these test conditions:
- 20 requests/second
- HTTP/1.1
- new connection per request
- in-cluster ClusterIP path
- 121 seconds
```

`PROVEN ZERO DOWNTIME`과 같은 절대적인 문구는 사용하지 않는다.

## 7. 권장 제품 약속

초기 기획의 제품 약속을 다음처럼 조정한다.

과도한 표현:

> 무중단 여부를 증명하고 정확한 원인을 설명한다.

권장 표현:

> Kubernetes Deployment의 RollingUpdate 중 서비스 연속성을 능동적으로 검증하거나 읽기 전용으로 관찰하고, 정의된 관측 조건에서 요청 실패와 lifecycle event의 상관관계를 제시한다.

결과는 세 단계로 구분한다.

```text
Observation
15 connection resets occurred during rollout.

Correlation
Failures began after the old Pod entered Terminating and stopped
after the endpoint was no longer observed.

Finding
The pattern is consistent with a termination/data-plane propagation gap.
Confidence: high
```

## 8. 효용성 점수

| 평가 항목 | 점수 | 판단 |
|---|---:|---|
| 문제의 심각도 | 8/10 | 발생 시 실제 사용자 오류로 연결 |
| 발생 빈도 | 6/10 | 모든 팀에서 빈번하지는 않음 |
| 기존 해결의 불편함 | 8/10 | 여러 도구와 수동 분석 필요 |
| 차별화 가능성 | 8.5/10 | Revision gate, connection profile, 경로 비교 |
| 초기 도입 편의성 | 9/10 | 단일 CLI, agentless 기본값 |
| 결과의 신뢰성 | 7/10 | 관측 범위와 confidence를 명시 |
| CI 활용성 | 9/10 | 새 revision 대기와 명확한 exit code |
| 운영 분석 활용성 | 8/10 | Production read-only gate 지원 |
| 확장 가능성 | 8/10 | gRPC, Gateway, Mesh, CNI 확장 가능 |
| 구현 가능성 | 7.5/10 | MVP-A/B 분리 시 관리 가능 |

**Core 예상 평가: 8.5/10**  
**Adoption 및 비교 기능 완료 목표: 9.0/10**

9점은 Prometheus, OTel, gRPC, Gateway, Service Mesh 또는 eBPF를 모두 구현해야 달성되는 점수가 아니다. 단일 binary와 agentless 기본값을 유지하면서 gate를 release workflow에 자연스럽게 넣고, report를 반복 비교할 수 있게 만드는 채택 전략에 대한 평가다.

### 8.1 9점 평가 조건

| 조건 | 목표 |
|---|---|
| 설치 | Homebrew, binary, container 또는 GitHub Action 중 하나로 5분 이내 |
| 첫 실행 | 설정 파일 없이 10분 이내 gate 완료 |
| 반복 사용 | Profile로 동일 기준 재사용 |
| 탐지력 | 새 연결/Keep-Alive 결함을 각각 재현 |
| 투명성 | `explain`이 판정 규칙과 evidence를 재현 |
| CI 적용 | JSON, Markdown, JUnit 및 exit code 제공 |
| 비교 | 이전/현재 report regression 비교 |
| Production | Kubernetes 쓰기 권한 없이 external gate 가능 |
| 보안 | Header, cookie, token 및 bundle redaction |
| 범위 통제 | 초기 기능에 상시 agent와 외부 telemetry 필수 의존성 없음 |

## 9. 검증해야 할 핵심 가설

### 9.1 가설 A: 결함을 안정적으로 재현하고 탐지할 수 있는가?

kind에서 정상 fixture와 잘못된 shutdown fixture를 각각 30회 rollout한다.

통과 기준:

- 결함 fixture 탐지율 95% 이상
- 정상 fixture false positive 0/30
- 실패 window가 반복 실행에서 관찰됨
- 실행별 timeline 편차를 설명할 수 있음

이 가설을 통과하지 못하면 프로젝트의 핵심 데모와 CI 가치가 약해진다.

### 9.2 가설 B: Kubernetes API event만으로 유용한 설명이 가능한가?

다음 데이터만으로 timeline을 생성한다.

- HTTP 요청 결과
- Deployment, ReplicaSet, Pod watch
- EndpointSlice watch
- Kubernetes Event

통과 기준:

- 사용자가 timeline만 보고 문제 구간을 이해할 수 있음
- 확인할 수 없는 정보를 명확하게 구분함
- 수동 `kubectl` 조사보다 원인 범위를 빠르게 좁힘
- Data plane을 직접 관찰한 것처럼 과장하지 않음

### 9.3 가설 C: 기존 도구 조합보다 편리한가?

플랫폼 엔지니어, SRE 또는 Kubernetes 경험자 8~12명을 대상으로 다음을 비교한다.

- k6와 여러 `kubectl watch`를 조합하는 기존 방식
- `rollout-proof` 단일 실행과 통합 report

확인할 질문:

- 최근 1년 동안 rollout 중 일시적 오류를 경험했는가?
- 현재 어떤 방식으로 검증하거나 분석하는가?
- Release 또는 staging pipeline에서 실행할 의향이 있는가?
- 어떤 evidence가 있어야 결과를 신뢰할 수 있는가?
- Application에 Pod identity header를 추가할 의향이 있는가?
- 허용 가능한 실행 시간과 traffic 부하는 어느 정도인가?
- Helm/CRD 없이 단일 binary로 시작하는 것이 채택 결정에 영향을 주는가?
- Internal probe를 위해 임시 Pod 생성 권한을 허용할 의향이 있는가?

### 9.4 가설 D: 실행 비용이 허용 가능한가?

초기 목표:

- 설치 5분 이내
- 첫 실행 10분 이내
- 추가 cluster component 없음
- 기본 RPS에서 CPU/memory 영향이 미미함
- 일반 rollout 시간 외 추가 대기 20초 이내
- 실행 실패 시 cluster 상태를 변경한 채 방치하지 않음

### 9.5 가설 E: Gate가 실제 CD workflow에 자연스럽게 들어가는가?

통과 기준:

- 배포 전에 실행해 새 revision을 안정적으로 감지함
- Argo CD, Flux, Helm 중 최소 두 방식에서 동작함
- rollout 시작을 놓치지 않고 baseline부터 settle까지 수집함
- CD pipeline이 report와 exit code를 artifact/gate로 사용할 수 있음
- 별도 상시 service 없이 일회성 process로 완료됨

### 9.6 가설 F: Connection profile과 경로 비교가 추가 가치를 주는가?

통과 기준:

- 새 연결과 Keep-Alive에서 서로 다른 종료 결함을 재현함
- Internal/External 결과 차이로 조사 계층을 실제로 좁힐 수 있음
- 단일 probe 결과보다 사용자의 진단 시간이 단축됨
- 결과가 root cause를 확정하는 것처럼 과장되지 않음

### 9.7 가설 G: Adoption 기능이 반복 사용을 만드는가?

통과 기준:

- 사용자가 동일 profile을 두 번 이상의 release에서 재사용함
- GitHub Action 또는 container 방식으로 별도 설치 없이 실행함
- Multi-probe가 health endpoint만으로 놓친 회귀를 한 건 이상 탐지함
- `explain`이 판정에 대한 사용자 질문을 줄임
- `report diff`가 이전 release 대비 regression을 명확히 보여줌
- Report artifact가 PR, release 또는 incident 기록에 첨부됨

## 10. Phase 0 평가 실험

### 10.1 실험 Fixture

최소 두 종류로 시작한다.

#### 정상 Fixture

- SIGTERM 수신 후 신규 요청 수락 중단
- 진행 중 요청 완료
- 충분한 grace period
- 실제 준비 후 readiness 성공

#### 결함 Fixture

- SIGTERM 또는 종료 시작 직후 listener 종료
- Endpoint/data-plane 전파 전 connection 거부 가능
- 동일한 Deployment/Service 조건 사용

### 10.2 반복 실행

각 fixture를 동일한 환경에서 최소 30회 실행한다.

기록 항목:

- 총 요청 수
- 오류 수와 유형
- 첫 오류 및 마지막 오류 시점
- Pod deletion 관찰 시점
- Pod Ready/Unready 전환 시점
- EndpointSlice 상태 변경 시점
- Rollout 완료 시점
- Watch reconnect 또는 event gap

### 10.3 사용자 평가

원시 `kubectl` 및 traffic log와 통합 timeline을 각각 사용자에게 제공한다.

측정 항목:

- 문제 구간을 찾는 데 걸린 시간
- 사용자가 선택한 가능한 원인
- 결과 신뢰도 평가
- 추가로 필요하다고 요청한 증거
- CI에 사용할 의향

### 10.4 단계별 효용 검증

MVP-A 종료 기준:

- 단일 binary 설치 후 10분 이내 첫 gate 실행
- 정상/결함 fixture 구분
- External probe와 connection profile 동작
- Production context에서 Kubernetes 쓰기 권한 없이 gate 완료

MVP-B 종료 기준:

- Ephemeral probe 생성과 정리가 반복적으로 성공
- Internal/External 동시 timeline 생성
- NetworkPolicy 또는 권한 실패가 명확하게 설명됨
- Cleanup 실패 시 orphan resource가 식별 가능함

9점 효용성 종료 기준:

- MVP-A Core와 Adoption 조건을 모두 충족
- 최소 3개 프로젝트 또는 서비스에서 반복 실행
- 최소 2종류 CD workflow에서 gate 적용
- Report diff가 실제 regression을 탐지
- 사용자 인터뷰에서 설치 복잡성이 도입 장애로 지목되지 않음
- 범용 observability 기능 없이도 지속 사용 의사가 확인됨

## 11. Go, Pivot, Stop 기준

### 11.1 Go

다음 조건을 만족하면 현재 방향으로 MVP 개발을 진행한다.

- 결함 fixture를 반복적으로 탐지함
- 정상 fixture에서 false positive가 거의 없음
- Timeline이 수동 조사보다 명확함
- 최소 3명 이상의 실무자가 사용 의사를 보임
- 추가 instrumentation 없이도 기본 가치가 있음
- 기본 검증 시간이 release pipeline에 수용 가능함
- `gate --wait-for-revision`이 실제 CD workflow에서 rollout을 놓치지 않음
- 단일 binary 설치 경험을 유지함

### 11.2 Pivot

다음 조건이면 제품 정의를 조정한다.

- 요청 오류는 탐지하지만 원인 상관분석이 약함
- ClusterIP 경로만으로 실무 사용 사례가 부족함
- 사용자가 lifecycle 분석보다 traffic scenario 작성 기능을 더 중요하게 평가함
- 정확한 backend attribution 없이는 finding의 가치가 낮음

가능한 전환 방향:

> Lifecycle analyzer보다 rollout-aware traffic test runner에 집중한다.

이 경우 핵심은 상관분석보다 rollout 전·중·후 traffic scenario와 CI 판정이 된다.

### 11.3 Stop

다음 조건이면 프로젝트 중단 또는 다른 후보로 전환을 검토한다.

- 일반적인 테스트 환경에서 실패를 안정적으로 재현하지 못함
- 정상과 결함 fixture를 신뢰성 있게 구분하지 못함
- 유용한 분석을 위해 sidecar 또는 eBPF가 항상 필수임
- 실무자들이 기존 k6, Flagger 또는 Argo Rollouts로 충분하다고 평가함
- 실행 비용이 CI/CD 도입 가치를 초과함

## 12. 최종 평가

독립 오픈소스로 만들 실질적인 효용은 있다. 다만 가치가 가장 높은 범위는 좁고 명확하다.

> 단일 binary로 release-time gate를 실행해 통제된 환경에서는 graceful shutdown 회귀를 능동 검증하고, Production에서는 기존 rollout을 읽기 전용으로 관찰하며, 연결 유형과 경로별 실패를 Kubernetes lifecycle timeline과 함께 보여준다.

프로젝트의 성공은 기능 수보다 다음 한 가지 실험에 달려 있다.

> 정상 앱은 PASS하고, 종료 결함이 있는 앱은 FAIL하며, 사용자가 통합 timeline만 보고 실패 구간과 가능한 원인을 이해할 수 있는가?

Phase 0와 MVP-A Core에서 탐지 가설을 먼저 검증하고, MVP-A Adoption에서 반복 사용과 팀 적용을 검증한다. 이후 Internal path가 실제로 필요할 때만 MVP-B로 확장한다. 9점 달성의 핵심은 지원 영역의 수가 아니라 단순한 설치, 재사용 가능한 policy, 투명한 판정, CI artifact 및 report regression 비교다.

Prometheus, OTel, gRPC 또는 eBPF는 9점 달성의 선행 조건이 아니다. 실제 사용자 요구가 확인되기 전에 추가하면 오히려 설치성과 범위 통제를 훼손해 종합 효용성을 낮출 수 있다.

## 13. 참고 자료

- [Kubernetes Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Explore Termination Behavior for Pods and Their Endpoints](https://kubernetes.io/docs/tutorials/services/pods-and-endpoint-termination-flow/)
- [Endpoint removal delayed when Pod is deleted](https://github.com/kubernetes/kubernetes/issues/47597)
- [Connection reset through Service](https://github.com/kubernetes/kubernetes/issues/112441)
- [Terminated Pod listed in Service endpoints](https://github.com/kubernetes/kubernetes/issues/109718)
- [kube-proxy and persistent connections](https://github.com/kubernetes/kubernetes/issues/38456)
