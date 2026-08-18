# RolloutProof 로컬 개발 인프라 검증 계약

> 상태: 0.1-draft
> 목적: Mac 개발환경 구축 후 실제 개발과 Kubernetes E2E에 사용할 수 있는지 자동 판정
> 환경 구성: [Mac 로컬 개발 환경](./development-environment.md)
> 제품 테스트: [테스트 전략 및 검증 계획](./test-strategy.md)

## 1. 문서 경계

이 문서는 다음 질문에 답한다.

> Environment as Code로 구축된 Mac·Colima·Docker·kind 환경이 올바르고 안전하게 동작하는가?

RolloutProof 제품 기능의 정확성은 검증하지 않는다. 제품 test가 실행되기 위한 기반 환경의 readiness만 검증한다.

## 2. 단일 진입점

AI와 개발자는 다음 명령 하나로 전체 환경을 검증할 수 있어야 한다.

```bash
make env-verify
```

세부 명령:

```bash
make env-verify-static       # 선언 파일과 version manifest
make env-verify-tools        # 설치 도구와 architecture
make env-verify-runtime      # Colima와 Docker
make env-verify-cluster      # kind와 Kubernetes
make env-verify-capability   # API, RBAC, DNS, image load
make env-verify-isolation    # kubeconfig와 기존 환경 보호
make env-verify-idempotency  # 반복 적용 안전성
make env-verify-cleanup      # opt-in 생성/삭제 검증
make env-report              # JSON/Markdown evidence 생성
```

기본 `env-verify`는 read-only 검사와 test namespace 내부 smoke만 수행한다. runtime/cluster 삭제를 포함하는 cleanup 검증은 별도 opt-in으로 실행한다.

## 3. 검증 단계

```text
V0 Static
  → V1 Host Tools
  → V2 Container Runtime
  → V3 Kubernetes Control Plane
  → V4 Cluster Capability
  → V5 Functional Smoke
  → V6 Isolation/Idempotency
  → V7 Cleanup/Recovery
```

앞 단계가 FAIL이면 의존하는 다음 단계는 실행하지 않고 `BLOCKED`로 기록한다.

## 4. 판정 상태

| 상태 | 의미 |
|---|---|
| PASS | 검증 조건을 충족함 |
| FAIL | 환경 또는 계약 위반이 재현됨 |
| BLOCKED | 선행 검증 실패로 실행하지 못함 |
| SKIPPED | 현재 mode에서 의도적으로 제외됨 |
| INCONCLUSIVE | 증거 부족 또는 외부 일시 오류로 판정 불가 |

전체 결과는 mandatory check가 모두 PASS일 때만 `READY`다. INCONCLUSIVE를 READY로 취급하지 않는다.

## 5. V0 선언 파일 검증

| Check ID | 대상 | PASS 조건 | 필수 |
|---|---|---|---|
| ENV-STATIC-001 | `Brewfile` | 문법과 필수 package 선언 유효 | 필수 |
| ENV-STATIC-002 | `mise.toml` | schema와 pin된 tool version 유효 | 필수 |
| ENV-STATIC-003 | Colima config | Docker runtime, Kubernetes disabled | 필수 |
| ENV-STATIC-004 | kind config | control-plane 1, worker 1, 유효 schema | 필수 |
| ENV-STATIC-005 | version manifest | K8s 1.34~1.36 tag와 digest 존재 | 필수 |
| ENV-STATIC-006 | script lint | syntax 검사와 executable bit | 필수 |

floating `latest`, digest 없는 kind node image, 전역 경로 cleanup은 FAIL이다.

## 6. V1 Host Tool 검증

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-HOST-001 | macOS architecture | `arm64` 또는 지원 `amd64` |
| ENV-HOST-002 | disk | `.work`와 Colima VM에 필요한 여유 공간 |
| ENV-TOOL-001 | Go | 승인된 1.26 patch 범위 |
| ENV-TOOL-002 | Colima | 승인된 version 범위 |
| ENV-TOOL-003 | Docker CLI | daemon API와 호환 |
| ENV-TOOL-004 | kind | manifest의 승인 version |
| ENV-TOOL-005 | kubectl | API server ±1 minor |
| ENV-TOOL-006 | Git/gh/jq/make | 명령 실행 가능 |

검사는 설치를 변경하지 않는다. 누락 시 설치 명령과 예상 version을 출력한다.

## 7. V2 Container Runtime 검증

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-RUNTIME-001 | Colima profile | 이름이 `rolloutproof`이고 running |
| ENV-RUNTIME-002 | runtime type | Docker, Colima Kubernetes disabled |
| ENV-RUNTIME-003 | allocation | CPU 4, memory 8 GiB, disk 60 GiB 이상 또는 승인 override |
| ENV-RUNTIME-004 | Docker context | 명시된 RolloutProof context와 일치 |
| ENV-RUNTIME-005 | Docker ping | daemon 응답 성공 |
| ENV-RUNTIME-006 | container smoke | 작은 pinned image 실행/종료 성공 |
| ENV-RUNTIME-007 | architecture | host와 node image architecture 호환 |

기존 default Colima profile이나 Docker Desktop context를 수정해서 PASS를 만들면 안 된다.

## 8. V3 Kubernetes Control Plane 검증

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-KIND-001 | cluster name | 허용된 `rolloutproof-*` 이름 |
| ENV-KIND-002 | kubeconfig | `.work/kubeconfig` 사용 |
| ENV-K8S-001 | API server | timeout 안에 `/readyz` 성공 |
| ENV-K8S-002 | version | 선택한 minor/patch와 manifest 일치 |
| ENV-K8S-003 | nodes | control-plane 1, worker 1 모두 Ready |
| ENV-K8S-004 | system Pods | 필수 kube-system Pod Ready |
| ENV-K8S-005 | EndpointSlice | `discovery.k8s.io/v1` discover 가능 |
| ENV-K8S-006 | watch | list/watch round trip 성공 |

API server 접근 실패를 제품 오류로 분류하지 않는다.

## 9. V4 Cluster Capability 검증

### 9.1 API와 RBAC

- Deployment/ReplicaSet get/list/watch
- Pod get/list/watch
- Service get/list
- EndpointSlice get/list/watch
- Event API 또는 fallback
- SelfSubjectAccessReview

필수 API나 namespace-scoped test 권한이 없으면 FAIL이다.

### 9.2 DNS와 Network

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-NET-001 | CoreDNS | test Pod에서 Service DNS resolve |
| ENV-NET-002 | ClusterIP | test client에서 test server 요청 성공 |
| ENV-NET-003 | Pod-to-Pod | worker 간 요청 성공 |
| ENV-NET-004 | Host path | port-forward를 통한 host 요청 성공 |
| ENV-NET-005 | repeated request | 지정 횟수 동안 예상치 못한 reset 없음 |

### 9.3 Image Path

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-IMAGE-001 | local build | native fixture image build 성공 |
| ENV-IMAGE-002 | kind load | 대상 cluster에 image load 성공 |
| ENV-IMAGE-003 | scheduling | worker에서 local image Pod 실행 |
| ENV-IMAGE-004 | stale prevention | commit/run ID tag 확인 |

## 10. V5 Functional Smoke

환경 smoke는 최소 fixture만 사용한다.

1. 전용 namespace 생성
2. HTTP echo/health server Deployment 생성
3. ClusterIP Service 생성
4. Pod Ready 대기
5. EndpointSlice address/ready 확인
6. cluster 내부 DNS/HTTP 요청
7. host port-forward HTTP 요청
8. Deployment image revision 변경
9. ReplicaSet/Pod/EndpointSlice watch event 확인
10. namespace cleanup

이 smoke는 RolloutProof analyzer 판정을 검증하지 않는다. 기반 lifecycle과 network 관측 가능성만 확인한다.

## 11. V6 격리 검증

| Check ID | 검증 | PASS 조건 |
|---|---|---|
| ENV-ISOLATION-001 | global kubeconfig | 실행 전후 current-context 동일 |
| ENV-ISOLATION-002 | Docker context | 승인된 전환 외 기존 context 보존 |
| ENV-ISOLATION-003 | kind clusters | unrelated cluster 목록과 상태 보존 |
| ENV-ISOLATION-004 | Colima profiles | default/타 project profile 보존 |
| ENV-ISOLATION-005 | filesystem | `.work` 밖 파일 생성/삭제 없음 |
| ENV-ISOLATION-006 | namespace | test namespace 밖 mutation 없음 |

검증 전 snapshot과 검증 후 snapshot을 비교하고 차이를 report에 기록한다.

## 12. V6 멱등성 검증

같은 commit과 config로 다음을 두 번 실행한다.

```bash
make runtime-up
make cluster-up K8S_MINOR=1.36
make env-verify
```

두 번째 실행의 PASS 조건:

- 중복 Colima profile이나 kind cluster를 만들지 않는다.
- version/config가 같으면 재사용한다.
- config drift가 있으면 암묵적 재생성 대신 diff와 복구 명령을 출력한다.
- global context와 unrelated resource를 변경하지 않는다.
- 결과가 첫 실행과 의미상 동일하다.

## 13. V7 Cleanup과 Recovery

cleanup 검증은 다음 opt-in 없이는 실행하지 않는다.

```text
ROLLOUTPROOF_ENV_ALLOW_CLEANUP_TEST=true
```

검증 항목:

- 지정 test namespace만 삭제
- 지정 `rolloutproof-*` kind cluster만 삭제
- runtime은 기본적으로 stop만 수행
- Colima profile delete는 별도 명시적 승인 필요
- 중간 실패 후 다시 cleanup 가능
- 남은 resource와 수동 복구 명령 출력
- unrelated cluster/profile/context 보존

## 14. Failure Injection

환경 검증 자체가 실패를 찾는지 다음 조건으로 확인한다.

- Docker daemon 중지
- 잘못된 Docker context
- 지원하지 않는 kubectl version
- digest와 다른 kind node version
- worker NotReady
- CoreDNS 실패
- image load 누락
- 잘못된 kubeconfig/context
- test namespace 권한 부족
- port-forward 조기 종료

failure injection은 자동 복구와 분리한다. 검출 test가 사용자 환경을 임의로 고치지 않는다.

## 15. Evidence Artifact

기본 경로:

```text
.work/artifacts/environment/<run-id>/
├── environment-report.json
├── environment-report.md
├── commands.jsonl
├── before-snapshot.json
├── after-snapshot.json
└── sanitized-diagnostics/
```

필수 report field:

```text
schemaVersion
runId
commit
startedAt/finishedAt
hostOS/architecture
toolVersions
containerProvider/context
clusterName/serverVersion
kubeconfigPathCategory
checks[]
overallVerdict
failedChecks[]
blockedChecks[]
recoveryCommands[]
artifactChecksums
```

token, certificate, kubeconfig content, registry credential와 URL query는 저장하지 않는다.

## 16. Exit Code

| Exit | 의미 |
|---:|---|
| 0 | READY, mandatory check 전체 PASS |
| 2 | 사용법 또는 config 오류 |
| 3 | 필수 도구 누락/incompatible version |
| 4 | runtime 검증 실패 |
| 5 | Kubernetes 검증 실패 |
| 6 | isolation/safety 위반 |
| 7 | cleanup/recovery 실패 |
| 10 | INCONCLUSIVE 또는 외부 일시 오류 |

machine-readable report는 exit code와 같은 verdict를 가져야 한다.

## 17. AI 실행 계약

AI는 다음 순서로 실행한다.

1. `make env-verify-static`
2. `make env-check`
3. 변경 예정 내용을 사용자에게 요약
4. 승인된 경우에만 bootstrap/apply
5. `make runtime-up`
6. `make cluster-up`
7. `make env-verify`
8. 실패 check ID와 recovery command 기록
9. `make env-report`
10. cleanup 여부를 명시적으로 결정

AI는 FAIL을 자동으로 숨기거나 destructive reset으로 해결하지 않는다. 같은 check가 두 번 실패하면 환경 drift와 tool compatibility를 먼저 조사한다.

## 18. 환경 Ready 완료 조건

로컬 인프라는 다음을 모두 만족해야 Ready다.

1. V0~V6 mandatory check PASS
2. functional smoke PASS
3. 두 번째 적용/검증도 PASS
4. global kubeconfig와 unrelated 환경 변화 없음
5. JSON/Markdown report 생성
6. cleanup opt-in test를 release 전 최소 1회 PASS
7. Apple Silicon Colima 경로 PASS
8. Docker Desktop 대체 경로는 별도 evidence 상태로 기록

