# RolloutProof 문서 안내

> 제품 목표: 효용성 평가 9/10 수준의 release-time service continuity gate

## 문서 구조

| 문서 | 역할 | 상태 |
|---|---|---|
| [제품 스펙](./product-spec.md) | CLI, 상태 머신, 데이터 모델, 보안, 승인 기준 | 0.1-draft |
| [엔지니어링 구현 스펙](./implementation-spec.md) | 언어, 라이브러리, 내부 구조, 테스트, 빌드 및 릴리스 방법론 | 0.1-draft |
| [AI 개발 운영 지침](./ai-development-playbook.md) | 이슈 크기, token budget, 구현·평가·재작업 workflow | 0.1-draft |
| [Phase 0 Task 분해](./phase-0-task-breakdown.md) | 최초 기술 검증을 위한 Epic과 atomic Task backlog | backlog draft |
| [Phase 0 Task 문서 인덱스](./task-index.md) | 36개 작업지시서와 평가서의 연결 상태 | Draft |
| [Issue 및 형상관리 Workflow](./version-control-workflow.md) | Issue–branch–commit–PR–평가 traceability | 0.1-draft |
| [ADR-0001 제품명](./adr/0001-product-name.md) | RolloutProof brand와 저장소/CLI 명명 규칙 | Accepted |
| [작업지시서 템플릿](./templates/task-work-order.md) | Task별 구현 범위·AC·형상관리 계약 | Template |
| [평가서 템플릿](./templates/task-evaluation.md) | 구현 전 검증 설계와 구현 후 독립 평가 | Template |
| [초기 기획서](./initial-product-plan.md) | 제품 정의, 기능 범위, 아키텍처, 단계별 로드맵 | Revision 3 |
| [실제 효용성 평가](./utility-evaluation.md) | 사용자 가치, 한계, 효용성 점수, 검증 가설 | Revision 3 |
| [오픈소스 벤치마킹](./benchmarking.md) | 경쟁 및 인접 프로젝트 조사 | 조사 기준 2026-08-18 |

## 현재 확정된 방향

`rollout-proof`는 모든 Kubernetes 장애를 분석하는 범용 observability 도구가 아니다.

> Kubernetes Deployment의 새 revision을 기다리면서 서비스 연속성을 검증하고, 요청 실패를 Pod 및 EndpointSlice lifecycle과 연결해 설명하는 단일 CLI다.

### 제품 원칙

- 사용자는 Go 단일 binary 하나만 설치한다.
- 기본 기능에 Helm, CRD, controller, database가 필요하지 않다.
- 핵심 workflow는 `gate --wait-for-revision`이다.
- MVP-A는 agentless external HTTP probe를 사용한다.
- Production은 Kubernetes read-only gate/observe를 우선한다.
- Internal probe는 선택적 ephemeral Pod 방식의 MVP-B다.
- 판정은 Observation, Correlation, Finding, Confidence로 설명한다.
- 자동 root cause 확정이나 자동 rollback은 하지 않는다.

### 구현 기준

- Go 1.26 계열과 client-go를 사용하는 단일 프로세스 CLI로 구현한다.
- Kubernetes 1.34~1.36을 최초 compatibility matrix로 검증한다.
- 직접 LIST/WATCH supervisor, 표준 `net/http`/`httptrace`, 단일 timeline aggregator를 사용한다.
- domain logic을 외부 I/O와 분리하고 kind E2E로 실제 rollout을 검증한다.
- 상세 기준은 [엔지니어링 구현 스펙](./implementation-spec.md)을 따른다.

## 9점 효용성 목표

9점은 기능의 수가 아니라 다음 사용자 경험을 의미한다.

```bash
brew install rollout-proof
rollout-proof gate deployment/api
```

이 두 명령만으로 설정 발견, baseline, 새 revision 대기, HTTP probe, lifecycle timeline, 판정 및 CI artifact 생성까지 이어지는 것을 목표로 한다.

### 9점 달성을 위한 필수 축

1. `gate --wait-for-revision`
2. 새 연결 및 Keep-Alive connection profile
3. Live timeline과 evidence-based `explain`
4. `.rollout-proof.yaml` policy profile
5. 여러 개의 안전한 GET/HEAD probe
6. JSON, Markdown, JUnit 및 GitHub Action artifact
7. 이전 report와 현재 report의 regression 비교
8. 단일 binary, container 및 GitHub Action 배포
9. Production-safe 기본값과 명확한 관측 범위

## 단계 구분

```text
Phase 0
  기술 가설 검증

MVP-A Core
  Agentless gate, connection profile, timeline, explain

MVP-A Adoption
  Profile, multi-probe, CI output, GitHub Action, container

MVP-B
  Optional ephemeral internal probe, internal/external 비교

Phase 4
  Report diff, 진단 bundle, framework guide, patch preview

Phase 5
  Prometheus, access log, OTel, gRPC, Gateway, Service Mesh
```

## 범위 변경 규칙

새 기능은 다음 질문에 모두 `예`인 경우에만 초기 로드맵에 추가한다.

1. Deployment rollout의 서비스 연속성과 직접 관련되는가?
2. 단일 binary 또는 선택적 ephemeral probe 원칙을 유지하는가?
3. 설치 없이도 기본 기능이 계속 동작하는가?
4. 기존 report schema와 timeline에 자연스럽게 들어가는가?
5. 실제 사용자 검증 또는 재현 fixture로 가치를 측정할 수 있는가?

하나라도 아니면 Phase 5 이후 또는 별도 프로젝트로 분리한다.
