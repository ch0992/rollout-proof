---
task_id: P0-003
title: "Cobra root command와 출력 channel 분리"
status: draft
size: S
milestone: Phase 0
epic: P0-E1
issue: null
branch: "feat/<issue-number>-p0-003-cobra-root"
work_order_version: 1
evaluation_document: ../evaluations/P0-003-evaluation.md
---

# P0-003 작업지시서: Cobra root command와 출력 channel 분리

## 1. 목적

Cobra root command와 출력 channel 분리을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-CLI-001`
- 엔지니어링 구현 스펙 §6.1 Cobra 구성
- ADR-0001 제품명

## 4. 작업 범위

- Cobra root command
- `version` command
- stdout/stderr writer 주입
- usage error 반환

## 5. 제외 범위

- gate/observe command
- structured logging
- config loading

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `go.mod` | 생성 또는 수정 | Cobra root command와 출력 channel 분리 |
| `cmd/rollout-proof/main.go` | 생성 또는 수정 | Cobra root command와 출력 channel 분리 |
| `internal/cli/root.go` | 생성 또는 수정 | Cobra root command와 출력 channel 분리 |
| `internal/cli/root_test.go` | 생성 또는 수정 | Cobra root command와 출력 channel 분리 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

root constructor는 stdout/stderr를 인자로 받고 test에서 buffer로 대체할 수 있어야 한다. library package는 `os.Exit`와 `log.Fatal`을 호출하지 않는다.

## 8. Acceptance Criteria

- [ ] AC-1: `rollout-proof --help`에 제품명과 command가 표시된다.
- [ ] AC-2: `rollout-proof version`이 stdout에 version을 출력하고 exit 0이다.
- [ ] AC-3: 잘못된 command는 non-zero이며 오류가 stderr로만 출력된다.
- [ ] AC-4: test가 process spawn 없이 출력 channel을 검증한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/cli ./cmd/rollout-proof
go run ./cmd/rollout-proof version
go run ./cmd/rollout-proof unknown-command
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/<issue-number>-p0-003-cobra-root`
- Commit prefix: `[P0-003]`
- PR title: `[P0-003] Cobra root command와 출력 channel 분리`
- PR 본문: `Closes #<issue-number>`와 작업지시서/평가서 링크
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

