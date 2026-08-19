---
task_id: P0-001
title: "Go module과 CLI entrypoint 생성"
status: completed
size: XS
milestone: Phase 0
epic: P0-E1
issue: https://github.com/ch0992/rollout-proof/issues/7
branch: "feat/7-p0-001-go-module-entrypoint"
base_commit: 0fa2bf889d2da04e2e41ffdec1f31fbaaf4edc3f
work_order_version: 1
evaluation_document: ../evaluations/P0-001-evaluation.md
---

# P0-001 작업지시서: Go module과 CLI entrypoint 생성

## 1. 목적

Go module과 CLI entrypoint 생성을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- GitHub repository owner와 Go module path는 `ch0992`, `github.com/ch0992/rollout-proof`로 확정됐다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-FOUNDATION-001`
- 엔지니어링 구현 스펙 §2 핵심 기술 결정
- 엔지니어링 구현 스펙 §5 저장소와 패키지 구조
- ADR-0001 제품명

## 4. 작업 범위

- Go 1.26 module 선언
- `cmd/rollout-proof` entrypoint 생성
- build metadata 없이도 실행 가능한 최소 main 구성

## 5. 제외 범위

- Cobra command tree
- version 출력 형식
- Kubernetes/HTTP 의존성

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `go.mod` | 생성 또는 수정 | Go module과 CLI entrypoint 생성 |
| `cmd/rollout-proof/main.go` | 생성 또는 수정 | Go module과 CLI entrypoint 생성 |
| `cmd/rollout-proof/main_test.go` | 생성 또는 수정 | Go module과 CLI entrypoint 생성 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

module path는 `github.com/ch0992/rollout-proof`를 사용한다. main은 package logic을 포함하지 않으며 이후 root command를 호출할 wiring 위치만 제공한다.

## 8. Acceptance Criteria

- [x] AC-1: `go.mod`가 Go 1.26을 선언한다.
- [x] AC-2: `go build ./cmd/rollout-proof`가 성공한다.
- [x] AC-3: `go test ./...`가 성공한다.
- [x] AC-4: main에 domain 또는 adapter logic이 없다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go mod tidy
go test ./...
go build ./cmd/rollout-proof
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/7-p0-001-go-module-entrypoint`
- Commit prefix: `[P0-001]`
- PR title: `[P0-001] Go module과 CLI entrypoint 생성`
- PR 본문: `Closes #7`와 작업지시서/평가서 링크
- merge 조건: 평가서 PASS와 required CI PASS

## 13. 완료 보고 형식

```text
Implemented:
Changed files:
Verification:
Acceptance evidence:
Known limitations:
Commit SHA:
```
