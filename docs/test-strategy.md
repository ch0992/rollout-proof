# RolloutProof 테스트 전략 및 검증 계획

> 상태: 0.1-draft
> 책임: 구현과 호환성 주장을 검증하는 test level, scenario, 환경, 주기, evidence 및 통과 기준 정의
> 개발환경: [Mac 로컬 개발 환경](./development-environment.md)
> 지원 정책: [Kubernetes Cluster 호환성](./cluster-compatibility.md)
> 제품 test 이전 환경 acceptance: [로컬 개발 인프라 검증 계약](./local-environment-validation.md)

## 1. 테스트 목표

테스트는 다음 네 가지를 독립적으로 증명한다.

1. 같은 input event가 같은 state/finding/report를 만든다.
2. Kubernetes LIST/WATCH와 HTTP probe가 실제 failure를 누락 없이 관측한다.
3. Mac, Linux, on-prem과 managed cluster 차이가 core 동작을 깨지 않는다.
4. 실제 cluster 검증이 사용자의 기존 workload와 cluster를 훼손하지 않는다.

Mac·Colima·Docker·kind 자체의 readiness는 제품 L0~L4 test에 포함하지 않고 환경 검증 계약에서 선행 검증한다.

테스트 개수나 coverage 숫자만으로 완료를 판정하지 않는다. 각 requirement와 failure mode에 evidence가 있어야 한다.

## 2. 테스트 분류

| Level | 이름 | 실행 환경 | 주요 책임 |
|---|---|---|---|
| L0 | Domain Unit | Go process | 상태 머신, rule, report, config |
| L1 | Component/API Contract | httptest/fake API server | HTTP phase, LIST/WATCH, 410, RBAC |
| L2 | Local Kubernetes E2E | kind | 실제 Deployment/Pod/EndpointSlice |
| L3 | Distribution Smoke | kubeadm/K3s/RKE2/OpenShift | distribution 차이 |
| L4 | Managed Cloud | EKS/GKE/AKS | auth/network/admission/LB 차이 |

상위 level은 하위 level을 대체하지 않는다. L4 PASS로 L0/L1 실패를 무시할 수 없다.

## 3. L0 Domain Unit

대상:

- config precedence와 validation
- event type과 ordering
- rollout state transition
- finding rule/confidence/verdict
- error/exit code mapping
- redaction
- report normalization/diff

규칙:

- 실제 network, filesystem 또는 sleep에 의존하지 않는다.
- fake clock과 table-driven test를 사용한다.
- state machine/analyzer 핵심 branch coverage는 90% 이상을 목표로 한다.
- coverage 평균이 mandatory scenario 누락을 상쇄하지 않는다.
- 같은 fixture는 실행 순서와 무관하게 같은 결과를 만들어야 한다.

PR마다 실행한다.

## 4. L1 Component 및 API Contract

### 4.1 HTTP

`httptest.Server`, custom listener와 fake resolver로 다음을 재현한다.

- DNS failure
- TCP refusal/timeout
- TLS handshake/certificate failure
- connection reset/EOF
- response header timeout
- HTTP status policy
- body validation
- context cancel/deadline
- new connection reuse 0
- keep-alive connection reuse evidence

### 4.2 Kubernetes API

fake Kubernetes HTTP server로 다음을 검증한다.

- initial LIST 이후 WATCH 순서
- bookmark resourceVersion
- EOF reconnect
- `410 Gone` relist
- relist deduplication
- watch gap event
- permission denied
- API discovery missing/degraded

client-go fake client만으로 watch 신뢰성을 증명하지 않는다.

PR마다 실행하며 race detector를 포함한다.

## 5. L2 kind E2E

### 5.1 환경

- Linux CI: Kubernetes 1.34, 1.35, 1.36
- Mac Colima: 대표 최신 minor
- Mac Docker Desktop: 대표 최신 minor
- node image: tag + SHA256 digest
- topology: control-plane 1 + worker 1
- kubeconfig: repository `.work` 경로

### 5.2 Core Scenario

| ID | Scenario | 기대 결과 |
|---|---|---|
| E2E-NORMAL-001 | 정상 rolling update | PASS, HTTP failure 없음 |
| E2E-READY-001 | readiness 지연 | lifecycle 지연 관측, policy에 따른 판정 |
| E2E-ENDPOINT-001 | EndpointSlice propagation gap | gap과 request failure 상관관계 |
| E2E-TERM-001 | 잘못된 graceful shutdown | reset/EOF와 terminating Pod evidence |
| E2E-WATCH-001 | watch connection 종료 | reconnect 후 report 완성 |
| E2E-WATCH-002 | stale resourceVersion | gap/relist evidence와 confidence 저하 |
| E2E-CONN-001 | new connection profile | reuse 0 증명 |
| E2E-CONN-002 | keep-alive profile | reuse와 connection failure 구분 |
| E2E-REPORT-001 | terminal/JSON 동시 생성 | canonical event/verdict 일치 |
| E2E-REDACT-001 | secret-like metadata | artifact에 민감정보 없음 |

각 scenario는 Given, Trigger, Expected observation, Expected verdict, Cleanup을 fixture README에 기록한다.

## 6. L3 Distribution Smoke

초기 대상:

- kubeadm 또는 upstream conformant cluster
- K3s
- RKE2
- OpenShift

검증 범위:

- server/API discovery
- RBAC preflight
- Deployment revision과 owner relation
- Pod/ReplicaSet/EndpointSlice watch
- external HTTP probe
- report/redaction
- namespace-scoped cleanup

distribution 전용 기능을 테스트하기보다 동일 black-box suite를 실행한다. OpenShift SCC나 Route처럼 차이가 있는 항목은 adapter 요구가 아니라 limitation/evidence로 먼저 기록한다.

## 7. L4 Managed Cloud

초기 대상은 EKS, GKE, AKS다.

추가 검증:

- kubeconfig exec credential과 token refresh
- private/public API endpoint 조건
- provider dataplane과 EndpointSlice 반영
- Ingress/L4 load balancer external path
- admission/defaulting 차이
- cloud identity 만료 오류 분류

provider SDK는 test infrastructure에서 cluster 준비에 사용할 수 있지만 RolloutProof binary에는 포함하지 않는다.

## 8. 실행 주기

| Trigger | 실행 범위 | 필수 여부 |
|---|---|---|
| Local edit | targeted L0/L1 | 필수 |
| Pull Request | 전체 L0/L1 + 대표 kind smoke | 필수 |
| Main merge | 전체 L0/L1 + 대표 kind E2E | 필수 |
| Nightly | kind 1.34~1.36 전체 scenario | 필수 |
| Weekly/Monthly | L3 distribution smoke | 환경 가용 시 |
| Release candidate | kind 전체 + 실제 distribution 2종 + managed 1종 | 필수 |
| Minor release claim | 주장할 각 EKS/GKE/AKS | 해당 provider 표시에 필수 |

비용이 큰 L3/L4를 모든 PR에서 실행하지 않는다. 대신 동일 commit을 release evidence로 고정한다.

## 9. PR Test Gate

PR merge 조건:

1. 변경 Task의 targeted test PASS
2. 영향 package 전체 test PASS
3. `go test -race` 해당 범위 PASS
4. lint/vet/vulnerability gate PASS
5. 대표 kind smoke PASS 또는 cluster 비관련 변경 사유 기록
6. golden/schema diff 승인
7. 작업 평가서 PASS

INCONCLUSIVE는 merge PASS가 아니다.

## 10. Release Test Gate

초기 release 최소 조건:

1. kind 1.34~1.36 전체 core scenario PASS
2. 정상 fixture false positive 0/30
3. 정의된 결함 fixture detection 30/30
4. Apple Silicon Colima smoke PASS
5. Docker Desktop smoke PASS
6. 서로 다른 실제 distribution 2종 PASS
7. managed cloud 1종 PASS
8. report schema/golden compatibility PASS
9. race, fuzz, vulnerability scan PASS
10. cleanup/redaction inspection PASS

EKS/GKE/AKS 모두를 `Release Tested`로 표시하려면 같은 release commit으로 각 환경 suite를 실행해야 한다.

## 11. 실제 Cluster Test 안전 계약

mutation test 필수 입력:

- 명시적 kubeconfig path
- 명시적 context
- 명시적 test namespace
- `ROLLOUTPROOF_E2E_ALLOW_MUTATION=true`
- run ID와 cleanup label

안전 규칙:

- `default`, `kube-system`과 기존 application namespace 금지
- cluster-scoped resource 생성 금지
- 실행 전 context, server URL, cluster identity 출력
- `app.kubernetes.io/managed-by=rollout-proof`와 `rolloutproof-test-run=<run-id>` 사용
- namespace와 label이 모두 일치하는 resource만 cleanup
- production context는 추가 `--allow-production-test` 없이는 mutation 거부
- cleanup 실패 시 수동 명령과 잔여 resource를 artifact에 기록
- 다른 kind cluster, Colima profile 또는 namespace를 삭제하지 않음

read-only smoke는 mutation opt-in 없이 가능하지만 target, URL과 request rate를 명시한다.

## 12. Test Data와 Fixture

- 정상 fixture와 결함 fixture는 한 가지 failure axis만 다르게 만든다.
- image와 manifest에 commit/run ID를 기록한다.
- 무작위 chaos를 core release gate로 사용하지 않는다.
- random/jitter source는 seed를 artifact에 기록한다.
- fixture 변경은 expected timeline/golden 변경과 함께 review한다.
- cloud 전용 fixture fork보다 공통 fixture + environment parameter를 우선한다.

## 13. Flaky Test 정책

- 실패한 E2E를 자동 retry해 PASS로 덮지 않는다.
- 첫 실행 결과와 retry 결과를 모두 기록한다.
- flaky로 확인된 test는 owner, 재현율, 만료일이 있는 quarantine issue를 만든다.
- quarantine test는 release gate 통계에서 제외하지 않고 별도로 표시한다.
- 동일 scenario flaky rate 1% 초과 시 원인 해결 전 release를 차단한다.

## 14. Evidence와 Artifact

각 실행은 다음 metadata를 남긴다.

```text
runId
testCommit
toolVersion
scenarioId
hostOS
architecture
containerProvider
distribution
kubernetesVersion
apiCapabilities
networkProfile
authMethodCategory
startedAt/finishedAt
result
artifactChecksums
knownLimitations
```

artifact:

- RolloutProof JSON/Markdown/JUnit report
- sanitized Kubernetes object snapshot
- kind/cluster diagnostics
- test command와 exit code
- cleanup 결과

credential, token, URL query와 secret data는 저장하지 않는다.

## 15. Compatibility Evidence 상태

| 상태 | 기준 |
|---|---|
| Continuously Tested | 자동 scheduled matrix에서 반복 PASS |
| Release Tested | 해당 release commit으로 필수 suite PASS |
| Community Tested | 재현 metadata가 있는 외부 report |
| Untested | 실행 evidence 없음 |

결과는 `docs/compatibility/<distribution>/<version>.md`에 기록한다.

- PASS: mandatory scenario 전체 통과
- PARTIAL: core PASS, optional/network 제한 존재
- FAIL: required API 또는 core scenario 실패
- INCONCLUSIVE: evidence 또는 환경 문제로 판정 불가

## 16. 실패 분류

test failure를 다음으로 분류한다.

- Product defect
- Test defect
- Fixture defect
- Environment/runtime defect
- Cluster incompatibility
- Credential/permission failure
- Network dependency failure
- Inconclusive

환경 실패를 제품 PASS로 바꾸지 않는다. 실패 분류와 원본 evidence를 보존한다.

## 17. Test 완료 정의

Task test는 다음을 모두 만족해야 완료된다.

- requirement와 scenario ID가 연결된다.
- positive/negative 경로가 있다.
- 실행 명령과 예상 exit가 명시된다.
- 재현에 필요한 environment metadata가 있다.
- artifact와 redaction이 검증된다.
- cleanup 결과가 확인된다.
- 평가서가 evaluated commit을 기준으로 PASS다.

## 참고 자료

- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
