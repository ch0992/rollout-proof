# Phase 0 AI 개발 Task 분해

> 상태: backlog draft  
> 운영 기준: [AI 개발 운영 지침](./ai-development-playbook.md)  
> 기술 기준: [엔지니어링 구현 스펙](./implementation-spec.md)

## 1. Phase 0 목표

Phase 0의 목표는 제품 전체를 만드는 것이 아니다.

> 실제 Kubernetes rollout에서 EndpointSlice/Pod lifecycle event와 HTTP 실패를 하나의 monotonic timeline으로 반복 재현할 수 있는지 증명한다.

## 2. Epic 구성

| Epic | 결과 | 선행 Epic |
|---|---|---|
| P0-E1 Foundation | 재현 가능한 Go 개발/CI 골격 | 없음 |
| P0-E2 Domain Contract | event와 report 최소 계약 | E1 |
| P0-E3 Kubernetes Observation | LIST/WATCH event 수집 | E2 |
| P0-E4 HTTP Observation | new/keep-alive probe event 수집 | E2 |
| P0-E5 Timeline Prototype | 두 관측 stream의 통합 report | E3, E4 |
| P0-E6 Reproduction | kind fixture 반복 검증 | E5 |

## 3. Task backlog

### P0-E1 Foundation

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-001 | XS | Go 1.26 module과 CLI entrypoint 생성 | `rollout-proof version` 실행 |
| P0-002 | XS | Makefile의 build/test/lint target 정의 | clean environment에서 명령 성공 |
| P0-003 | S | Cobra root command와 stdout/stderr 분리 | help/version snapshot |
| P0-004 | S | CI unit/build workflow 생성 | Linux build와 unit test PASS |
| P0-005 | XS | ADR-0002 Go 단일 프로세스 결정 기록 | ADR lint/checklist PASS |

### P0-E2 Domain Contract

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-006 | S | Source, Kind, ObjectRef, Event domain type | compile-time typed payload test |
| P0-007 | S | fake/real clock interface와 elapsed time | sleep 없는 deterministic test |
| P0-008 | S | 단일 event sequencer | concurrent producer에서도 sequence 유일성 |
| P0-009 | S | v1alpha1 최소 report DTO | golden JSON 일치 |
| P0-010 | XS | atomic report writer | 실패 시 partial target file 없음 |

### P0-E3 Kubernetes Observation

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-011 | S | kubeconfig/rest.Config loader | context/namespace precedence test |
| P0-012 | S | Deployment GET과 selector discovery | fake API fixture test |
| P0-013 | M | generic LIST/WATCH supervisor interface | initial list와 watch event 전달 |
| P0-014 | S | EOF reconnect와 jitter backoff | fake watch server test |
| P0-015 | M | 410 Gone relist와 gap event | stale resourceVersion scenario PASS |
| P0-016 | S | Pod watch adapter | typed Pod lifecycle event golden |
| P0-017 | S | EndpointSlice watch adapter | endpoint add/remove event golden |
| P0-018 | XS | ADR-0004 watch supervisor 결정 기록 | 구현과 ADR 일치 |

### P0-E4 HTTP Observation

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-019 | S | probe request/result domain type | JSON-independent domain test |
| P0-020 | S | bounded probe scheduler | backlog 상한과 lag observation |
| P0-021 | S | new-connection transport | 연결 reuse 0회 |
| P0-022 | S | keep-alive transport | `GotConnInfo.Reused` 증거 |
| P0-023 | M | DNS/TCP/TLS/timeout typed classifier | httptest/custom listener table test |
| P0-024 | S | HTTP status policy | 허용/실패 status table test |
| P0-025 | XS | ADR-0006 connection profile 기록 | profile contract와 일치 |

### P0-E5 Timeline Prototype

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-026 | M | watch와 probe producer를 event bus에 연결 | 취소와 channel close test |
| P0-027 | S | canonical timeline ordering | mixed source golden timeline |
| P0-028 | S | 최소 terminal renderer | stdout snapshot |
| P0-029 | S | 최소 JSON report renderer | schema golden |
| P0-030 | M | observe prototype command wiring | fake adapters end-to-end PASS |

### P0-E6 Reproduction

| ID | 크기 | Task | 핵심 검증 |
|---|---|---|---|
| P0-031 | S | kind cluster bootstrap | repeatable create/delete |
| P0-032 | M | 정상 rollout fixture | 정상 timeline 생성 |
| P0-033 | M | readiness/endpoint gap fixture | gap과 HTTP 실패 동시 재현 |
| P0-034 | M | 실제 cluster observe E2E | terminal/JSON event 일치 |
| P0-035 | S | 10회 반복 harness | detection/reproduction 비율 산출 |
| P0-036 | S | Phase 0 결과와 parameter ADR | go/no-go evidence 기록 |

## 4. Dependency path

```text
P0-001 → 003 → 006 → 007 → 008 → 009
                         ├→ 013 → 014 → 015 → 016/017 ┐
                         └→ 019 → 020 → 021/022/023 ──┼→ 026 → 027 → 030
                                                      └→ 031 → 032/033 → 034 → 035 → 036
```

독립 가능한 Task는 병렬로 수행할 수 있지만 같은 package와 public interface를 동시에 수정하지 않는다.

## 5. Phase 0 평가 gate

다음이 모두 PASS여야 MVP-A1로 이동한다.

1. 정상 rollout 10회에서 timeline 누락이 없다.
2. 결함 fixture 10회에서 HTTP 실패와 EndpointSlice/Pod event가 모두 기록된다.
3. process 내 event ordering이 deterministic하다.
4. WATCH EOF와 410 이후에도 report가 생성된다.
5. new profile은 connection reuse가 없고 keep-alive profile은 reuse 증거가 있다.
6. terminal과 JSON의 event/verdict source가 동일하다.
7. 실패 결과를 재현하는 command와 fixture가 repository에 남아 있다.
8. Phase 0에서 확정하지 못한 결과는 PASS가 아니라 INCONCLUSIVE로 기록된다.

## 6. 첫 실행 순서

처음에는 `P0-001`부터 `P0-010`까지 순서대로 생성하되 한꺼번에 구현하지 않는다. 각 Task가 평가 PASS를 받은 뒤 다음 dependent Task를 `Ready`로 전환한다. Kubernetes와 HTTP branch는 domain contract가 확정된 이후 병렬 진행할 수 있다.
