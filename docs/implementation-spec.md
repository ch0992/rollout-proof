# RolloutProof 엔지니어링 구현 스펙

> 상태: 0.1-draft  
> 작성 기준: 2026-08-18  
> 관련 문서: [제품 스펙](./product-spec.md), [초기 기획서](./initial-product-plan.md), [효용성 평가](./utility-evaluation.md)
> 개발 운영: [AI 개발 운영 지침](./ai-development-playbook.md), [Phase 0 Task 분해](./phase-0-task-breakdown.md)
> 환경 계약: [Mac 로컬 개발 환경](./development-environment.md), [Kubernetes Cluster 호환성](./cluster-compatibility.md)
> 검증 계약: [테스트 전략 및 검증 계획](./test-strategy.md)

## 1. 문서 목적

이 문서는 `rollout-proof`를 **어떤 기술과 방법으로 구현할지** 정의한다. 제품 스펙이 외부 동작 계약을 다룬다면, 이 문서는 언어, 라이브러리, 내부 구조, 동시성, 오류 처리, 테스트, 빌드 및 릴리스 계약을 다룬다.

다음은 이 문서의 결정 범위다.

- 구현 언어와 지원 버전
- 핵심 의존성과 의존성 선택 기준
- CLI 프로세스 및 패키지 구조
- Kubernetes watch와 HTTP probe 구현 방식
- event ordering, 시간 측정 및 상태 머신 방식
- 오류, 로그, 설정 및 report 구현 규칙
- 단위, 통합, E2E 및 호환성 테스트
- 로컬 개발, CI, binary/container 릴리스 방식
- 단계별 구현 순서와 완료 조건

## 2. 핵심 기술 결정

| 항목 | 결정 | 근거 |
|---|---|---|
| 언어 | Go 1.26 계열 | Kubernetes 생태계 친화성, 단일 binary, 정적 타입, 동시성, 표준 HTTP 지원 |
| 모듈 | Go Modules | 재현 가능한 의존성 및 표준 도구 체인 |
| CLI | Cobra 1.10 계열 | command/subcommand, completion, help 안정성 |
| Kubernetes | client-go 0.34 계열 | 최초 지원 하한인 Kubernetes 1.34와 정렬 |
| YAML | `go.yaml.in/yaml/v3` | strict decoding과 source 위치 기반 오류 제공 |
| HTTP probe | 표준 `net/http`, `httptrace` | 연결 재사용과 단계별 실패를 직접 관측 |
| 동시성 | `context`, goroutine, `errgroup`, bounded channel | 취소 전파, 제한된 병렬성, backpressure |
| 로그 | 표준 `log/slog` | 구조화 로그, 외부 로깅 의존성 제거 |
| 테스트 | 표준 `testing`, `httptest`, kind | domain logic과 실제 Kubernetes 동작을 분리 검증 |
| 배포 | binary, Homebrew, OCI image, GitHub Action | 설치 장벽 최소화 |
| 릴리스 | GoReleaser + GitHub Actions | 다중 플랫폼 artifact와 checksum 자동화 |

### 2.1 Go를 선택하는 이유

Go를 선택하는 핵심 이유는 이 도구가 Kubernetes API client이면서 동시에 높은 빈도의 HTTP probe를 수행하는 단일 CLI이기 때문이다.

- `client-go`를 직접 사용해 Kubernetes API 의미와 버전 정책을 그대로 따른다.
- macOS/Linux의 amd64/arm64 단일 binary를 만들기 쉽다.
- goroutine과 context가 watch, probe, timeout, signal 취소 모델에 잘 맞는다.
- `net/http`, `httptrace`, TLS 등 핵심 기능을 표준 라이브러리로 구현할 수 있다.
- 운영자가 Python/Node runtime을 설치할 필요가 없다.

Rust는 성능과 binary 배포에 유리하지만 Kubernetes client 생태계와 기여 진입 비용이 더 높다. Python과 TypeScript는 초기 개발 속도는 빠르지만 runtime 및 패키징 부담과 고빈도 probe의 예측 가능성 측면에서 본 프로젝트의 기본 전제에 덜 맞는다.

### 2.2 버전 정책

- `go.mod`는 `go 1.26`을 선언한다.
- 개발과 CI는 Go 1.26의 최신 patch를 사용한다. patch 버전을 source에 고정하지 않는다.
- 최초 Kubernetes 지원 범위는 1.34, 1.35, 1.36이다.
- `client-go`, `k8s.io/api`, `k8s.io/apimachinery`는 모두 같은 `v0.34.x` patch로 맞춘다.
- Kubernetes stable API만 사용하며 버전별 분기를 최소화한다.
- 지원 범위는 Kubernetes upstream의 최근 세 minor 정책에 맞춰 minor release마다 갱신한다.
- 의존성 갱신은 주 1회 자동 PR로 만들되, compatibility matrix를 통과한 경우에만 병합한다.

`v0.34.x` client를 선택하는 이유는 지원 범위의 가장 오래된 cluster를 기준으로 compile-time API를 제한하기 위해서다. 최신 cluster에서도 공통 stable API만 사용한다.

## 3. 설계 원칙

### 3.1 단일 프로세스, 설치물 없음

기본 실행은 하나의 로컬 CLI 프로세스다. CRD, controller, database, message broker를 설치하지 않는다. MVP-B의 internal probe만 명시적 opt-in으로 임시 Kubernetes resource를 생성할 수 있다.

### 3.2 Domain과 외부 I/O 분리

상태 전이, finding rule, verdict, report diff는 Kubernetes나 실제 clock 없이 테스트 가능해야 한다. Kubernetes API, HTTP, filesystem, terminal은 adapter로 분리한다.

### 3.3 명시적 의존성 주입

DI framework와 전역 singleton을 사용하지 않는다. constructor parameter로 client, clock, writer 및 policy를 전달한다. interface는 소비하는 package에서 작게 정의한다.

### 3.4 규칙 기반의 재현성

같은 report와 같은 rule version은 항상 같은 verdict를 만들어야 한다. 분석기는 외부 API, LLM 또는 현재 cluster 상태를 조회하지 않는다.

### 3.5 안전한 기본값

기본 명령은 read-only다. mutation은 command와 flag에서 명시적으로 드러나야 하며 preflight에서 RBAC 권한과 대상 resource를 먼저 출력한다.

## 4. 프로세스 아키텍처

```text
Cobra command
    │
    ▼
Application runner ── Preflight / Discovery
    │
    ├── Kubernetes watch supervisors ─┐
    ├── HTTP probe workers ───────────┼── Event bus
    └── Signal / timeout ─────────────┘      │
                                             ▼
                                      Timeline aggregator
                                             │
                               ┌─────────────┴─────────────┐
                               ▼                           ▼
                         Rollout state                Live renderer
                               │
                               ▼
                         Analyzer rules
                               │
                               ▼
                    Report + terminal + exit code
```

### 4.1 실행 단계

1. CLI option과 config를 병합하고 strict validation한다.
2. kube context, namespace, Deployment, URL 및 출력 경로를 확인한다.
3. RBAC SelfSubjectAccessReview와 대상 discovery를 수행한다.
4. initial LIST로 baseline snapshot과 resourceVersion을 확보한다.
5. watch supervisor와 probe worker를 시작한다.
6. `gate`는 baseline 안정성을 확인한 뒤 새 revision을 기다린다.
7. 모든 관측을 immutable domain event로 event bus에 보낸다.
8. 단일 aggregator가 sequence를 부여하고 timeline과 rollout state를 갱신한다.
9. 종료 조건 도달 시 worker를 취소하고 bounded drain을 수행한다.
10. analyzer가 report를 만들고 renderer와 exit policy가 결과를 출력한다.

## 5. 저장소와 패키지 구조

```text
cmd/rollout-proof/main.go
internal/
  app/                  command orchestration
    gate/
    observe/
    verify/
    explain/
    reportdiff/
  config/               defaults, file/env/flag merge, validation
  kube/
    client/             rest.Config와 typed clients
    discovery/          Deployment, Service, URL discovery
    watch/              LIST/WATCH reconnect supervisor
    rbac/               preflight permission check
    mutate/             verify/internal probe에서만 사용하는 write path
  probe/
    runner/             scheduling과 worker pool
    transport/          new/keep-alive profile
    classify/           DNS/TCP/TLS/HTTP 오류 분류
  timeline/             event, bus, clock, ordering
  rollout/              revision과 상태 머신
  analyzer/             versioned finding rules와 confidence
  report/               schema, terminal, JSON, Markdown, JUnit, diff
  redact/               URL, header, annotation, message 정제
  platform/             signal, atomic file, terminal capability
pkg/report/v1alpha1/    외부 사용을 허용하는 report Go type
fixtures/               정상/결함 샘플 workload
test/e2e/               kind 기반 scenario
docs/adr/               주요 기술 결정 기록
```

원칙:

- `cmd`에는 wiring과 exit 외의 logic을 두지 않는다.
- `internal/app`은 use case를 조립하지만 구체적인 HTTP/Kubernetes 구현을 직접 생성하지 않는다.
- `pkg`는 report consumer가 실제로 필요해질 때만 공개한다. 초기에는 report schema 외 공개 package를 만들지 않는다.
- package cycle을 허용하지 않는다.
- `util`, `common`, `helpers` 같은 범용 package를 만들지 않는다.

## 6. CLI와 설정 구현

### 6.1 Cobra 구성

- root command는 dependency constructor를 전달받는다.
- 각 subcommand는 `RunE`를 사용하며 panic 대신 error를 반환한다.
- usage error와 runtime error를 분리한다.
- stdout은 사용자 결과와 machine-readable output 전용, stderr는 progress와 log 전용이다.
- JSON/JUnit output 모드에서 stdout을 오염시키지 않는다.

### 6.2 설정 우선순위

```text
compiled default < config file < environment variable < CLI flag
```

- `.rollout-proof.yaml`은 unknown field를 오류로 처리한다.
- merge 후 effective config를 immutable value로 만든다.
- duration, URL, RPS, timeout 및 path는 실행 전에 모두 검증한다.
- `config print --effective`는 secret을 제거한 최종 설정을 출력한다.
- annotation config는 제품 스펙의 allowlist만 허용한다.

### 6.3 Config API

- 최초 schema는 `apiVersion: rollout-proof.io/v1alpha1`이다.
- CLI 버전과 config/report schema 버전은 독립적으로 관리한다.
- alpha에서도 unknown field silent-ignore는 허용하지 않는다.
- breaking migration이 생기면 명시적 오류와 migration guide를 제공한다.

## 7. Kubernetes 구현

### 7.1 사용하는 API

- `apps/v1`: Deployment, ReplicaSet
- `core/v1`: Pod, Service, Event fallback
- `discovery.k8s.io/v1`: EndpointSlice
- `events.k8s.io/v1`: Event 우선 경로
- `authorization.k8s.io/v1`: SelfSubjectAccessReview

Dynamic client보다 typed client를 기본으로 사용한다. unstructured 변환은 미지원 workload 확장 전까지 도입하지 않는다.

### 7.2 Discovery

1. Deployment를 GET한다.
2. selector로 관련 ReplicaSet과 Pod를 LIST한다.
3. 명시적 Service 또는 profile URL이 있으면 그 대상을 우선한다.
4. 자동 URL discovery는 annotation allowlist 안에서만 수행한다.
5. EndpointSlice는 Service label로 연결한다.
6. ownerReference와 revision annotation을 함께 사용해 revision을 판별한다.

이름 prefix만으로 resource 관계를 추론하지 않는다.

### 7.3 LIST/WATCH supervisor

정확한 timeline을 위해 informer callback에 domain 의미를 직접 결합하지 않는다. resource 종류별 supervisor는 다음 루프를 구현한다.

1. label/field selector가 적용된 LIST를 수행한다.
2. list item을 snapshot event로 전달하고 resourceVersion을 저장한다.
3. 해당 resourceVersion부터 WATCH한다.
4. bookmark event로 진행 위치를 갱신한다.
5. 일시 오류는 jitter가 있는 exponential backoff로 reconnect한다.
6. `410 Gone`이면 다시 LIST하고 `watch_gap` observation을 남긴다.
7. relist 결과를 이전 cache와 비교해 실제 변경만 event로 만든다.
8. context 취소 시 즉시 watch를 닫는다.

Backoff 기본값은 250ms에서 시작해 최대 10초이며 full jitter를 적용한다. reconnect 횟수와 gap은 report에 남긴다. watch gap이 핵심 판정 구간을 포함하면 verdict를 무조건 PASS로 만들지 않고 confidence를 낮추거나 INCONCLUSIVE로 처리한다.

### 7.4 API rate와 timeout

- client-go 기본 rate limiter를 명시적으로 설정한다.
- 기본 QPS/Burst는 read-only single target에 맞는 보수적 값으로 시작하고 부하 테스트 후 확정한다.
- 모든 API call은 command root context와 개별 timeout을 갖는다.
- retry는 GET/LIST/WATCH 같은 안전한 작업에만 적용한다.
- mutation에는 일반 retry를 적용하지 않고 conflict에 대한 bounded retry만 사용한다.

## 8. HTTP probe 구현

### 8.1 Worker model

- scheduler가 monotonic deadline을 기준으로 probe job을 생성한다.
- bounded channel과 고정 worker pool을 사용한다.
- scheduler가 밀리면 무한 backlog를 만들지 않고 `probe_schedule_lag`를 기록한다.
- 전체 RPS budget을 probe별 weight로 배분한다.
- 기본 request는 GET 또는 HEAD만 허용한다.
- redirect는 기본적으로 제한하며 host 변경 시 명시적 policy가 필요하다.

### 8.2 Connection profile

`new` profile:

- request마다 새 transport 또는 명시적으로 새 connection이 되도록 구성한다.
- `DisableKeepAlives`를 사용한다.
- idle connection이 다음 request에 재사용되지 않음을 테스트한다.

`keep-alive` profile:

- profile마다 독립된 `http.Transport`를 공유한다.
- `MaxIdleConns`, `MaxIdleConnsPerHost`, `IdleConnTimeout`을 명시한다.
- `httptrace.GotConnInfo.Reused`를 저장해 재사용 여부를 증거로 남긴다.

두 profile은 같은 worker나 transport를 공유하지 않는다. HTTP/2 자동 negotiation은 MVP-A에서 비활성화하거나 명시적으로 report에 기록해 HTTP/1.1 결과와 혼합되지 않게 한다.

### 8.3 단계별 오류 분류

custom `DialContext`, `TLSHandshakeTimeout`, `ResponseHeaderTimeout`과 `httptrace`를 사용해 다음으로 분류한다.

- DNS resolution
- TCP connect
- TLS handshake/certificate
- connection reset/EOF
- request write
- response header timeout
- HTTP status policy failure
- body validation failure
- client cancellation/deadline

오류 문자열 matching을 판정 근거로 사용하지 않는다. `net.Error`, `url.Error`, `net.OpError`, `tls` 오류 및 typed wrapper를 `errors.Is/As`로 분류한다. 원문 오류는 redaction 후 보조 정보로만 보존한다.

### 8.4 시간 측정

- report 시각은 UTC RFC3339Nano다.
- event에는 run 시작 이후 monotonic elapsed nanoseconds도 저장한다.
- 상관관계와 latency 계산은 elapsed time으로 수행한다.
- 서로 다른 system clock을 가진 외부 source의 timestamp는 observation으로 표시하고 local receive time과 구분한다.

## 9. Event bus와 상태 관리

### 9.1 Event 규칙

모든 event는 생성 후 변경하지 않는다.

```go
type Event struct {
    Sequence  uint64
    At        time.Time
    Elapsed   time.Duration
    Source    Source
    Kind      Kind
    ObjectRef *ObjectRef
    Payload   Payload
}
```

구체 payload는 `map[string]any` 대신 typed struct를 사용한다. JSON schema로 내보낼 때만 versioned DTO로 변환한다.

### 9.2 Ordering

- producer는 관측 시각과 source metadata를 넣는다.
- 단일 aggregator goroutine만 sequence를 발급한다.
- sequence가 report의 최종 total order다.
- 같은 순간의 Kubernetes resourceVersion을 전역 clock처럼 취급하지 않는다.
- live renderer와 analyzer는 같은 canonical event stream을 소비한다.

### 9.3 Backpressure

- event channel은 bounded다.
- probe sample이 과도하면 raw 성공 event를 interval aggregate로 축약할 수 있다.
- 실패, 상태 전이, watch gap은 drop하지 않는다.
- channel pressure와 축약 수는 report diagnostics에 기록한다.
- memory budget 초과 시 silent loss 대신 INCONCLUSIVE 또는 명시적 실패로 종료한다.

## 10. Rollout state machine과 분석기

### 10.1 State machine

권장 상태는 다음과 같다.

```text
Initializing → Baselining → WaitingForRevision → Progressing
             ↘ Inconclusive                  ↘ Settling → Completed
                                                ↘ Failed
```

- state transition은 순수 함수로 구현한다.
- input은 이전 state와 domain event다.
- transition에는 reason code와 evidence reference가 포함된다.
- timeout도 wall-clock polling이 아니라 timer event로 주입한다.

### 10.2 Analyzer

- rule은 stable ID, version, severity, required evidence를 가진다.
- rule 간 실행 순서가 결과에 영향을 주지 않게 한다.
- finding은 observation ID를 참조한다.
- correlation window와 confidence 계산식을 code와 문서에서 일치시킨다.
- `explain`은 저장된 report만으로 같은 finding을 재생성할 수 있어야 한다.
- 분석 rule 변경 시 golden report regression test를 갱신한다.

## 11. 오류, 로그 및 종료

### 11.1 오류 모델

최상위 오류는 다음 category를 갖는다.

- `UsageError`
- `ConfigError`
- `PermissionError`
- `DiscoveryError`
- `ObservationError`
- `VerificationFailure`
- `InternalError`

오류는 `%w`로 원인을 보존하고 machine-readable code를 갖는다. 최종 exit code 변환은 `main` 한 곳에서만 수행한다. library package에서 `os.Exit`, `log.Fatal`, panic을 사용하지 않는다.

### 11.2 로그

- `slog`를 사용하고 `--log-format text|json`, `--log-level`을 제공한다.
- password, token, Authorization/Cookie header, URL query는 ingestion 시점에 redaction한다.
- request body와 response body는 기본 수집하지 않는다.
- 로그에 전체 Kubernetes Secret이나 kubeconfig를 출력하지 않는다.
- progress renderer와 structured log는 서로 다른 writer를 사용한다.

### 11.3 Graceful shutdown

SIGINT/SIGTERM을 root context 취소로 변환한다. 신규 probe 생성을 즉시 중단하고 진행 중 요청과 watch를 취소한 뒤 짧은 bounded drain 동안 report를 원자적으로 저장한다. 두 번째 signal은 즉시 종료한다.

## 12. Report와 파일 I/O

- report schema는 `rollout-proof.io/report/v1alpha1`로 versioning한다.
- 내부 domain model을 직접 JSON marshal하지 않고 DTO mapping layer를 둔다.
- report는 임시 파일에 쓴 뒤 rename하는 atomic write를 사용한다.
- JSON key ordering에 의존하지 않는다.
- Markdown/JUnit은 canonical report에서 생성한다.
- 큰 timeline을 위한 JSONL 분리는 schema 결정 전 feature flag로 만들지 않는다.
- report diff는 dynamic field를 normalization한 뒤 의미 단위로 비교한다.

## 13. 테스트 전략

### 13.1 Unit test

전체 test의 중심이며 실제 sleep과 network를 사용하지 않는다.

- config precedence와 strict validation
- Deployment revision 판별
- rollout state transition
- timeline ordering과 watch relist deduplication
- HTTP typed error classification
- finding rule과 confidence
- verdict와 exit code
- redaction
- report normalization과 diff

fake clock과 table-driven test를 사용한다. 핵심 state machine과 analyzer는 branch coverage 90% 이상을 목표로 하고, 전체 coverage 숫자를 품질 목표로 사용하지 않는다.

### 13.2 Component test

- `httptest.Server`와 custom listener로 timeout, reset, delayed header, status 변화, keep-alive reuse를 재현한다.
- 가짜 Kubernetes HTTP API server로 LIST/WATCH, bookmark, disconnect, 410/relist를 검증한다.
- client-go fake client는 discovery와 CRUD 단위 test에만 사용한다. 실제 watch 신뢰성의 증거로 사용하지 않는다.

### 13.3 E2E test

kind cluster에서 실제 Deployment, ReplicaSet, Pod, Service, EndpointSlice 변화를 검증한다.

Mac의 canonical environment는 Colima Docker runtime 위의 kind이며 Colima 내장 k3s와 혼합하지 않는다. CI와 Mac은 같은 kind config와 digest-pinned node image를 사용한다. 실제 on-prem/cloud 검증의 level, suite, 주기와 mutation safety는 [테스트 전략 및 검증 계획](./test-strategy.md)을 따른다.

PR smoke:

- 지원 Kubernetes 중 대표 1개 version
- 정상 rollout 1회
- readiness 결함 1회
- gate wait-for-revision 1회

nightly compatibility:

- Kubernetes 1.34, 1.35, 1.36 matrix
- 정상, readiness, graceful shutdown, endpoint gap, keep-alive fixture
- 핵심 fixture 반복 실행과 flaky rate 측정
- binary와 container 양쪽 실행

release gate:

- 최근 3개 Kubernetes minor 전체 PASS
- 정상 fixture false positive 0/30
- 정의된 결함 fixture detection 30/30
- report schema golden compatibility PASS
- race detector와 vulnerability scan PASS

### 13.4 추가 검증

- `go test -race ./...`
- config/report/redactor/error classifier fuzz test
- `go vet ./...`
- pinned `golangci-lint`
- `govulncheck ./...`
- `go mod verify`

## 14. 로컬 개발 workflow

필수 명령은 Makefile에 얇게 제공하되 실제 logic은 Go tool 또는 script에 둔다.

```bash
make test          # unit/component
make test-race
make lint
make build
make kind-up
make e2e
make snapshot      # golden report 확인
```

개발 방식은 vertical slice를 따른다. package 전체를 미리 만드는 대신 하나의 사용자 시나리오를 CLI부터 report까지 완성한다.

1. failing acceptance scenario 또는 fixture를 먼저 정의한다.
2. domain type과 state transition test를 작성한다.
3. 최소 adapter를 연결해 scenario를 통과시킨다.
4. JSON golden과 terminal snapshot을 검토한다.
5. kind에서 실제 동작을 검증한다.
6. 사용자 문서와 ADR을 같은 변경에 반영한다.

주요 결정은 `docs/adr/NNNN-title.md`에 context, decision, consequences 형식으로 남긴다. 첫 ADR은 언어/프로세스, client-go version, direct LIST/WATCH, report schema versioning이다.

## 15. CI 및 릴리스

### 15.1 CI pipeline

```text
format/vet → unit/component → race/fuzz smoke → build
                                      └──────→ kind E2E
```

- GitHub Actions action은 commit SHA로 pin한다.
- build cache는 사용하되 test 결과를 cache하지 않는다.
- PR은 representative kind E2E, nightly는 전체 compatibility matrix를 실행한다.
- generated file 변경 여부를 CI에서 검사한다.

### 15.2 Artifact

- `darwin/amd64`, `darwin/arm64`, `linux/amd64`, `linux/arm64`
- tar.gz archive와 SHA256 checksum
- Homebrew formula
- multi-arch OCI image
- GitHub Action wrapper
- SBOM
- provenance와 keyless signature

CGO는 기본적으로 비활성화한다. container는 CA certificate가 포함된 non-root distroless static image를 사용하고 read-only filesystem에서 실행 가능해야 한다.

### 15.3 버전 관리

- CLI는 Semantic Versioning을 따른다.
- config와 report schema는 별도 `apiVersion`을 사용한다.
- pre-1.0 CLI에서도 CI가 의존하는 flag, exit code, report field 변경은 release note에 명시한다.
- tag build는 깨끗한 source와 lock된 module graph에서 재현 가능해야 한다.

## 16. 보안 및 개인정보

- telemetry는 기본적으로 수집하지 않는다.
- 외부 network 전송은 사용자가 지정한 probe endpoint와 Kubernetes API로 제한한다.
- URL userinfo, query, 인증 header 및 민감 annotation은 저장 전에 제거한다.
- internal probe image는 non-root, read-only root filesystem, capability drop을 기본값으로 한다.
- mutation command는 resource와 namespace를 출력하고 최소 RBAC 예시를 제공한다.
- dependency와 container vulnerability scan을 release gate에 포함한다.
- diagnostic bundle은 allowlist 방식으로만 항목을 포함한다.

## 17. 성능 및 자원 목표

초기 engineering budget은 다음과 같다. Phase 0 실측 후 수정한다.

| 항목 | 목표 |
|---|---|
| idle RSS | 100 MiB 이하 |
| 기본 10 RPS CPU | 일반 노트북 core 1개의 10% 이하 평균 |
| 기본 event channel | bounded, 10,000 event 이하 |
| report flush | 종료 후 2초 이내 |
| probe scheduler lag | p99가 interval의 20% 이하 |
| 정상 실행 event loss | 0 |
| watch disconnect 복구 | network 복구 후 15초 이내 |

성능을 위해 correctness를 희생하지 않는다. raw 성공 sample 축약은 원본 수치와 축약 개수를 report에 남긴 경우에만 허용한다.

## 18. 단계별 구현 순서

### Phase 0 — 기술 위험 제거

1. Go module과 Cobra skeleton
2. client-go LIST/WATCH reconnect spike
3. `net/http` new/keep-alive profile spike
4. kind 정상/결함 fixture
5. event ordering과 JSON report prototype

완료 기준은 EndpointSlice 변화와 HTTP 실패를 하나의 monotonic timeline으로 반복 재현하는 것이다.

### MVP-A1 — 최소 유효 gate

1. config/CLI/preflight
2. Deployment/ReplicaSet/Pod/EndpointSlice discovery
3. gate wait-for-revision state machine
4. 단일 URL, new connection probe
5. terminal + JSON report
6. PASS/FAIL/INCONCLUSIVE와 exit code

### MVP-A2 — 진단력과 채택성

1. keep-alive profile
2. typed error classifier와 httptrace
3. live timeline과 explain
4. multi-probe와 reusable policy profile
5. Markdown/JUnit
6. GitHub Action, container, Homebrew

### MVP-B — 선택적 internal probe

read-only core와 package 경계를 유지한 채 별도 mutation adapter로 구현한다. ephemeral resource 생성, TTL cleanup, Pod Security 호환성, 실패 시 수동 정리 안내를 포함한다.

## 19. 초기 ADR 목록

| ADR | 결정 |
|---|---|
| ADR-0001 | RolloutProof 제품명과 명명 규칙 |
| ADR-0002 | Go 단일 프로세스 CLI와 no-controller 원칙 |
| ADR-0003 | Kubernetes 1.34 하한과 client-go 0.34 정렬 |
| ADR-0004 | direct LIST/WATCH supervisor와 gap 처리 |
| ADR-0005 | 단일 event aggregator와 monotonic ordering |
| ADR-0006 | net/http 기반 connection profile |
| ADR-0007 | domain model과 versioned report DTO 분리 |
| ADR-0008 | kind 중심 compatibility test matrix |

## 20. 구현 착수 전 확정할 항목

다음은 Phase 0 실험 결과를 보고 확정한다.

1. 기본 probe RPS와 worker 수
2. client-go QPS/Burst
3. WATCH relist diff의 cache memory 상한
4. HTTP/2를 MVP-A에서 완전히 비활성화할지 여부
5. raw probe sample 보존과 interval aggregate 기준
6. report inline timeline 크기 제한
7. watch gap이 INCONCLUSIVE가 되는 정확한 조건
8. Production context 탐지와 경고 방식
9. internal probe resource 종류와 cleanup 보장 방식

이 항목들은 제품 방향을 다시 여는 질문이 아니라, 측정 결과로 정할 engineering parameter다.

## 21. 구현 준비 완료 정의

다음이 충족되면 코딩을 시작할 수 있다.

1. Phase 0 acceptance scenario와 fixture가 정의되어 있다.
2. CLI/config/report의 v1alpha1 최소 schema가 확정되어 있다.
3. 지원 Kubernetes matrix와 개발 Go version이 CI에 표현되어 있다.
4. event, observation, finding, verdict의 domain type 초안이 있다.
5. LIST/WATCH gap과 HTTP 오류 분류 test case가 준비되어 있다.
6. 첫 vertical slice인 `gate deployment/api --url ...`의 종료 조건이 명확하다.
7. mutation 없는 최소 RBAC manifest가 작성되어 있다.
8. release artifact와 security baseline이 CI backlog에 포함되어 있다.

## 참고 자료

- [Go Release History](https://go.dev/doc/devel/release)
- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [client-go](https://github.com/kubernetes/client-go)
- [client-go Architecture](https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/client-go/ARCHITECTURE.md)
- [Cobra](https://github.com/spf13/cobra)
