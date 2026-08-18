---
task_id: P0-010
title: "Atomic report writer 구현"
status: backlog
size: XS
milestone: Phase 0
epic: P0-E2
issue: https://github.com/ch0992/rollout-proof/issues/16
branch: "feat/16-p0-010-atomic-report-writer"
work_order_version: 1
evaluation_document: ../evaluations/P0-010-evaluation.md
---

# P0-010 작업지시서: Atomic report writer 구현

## 1. 목적

Atomic report writer 구현을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-REPORT-002`
- 엔지니어링 구현 스펙 §12 Report와 파일 I/O

## 4. 작업 범위

- 같은 directory 임시 파일
- flush/close 후 atomic rename
- permission과 cleanup 오류 전파

## 5. 제외 범위

- stdout writer
- report encoding
- cross-filesystem rename fallback

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `internal/report/writer.go` | 생성 또는 수정 | Atomic report writer 구현 |
| `internal/report/writer_test.go` | 생성 또는 수정 | Atomic report writer 구현 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

target file과 같은 directory에 temporary file을 만들고 성공한 경우에만 rename한다. 실패한 write는 기존 target을 손상시키지 않고 임시 파일을 정리한다.

## 8. Acceptance Criteria

- [ ] AC-1: 성공 시 target에 전체 byte가 기록된다.
- [ ] AC-2: write 실패 시 기존 target 내용이 보존된다.
- [ ] AC-3: 실패 후 temporary file이 남지 않는다.
- [ ] AC-4: permission/rename 오류가 wrapping되어 caller에 반환된다.
- [ ] AC-5: unit test가 실제 temporary directory에서 동작한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
go test ./internal/report -run 'Test.*Atomic'
go test -race ./internal/report
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/16-p0-010-atomic-report-writer`
- Commit prefix: `[P0-010]`
- PR title: `[P0-010] Atomic report writer 구현`
- PR 본문: `Closes #16`와 작업지시서/평가서 링크
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

