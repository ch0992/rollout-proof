# RolloutProof 개발 명령

> Requirement: `ENG-FOUNDATION-002`

저장소 루트의 Makefile은 반복되는 Go 명령을 얇은 target으로 제공한다. 실제 build와 검증은 Go 표준 도구가 수행하며 shell 전역 상태나 로컬 절대경로에 의존하지 않는다.

## 기본 workflow

```bash
make help
make build
make test
make test-race
make lint
```

## 명령 매핑

| Make target | 실제 명령 | 결과 |
|---|---|---|
| `make build` | `go build -o .work/bin/rollout-proof ./cmd/rollout-proof` | `.work/bin/rollout-proof` 생성 |
| `make test` | `go test ./...` | 전체 Go package test |
| `make test-race` | `go test -race ./...` | race detector를 사용한 전체 test |
| `make lint` | `go vet ./...` | Go 표준 정적 분석 |
| `make help` | Makefile의 `##` 설명 목록 출력 | 사용 가능한 개발·환경 target 확인 |

Go 1.26 toolchain은 환경 Runbook의 `make env-bootstrap APPLY=true`로 설치한다. build artifact는 git에서 제외된 `.work` 아래에만 생성된다.

kind cluster, E2E, release packaging 및 CI workflow는 각 후속 Task에서 별도로 제공한다.
