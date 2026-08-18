# RolloutProof 제품 스펙

> 스펙 버전: 0.1-draft  
> 작성일: 2026-08-18  
> 목표: 효용성 평가 9/10 달성을 위한 제품 동작 계약  
> 구현 방법: [엔지니어링 구현 스펙](./implementation-spec.md)  
> 관련 문서: [문서 안내](./README.md), [초기 기획서](./initial-product-plan.md), [효용성 평가](./utility-evaluation.md)

## 1. 스펙 목적

이 문서는 `rollout-proof`의 제품 기획을 구현 가능한 요구사항으로 변환한다. CLI 동작, 상태 전이, 데이터 수집, 판정, 출력, 안전성 및 배포 계약을 정의한다.

요구사항 수준은 다음 용어를 사용한다.

- **MUST**: 해당 milestone 완료에 필수
- **SHOULD**: 특별한 사유가 없으면 구현
- **MAY**: 선택 구현

## 2. 제품 범위

### 2.1 핵심 제품 정의

`rollout-proof`는 Kubernetes Deployment의 새 revision을 기다리면서 HTTP 서비스 연속성을 검증하고, 요청 실패를 Deployment, ReplicaSet, Pod 및 EndpointSlice lifecycle event와 연결해 설명하는 단일 CLI다.

### 2.2 지원 대상

- Kubernetes `apps/v1` Deployment
- RollingUpdate strategy
- HTTP/1.1
- External HTTP/HTTPS endpoint
- Kubernetes API에서 관찰 가능한 Deployment, ReplicaSet, Pod, Event, Service, EndpointSlice
- Local, Preview, Staging 및 Production cluster

### 2.3 초기 비지원 대상

- StatefulSet, DaemonSet, Job
- Canary 및 Blue/Green 배포 제어
- 자동 rollback
- 상시 controller 또는 CRD
- 범용 load testing
- 범용 Kubernetes root cause analysis
- gRPC, WebSocket, SSE, HTTP/2 전용 검증
- Prometheus, OTel 또는 Service Mesh 필수 의존성
- eBPF 기반 data-plane 관찰

## 3. Milestone

| 버전 | 범위 | 핵심 결과 |
|---|---|---|
| `v0.1` | MVP-A Core | Agentless gate, HTTP profile, lifecycle timeline, explain |
| `v0.2` | MVP-A Adoption | Policy profile, multi-probe, CI output, Action, container |
| `v0.3` | MVP-B | Optional ephemeral internal probe, 경로 비교 |
| `v0.4` | 비교와 협업 | Report diff, 진단 bundle, framework guide |

9점 효용성 목표는 `v0.1`과 `v0.2`가 안정화되고 `v0.4`의 report diff가 제공되는 시점으로 정의한다. `v0.3`은 Internal path 수요가 확인될 때 병렬 또는 후속으로 진행할 수 있다.

## 4. CLI 명령 체계

```text
rollout-proof
├─ gate
├─ verify
├─ observe
├─ inspect
├─ explain
├─ diff
├─ bundle
├─ cleanup
└─ version
```

### 4.1 공통 Resource 표기

Deployment는 다음 형식을 지원해야 한다.

```text
deployment/api
deploy/api
api
```

Namespace 해석 우선순위:

1. `--namespace`
2. kubeconfig context namespace
3. `default`

### 4.2 `gate`

새 Deployment revision을 기다려 전체 rollout을 관찰하는 기본 명령이다.

```bash
rollout-proof gate deployment/api \
  --url https://api.example.com/health \
  --wait-for-revision 5m
```

필수 동작:

- 현재 Deployment generation과 revision 기록
- Probe baseline 시작
- Kubernetes watch 시작
- 새로운 revision 대기
- Rollout 및 settle window 관찰
- 판정과 report 생성

요구사항:

- `CLI-GATE-001` MUST: 새 revision 전에 baseline과 watcher가 준비되어야 한다.
- `CLI-GATE-002` MUST: `--wait-for-revision` timeout을 지원해야 한다.
- `CLI-GATE-003` MUST: timeout 동안 revision이 없으면 `NO_ROLLOUT_OBSERVED`를 반환해야 한다.
- `CLI-GATE-004` MUST: Deployment를 변경하지 않아야 한다.
- `CLI-GATE-005` SHOULD: Argo CD, Flux, Helm 및 직접 `kubectl apply` rollout을 구분 없이 감지해야 한다.

### 4.3 `verify`

도구가 container image를 patch해 능동 rollout을 수행한다.

```bash
rollout-proof verify deployment/api \
  --image api=ghcr.io/example/api:v2 \
  --url https://api.staging.example.com/health
```

요구사항:

- `CLI-VERIFY-001` MUST: `--image container=image`를 요구해야 한다.
- `CLI-VERIFY-002` MUST: 실행 전에 context, namespace, Deployment, container 및 image 변경 내용을 출력해야 한다.
- `CLI-VERIFY-003` MUST: Deployment patch 권한을 사전 검사해야 한다.
- `CLI-VERIFY-004` MUST NOT: 자동 rollback을 수행하지 않아야 한다.
- `CLI-VERIFY-005` MUST: baseline 불안정 시 기본적으로 patch를 수행하지 않아야 한다.
- `CLI-VERIFY-006` SHOULD: `--allow-unstable-baseline`을 명시적으로 제공할 수 있다.

### 4.4 `observe`

현재 진행 중이거나 곧 시작되는 rollout을 read-only로 관찰한다.

```bash
rollout-proof observe deployment/api \
  --url https://api.example.com/health \
  --timeout 5m
```

요구사항:

- `CLI-OBS-001` MUST: Deployment patch 권한 없이 동작해야 한다.
- `CLI-OBS-002` MUST: 관찰 시작 시 rollout이 이미 진행 중이면 coverage를 `partial`로 표시해야 한다.
- `CLI-OBS-003` MUST: Partial observation을 완전한 검증 결과처럼 표현하지 않아야 한다.

### 4.5 `inspect`

실제 rollout 없이 실행 가능성과 정적 위험을 확인한다.

```bash
rollout-proof inspect deployment/api
```

확인 항목:

- Resource 발견
- RollingUpdate strategy
- Replica 수와 `maxUnavailable`/`maxSurge`
- Probe URL 설정
- 필요한 RBAC
- Production safety mode
- Service 및 EndpointSlice 후보

`inspect` 결과는 무중단 보장이 아니라 preflight 정보다.

### 4.6 `explain`

기존 report의 판정 규칙과 evidence를 다시 출력한다.

```bash
rollout-proof explain report.json
```

- `CLI-EXPLAIN-001` MUST: 원래 실행과 동일한 finding 및 confidence를 재현해야 한다.
- `CLI-EXPLAIN-002` MUST: 판정에 사용된 rule ID를 출력해야 한다.
- `CLI-EXPLAIN-003` MUST: 관찰하지 못한 영역을 출력해야 한다.
- `CLI-EXPLAIN-004` MUST NOT: 네트워크나 cluster에 접근하지 않아야 한다.

### 4.7 `diff`

두 versioned report를 비교한다.

```bash
rollout-proof diff previous.json current.json
```

비교 항목:

- Request failure 및 오류 유형
- Connection reset
- p50/p95/p99 latency
- Rollout duration
- Pod ready time
- Endpoint transition 관찰 시간
- Replica availability gap
- Test condition 차이

- `CLI-DIFF-001` MUST: Server와 database 없이 동작해야 한다.
- `CLI-DIFF-002` MUST: 테스트 조건이 달라 직접 비교할 수 없으면 경고해야 한다.
- `CLI-DIFF-003` MUST: Regression, Improvement, No Material Change를 구분해야 한다.

### 4.8 `bundle`

공유 가능한 redacted 진단 bundle을 생성한다.

```bash
rollout-proof bundle report.json --output rollout-api-184.tar.gz
```

포함 후보:

- `summary.md`
- `report.json`
- `timeline.jsonl`
- Deployment/ReplicaSet/Pod/Service/EndpointSlice snapshot
- Kubernetes Event
- Environment metadata
- Redaction report

### 4.9 `cleanup`

MVP-B ephemeral probe 정리에 사용한다.

```bash
rollout-proof cleanup --session rp-20260818-abc123
```

다른 session이나 사용자가 생성한 resource는 삭제하지 않아야 한다.

## 5. 설정 모델

### 5.1 설정 우선순위

```text
CLI option
  > .rollout-proof.yaml
  > Deployment annotation
  > auto-discovery
  > built-in safe default
```

- `CFG-001` MUST: 최종 적용 설정을 `--show-effective-config`로 출력해야 한다.
- `CFG-002` MUST: 각 설정 값의 source를 표시할 수 있어야 한다.
- `CFG-003` MUST: 설정 파일 없이 기본 실행이 가능해야 한다.
- `CFG-004` MUST: 알 수 없는 설정 key를 무시하지 말고 오류로 처리해야 한다.
- `CFG-005` SHOULD: 환경변수 치환을 `${NAME}` 형식으로 지원해야 한다.

### 5.2 설정 파일

기본 파일명은 `.rollout-proof.yaml`이다.

```yaml
apiVersion: rollout-proof.io/v1alpha1
kind: RolloutProofConfig

target:
  namespace: payments
  deployment: api

probes:
  - name: health
    url: https://api.example.com/health
    method: GET
    expectedStatuses: [200, 204]

  - name: product-read
    url: https://api.example.com/products/known-item
    method: GET
    headers:
      Authorization: ${PROBE_TOKEN}

traffic:
  requestsPerSecond: 5
  connectionModes:
    - new
    - keep-alive
  requestTimeout: 2s

observation:
  baselineDuration: 15s
  waitForRevision: 5m
  rolloutTimeout: 5m
  settleDuration: 20s

policy:
  maxErrors: 0
  maxConnectionResets: 0
  minimumRequests: 500
  maxRolloutDuration: 3m

output:
  formats: [terminal, json]
  directory: ./rollout-proof-results
```

### 5.3 Deployment Annotation

선택적으로 다음 annotation을 지원한다.

```yaml
metadata:
  annotations:
    rollout-proof.io/probe-url: https://api.example.com/health
    rollout-proof.io/profile: production-http
    rollout-proof.io/backend-header: X-Pod-Name
```

Annotation은 도구 사용의 필수 조건이 아니다.

## 6. Rollout 상태 머신

```text
INITIALIZING
  → PREFLIGHT
  → BASELINE
  → WAITING_FOR_REVISION
  → ROLLOUT_OBSERVING
  → SETTLING
  → ANALYZING
  → COMPLETED
```

Terminal state:

```text
COMPLETED
NO_ROLLOUT_OBSERVED
BASELINE_UNSTABLE
ROLLOUT_FAILED
INCONCLUSIVE
EXECUTION_ERROR
CANCELLED
```

요구사항:

- `STATE-001` MUST: 모든 state 전이에 local observation timestamp를 기록해야 한다.
- `STATE-002` MUST: 취소 시 현재까지의 partial report를 생성해야 한다.
- `STATE-003` MUST: Watch gap이 판정 신뢰성을 훼손하면 `INCONCLUSIVE`로 종료해야 한다.
- `STATE-004` MUST: Rollout 완료 후 settle window를 관찰해야 한다.
- `STATE-005` SHOULD: 각 state duration을 report에 포함해야 한다.

## 7. Resource Discovery

### 7.1 Deployment 관계

- Deployment UID와 selector 확인
- OwnerReference를 이용해 ReplicaSet 연결
- ReplicaSet OwnerReference를 이용해 Pod 연결
- Revision annotation 수집

Selector만으로 owner 관계를 확정하지 않아야 한다.

### 7.2 Service와 EndpointSlice

MVP-A에서는 URL probe가 기본이며 Service 자동 선택은 필수가 아니다. MVP-B에서는 다음 규칙을 사용한다.

1. Deployment Pod selector와 일치하는 Service 탐색
2. Service label `kubernetes.io/service-name`으로 EndpointSlice 탐색
3. 후보가 하나면 자동 선택
4. 후보가 여러 개면 사용자에게 명시적 선택 요구

- `DISC-001` MUST: 모호한 Service를 임의로 선택하지 않아야 한다.
- `DISC-002` MUST: Resource UID를 report에 저장해야 한다.
- `DISC-003` MUST: Discovery 결과와 선택 근거를 출력해야 한다.

## 8. HTTP Probe 스펙

### 8.1 지원 Method

- MVP-A 기본: `GET`, `HEAD`
- Production 기본: `GET`, `HEAD`만 허용
- Side-effect 가능 method는 초기 미지원

### 8.2 Connection Profile

#### `new`

각 요청 또는 설정된 작은 request batch마다 새 connection을 만든다.

탐지 대상:

- Connection refused/reset
- TLS handshake failure
- 신규 connection routing 문제

#### `keep-alive`

Connection pool을 재사용한다.

탐지 대상:

- 기존 connection reset
- Connection draining 부족
- Idle connection 종료 문제

- `PROBE-CONN-001` MUST: Profile별 결과를 분리해 report해야 한다.
- `PROBE-CONN-002` MUST: 두 profile의 HTTP client/transport를 공유하지 않아야 한다.
- `PROBE-CONN-003` SHOULD: 실제 connection reuse 여부를 metric으로 표시해야 한다.

### 8.3 Multi-probe

- 각 probe는 고유 name을 가져야 한다.
- Probe별 URL, method, expected status, header 및 timeout을 지정할 수 있어야 한다.
- 전체 RPS와 probe별 RPS 합계가 안전 상한을 넘지 않아야 한다.
- 결과는 probe와 connection profile별로 분리해야 한다.

### 8.4 오류 분류

최소 오류 분류:

```text
dns_error
connect_timeout
connection_refused
connection_reset
tls_error
request_timeout
unexpected_status
body_validation_error
cancelled
unknown_transport_error
```

문자열 오류 메시지만으로 판정하지 말고 가능한 범위에서 typed error를 사용한다.

### 8.5 요청 식별 및 Backend Attribution

- 모든 요청에 session 및 request ID를 부여한다.
- 선택적으로 header를 request에 추가한다.
- 사용자가 지정한 response header로 backend Pod identity를 수집할 수 있다.
- Backend attribution이 없으면 특정 Pod가 요청을 실패시켰다고 단정하지 않는다.

## 9. Kubernetes Watch 스펙

관찰 대상:

- Deployment
- ReplicaSet
- Pod
- Event
- EndpointSlice

요구사항:

- `WATCH-001` MUST: List 후 resourceVersion 기반 Watch를 시작해야 한다.
- `WATCH-002` MUST: Watch 종료 시 reconnect해야 한다.
- `WATCH-003` MUST: `410 Gone` 발생 시 relist하고 observation gap을 기록해야 한다.
- `WATCH-004` MUST: API object timestamp와 local observation timestamp를 모두 기록해야 한다.
- `WATCH-005` MUST: Watch gap이 있었는지 report metadata에 포함해야 한다.
- `WATCH-006` SHOULD: Bookmark event를 활용해야 한다.
- `WATCH-007` MUST NOT: API timestamp만으로 data-plane 적용 시점을 확정하지 않아야 한다.

## 10. Timeline Event 모델

```json
{
  "observedAt": "2026-08-18T12:00:06.121Z",
  "sourceTimestamp": "2026-08-18T12:00:06.100Z",
  "source": "kubernetes.pod",
  "type": "pod.deletion_observed",
  "resource": {
    "apiVersion": "v1",
    "kind": "Pod",
    "namespace": "payments",
    "name": "api-7c8f",
    "uid": "..."
  },
  "attributes": {}
}
```

필수 event 유형:

```text
run.started
baseline.started
baseline.completed
rollout.waiting
rollout.detected
rollout.completed
rollout.failed
replicaset.created
replicaset.scaled
pod.created
pod.ready
pod.unready
pod.deletion_observed
pod.container_terminated
endpoint.added
endpoint.condition_changed
endpoint.removed
probe.request_failed
probe.window_recovered
watch.gap_started
watch.gap_ended
settle.started
settle.completed
```

## 11. 판정 스펙

### 11.1 결과 유형

Verify:

```text
PASSED
FAILED
INCONCLUSIVE
```

Gate/Observe:

```text
NO_DEGRADATION_OBSERVED
DEGRADATION_OBSERVED
INCOMPLETE_OBSERVATION
INCONCLUSIVE
```

### 11.2 Finding 구조

모든 finding은 다음 필드를 가져야 한다.

```json
{
  "ruleId": "RP-TERM-001",
  "title": "Failures overlapped with Pod termination",
  "observation": "12 connection resets occurred during rollout",
  "correlation": "Failures began after Pod deletion was observed",
  "likelyExplanation": "Pattern is consistent with a termination or routing propagation gap",
  "confidence": "high",
  "evidenceEventIds": ["event-17", "event-24"],
  "notObserved": ["exact SIGTERM delivery", "node data-plane update"]
}
```

### 11.3 초기 Rule

| Rule ID | 조건 | Finding |
|---|---|---|
| `RP-BASE-001` | Baseline 오류가 policy 초과 | Baseline unstable |
| `RP-READY-001` | 새 Pod Ready 직후 실패 시작 | Premature readiness 가능성 |
| `RP-TERM-001` | Pod deletion 관찰 이후 실패 시작 | Termination overlap |
| `RP-ENDPOINT-001` | 실패 window가 endpoint 전환과 겹침 | Endpoint/data-plane propagation pattern |
| `RP-DRAIN-001` | Keep-Alive만 실패 | Existing connection draining 문제 가능성 |
| `RP-CONNECT-001` | 새 연결만 실패 | New connection routing 문제 가능성 |
| `RP-AVAIL-001` | Available replica가 policy 아래로 하락 | Availability gap |
| `RP-GRACE-001` | Grace 종료 근처에서 container 강제 종료 | Grace period 부족 가능성 |
| `RP-COVERAGE-001` | Watch 또는 rollout 일부 누락 | Incomplete observation |

### 11.4 Confidence

```text
high
medium
low
```

영향 요소:

- Baseline 안정성
- 전체 rollout 관찰 여부
- Watch gap 유무
- 최소 요청 수 충족
- Internal/External probe 일치 여부
- Backend attribution 유무
- Clock skew

## 12. Report 스펙

### 12.1 기준 형식

Versioned JSON을 canonical format으로 사용한다.

```json
{
  "schemaVersion": "rollout-proof.io/report/v1alpha1",
  "run": {},
  "target": {},
  "environment": {},
  "effectiveConfig": {},
  "coverage": {},
  "rollout": {},
  "probes": [],
  "timeline": [],
  "findings": [],
  "verdict": {},
  "redactions": []
}
```

- `REPORT-001` MUST: Schema version을 포함해야 한다.
- `REPORT-002` MUST: Effective config와 source를 포함해야 한다.
- `REPORT-003` MUST: Kubernetes context 이름을 저장하되 credential은 저장하지 않아야 한다.
- `REPORT-004` MUST: Partial/cancelled 실행도 유효한 report를 생성해야 한다.
- `REPORT-005` MUST: Secret header와 token을 저장하지 않아야 한다.

### 12.2 출력 형식

| 형식 | Milestone | 용도 |
|---|---|---|
| Terminal | v0.1 | Live 및 최종 요약 |
| JSON | v0.1 | Canonical artifact |
| Markdown | v0.2 | PR/Release summary |
| JUnit XML | v0.2 | CI test result |
| HTML | v0.4 | Timeline 공유 |

### 12.3 Live Timeline

```text
00:00  Baseline started
00:10  Baseline healthy — 100/100 requests succeeded
00:14  New revision detected: 183 → 184
00:18  New Pod api-7bd created
00:23  New Pod api-7bd became Ready
00:26  Old Pod api-66c entered Terminating
00:26  WARN 3 keep-alive connections reset
00:29  Old endpoint removed
00:44  Rollout completed
00:54  Settle period completed
```

## 13. Exit Code

| Code | 의미 |
|---:|---|
| `0` | Success 또는 policy 내 no degradation |
| `1` | Verification failed/degradation threshold exceeded |
| `2` | Inconclusive/incomplete observation |
| `3` | Invalid CLI/configuration |
| `4` | Kubernetes access/RBAC error |
| `5` | Probe execution error |
| `6` | Rollout timeout/no rollout observed |
| `7` | Internal execution/report write error |
| `130` | User cancellation where supported |

Gate/Observe에서 degradation을 exit `1`로 처리할지는 policy로 설정 가능하되 기본값을 문서화해야 한다. CI profile은 `1`, interactive production observe profile은 report-only `0`을 선택할 수 있다.

## 14. RBAC

### 14.1 Agentless Gate/Observe

필요 권한:

```text
get/list/watch deployments.apps
get/list/watch replicasets.apps
get/list/watch pods
get/list/watch events
get/list/watch services
get/list/watch endpointslices.discovery.k8s.io
create selfsubjectaccessreviews.authorization.k8s.io
```

### 14.2 Verify

Agentless 권한에 추가:

```text
patch deployments.apps
```

### 14.3 Ephemeral Probe

MVP-B에서 추가:

```text
create/get/list/watch/delete pods
get pods/log
```

권한은 실행 전 `SelfSubjectAccessReview`로 검사한다.

## 15. Production 안전성

- `SAFE-001` MUST: Production으로 추정되는 context에서는 기본적으로 Gate/Observe만 허용해야 한다.
- `SAFE-002` MUST: 기본 method는 GET 또는 HEAD여야 한다.
- `SAFE-003` MUST: 기본 RPS와 최대 요청 수에 안전 상한을 적용해야 한다.
- `SAFE-004` MUST: Authorization, Cookie, token 및 사용자 지정 secret header를 redaction해야 한다.
- `SAFE-005` MUST: Redirect 횟수와 cross-host redirect를 제한해야 한다.
- `SAFE-006` MUST: TLS verification을 기본 활성화해야 한다.
- `SAFE-007` MUST: `--insecure-skip-tls-verify` 사용을 report에 기록해야 한다.
- `SAFE-008` MUST: Verify와 ephemeral probe는 명시적 mutation 허용이 필요하다.
- `SAFE-009` MUST NOT: 자동 rollback이나 자동 patch fix를 수행하지 않아야 한다.

## 16. Ephemeral Probe 스펙

MVP-B 요구사항:

- CLI와 동일 version의 probe image 사용
- Session ID와 관리 label 추가
- Active deadline 적용
- 최소 resource request/limit
- Non-root 및 read-only root filesystem
- 종료 및 Ctrl+C 시 cleanup
- Cleanup 실패 시 resource 이름과 수동 명령 출력
- Existing NetworkPolicy를 우회하지 않음
- Private registry 오류를 명확히 분류

MVP-B는 별도 Helm 설치가 아니지만 Kubernetes mutation임을 UI와 report에 명시한다.

## 17. 배포 및 설치

필수 배포 채널:

- GitHub release binary
- Homebrew tap
- `go install`
- OCI container image
- GitHub Action

선택 채널:

- Krew plugin
- Package manager 추가 지원

요구사항:

- `DIST-001` MUST: Linux amd64/arm64를 지원해야 한다.
- `DIST-002` MUST: macOS amd64/arm64를 지원해야 한다.
- `DIST-003` SHOULD: Windows amd64를 지원해야 한다.
- `DIST-004` MUST: Release checksum을 제공해야 한다.
- `DIST-005` SHOULD: SBOM과 provenance를 제공해야 한다.
- `DIST-006` MUST: CLI와 probe image version compatibility를 검사해야 한다.

## 18. 성능 및 비기능 요구사항

- `NFR-001` MUST: 기본 실행에서 외부 database를 사용하지 않아야 한다.
- `NFR-002` MUST: 첫 실행에 configuration file을 요구하지 않아야 한다.
- `NFR-003` MUST: 기본 RPS에서 memory 사용량이 장시간 선형 증가하지 않아야 한다.
- `NFR-004` MUST: Timeline event 양에 대한 configurable memory/file limit이 있어야 한다.
- `NFR-005` MUST: SIGINT/SIGTERM을 처리하고 partial report를 생성해야 한다.
- `NFR-006` MUST: Report write는 임시 파일 후 atomic rename을 사용해야 한다.
- `NFR-007` SHOULD: 10분 rollout, 10 RPS, 2 profile을 일반 개발 머신에서 처리해야 한다.
- `NFR-008` SHOULD: CLI startup에서 baseline 시작까지 5초 이내여야 한다. Kubernetes API latency는 별도 기록한다.

## 19. Telemetry 및 Privacy

- 기본 telemetry는 비활성화한다.
- 사용자 opt-in 없이 외부 서버로 report를 전송하지 않는다.
- Crash report 자동 전송을 하지 않는다.
- URL query, header 및 resource annotation의 민감정보 redaction 규칙을 제공한다.
- Bundle 생성 시 redaction 결과 목록을 포함한다.

## 20. 테스트 스펙

### 20.1 Fixture

| Fixture | 기대 결과 |
|---|---|
| `graceful` | No degradation |
| `immediate-close` | Termination overlap 탐지 |
| `premature-readiness` | Readiness 관련 finding |
| `insufficient-grace` | Grace period 관련 finding |
| `unavailable-gap` | Availability gap 탐지 |
| `long-request` | Keep-Alive/long request interruption |

### 20.2 반복성 기준

- 정상 fixture: 30회 실행 중 false positive 0회 목표
- 결함 fixture: 30회 실행 중 95% 이상 탐지
- Watch reconnect fixture: 유효한 partial 또는 complete report 생성
- Cancellation fixture: partial report 및 cleanup 성공

### 20.3 호환성 Matrix

초기 matrix:

- Kubernetes: 최근 3개 minor version
- kind 기본 network
- Linux GitHub Actions
- macOS local client

MVP-B 이후 Cilium 또는 다른 eBPF CNI 환경을 하나 이상 추가한다.

## 21. Acceptance Criteria

### 21.1 v0.1 MVP-A Core

- 단일 binary로 설치
- External URL에 baseline 수행
- 새 revision 대기 및 감지
- Deployment/ReplicaSet/Pod/EndpointSlice timeline
- New/Keep-Alive 결과 분리
- Live timeline
- JSON report
- Explain 재현
- Production read-only gate
- Phase 0 fixture 반복성 기준 충족

### 21.2 v0.2 MVP-A Adoption

- `.rollout-proof.yaml`
- Multi GET/HEAD probe
- Effective config/source 출력
- Markdown/JUnit output
- GitHub Action 및 container
- Header/token redaction
- 설정 파일 없는 quick start 유지

### 21.3 v0.3 MVP-B

- Ephemeral probe lifecycle
- Service/port discovery
- Internal/External 동시 결과
- 추가 RBAC preflight
- Cleanup 및 orphan recovery

### 21.4 v0.4 비교와 협업

- Report diff
- 조건 불일치 경고
- Redacted bundle
- Framework guide
- Patch preview는 apply 없이 출력만 제공

## 22. 9점 효용성 Definition of Done

다음 조건을 모두 만족해야 한다.

1. 사용자가 지원 채널 중 하나로 5분 이내 설치할 수 있다.
2. 설정 파일 없이 10분 이내 첫 gate를 완료할 수 있다.
3. Gate가 rollout 이전 baseline부터 settle까지 전체 구간을 관찰한다.
4. 정상/결함 fixture 반복성 기준을 충족한다.
5. 새 연결과 Keep-Alive 결함을 구분한다.
6. Explain이 동일 report에서 동일 판정과 rule ID를 재현한다.
7. Profile과 multi-probe를 release 간 재사용할 수 있다.
8. GitHub Action 또는 container로 설치 없이 실행할 수 있다.
9. Report diff가 실제 regression fixture를 탐지한다.
10. Production external gate가 Kubernetes 쓰기 권한 없이 동작한다.
11. Secret과 인증정보가 report 및 bundle에서 제거된다.
12. 최소 3개 서비스와 2종류 CD workflow에서 반복 사용을 검증한다.

## 23. Open Questions

구현 전 확정이 필요한 항목:

1. Gate/Observe degradation의 기본 exit code 정책
2. Production context 탐지 규칙과 override 방식
3. New connection profile에서 connection 생성 단위
4. Keep-Alive pool 크기와 connection reuse 검증 방식
5. Kubernetes Event API `events.k8s.io/v1`과 core/v1 지원 범위
6. Deployment revision 감지의 정확한 기준
7. Report schema의 timeline inline/JSONL 분리 기준
8. Multi-probe scheduling과 전체 RPS 배분 방식
9. Config annotation에서 허용할 민감하지 않은 필드 범위
10. Ephemeral probe image의 최소 runtime 구성
