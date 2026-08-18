# ADR-0001: 제품명을 RolloutProof로 확정

- 상태: Accepted
- 결정일: 2026-08-18
- 결정 범위: 제품 brand, repository, CLI 및 파일 이름

## Context

구현 Task, GitHub Issue, branch, Go module, binary, container image 및 report artifact를 연결하기 전에 안정적인 제품 식별자가 필요하다. 이름은 Kubernetes rollout의 서비스 연속성 검증이라는 범위와 evidence 기반 판정이라는 차별점을 함께 표현해야 한다.

## Decision

다음 이름을 사용한다.

| 대상 | 확정 이름 |
|---|---|
| 제품 brand | `RolloutProof` |
| GitHub repository | `rollout-proof` |
| CLI binary | `rollout-proof` |
| 기본 config 파일 | `.rollout-proof.yaml` |
| container repository | `rollout-proof` |
| 문서 내 일반 표기 | `RolloutProof` |

Go module은 GitHub owner가 확정된 후 `github.com/<owner>/rollout-proof`로 정한다. container image는 같은 owner를 사용해 `ghcr.io/<owner>/rollout-proof`로 정한다.

## API identifier 보류

Kubernetes annotation prefix와 공개 config/report API group은 소유한 DNS domain을 사용해야 한다. 현재 문서의 `rollout-proof.io`는 제품명 확정과 별개의 provisional identifier이며 공개 계약으로 확정하지 않는다.

다음 순서로 별도 ADR에서 결정한다.

1. GitHub owner를 확정한다.
2. 제품 domain의 확보 가능성과 소유권을 확인한다.
3. annotation prefix, config `apiVersion`, report `schemaVersion`을 함께 확정한다.
4. 공개 release 전에 provisional identifier를 일괄 교체한다.

## Consequences

- Issue, branch, commit 및 PR에서 `RolloutProof`/`rollout-proof`를 일관되게 사용할 수 있다.
- 제품 범위가 향후 Deployment 외 rollout으로 확장되어도 이름을 유지할 수 있다.
- API identifier는 GitHub repository 생성 전에 최종 확정할 수 없으며 별도 blocking decision으로 관리한다.
- 상표권과 domain 확보 여부는 공개 release 전 별도 확인이 필요하다.

