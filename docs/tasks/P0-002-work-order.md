---
task_id: P0-002
title: "개발 기본 Make target 정의"
status: ready
size: XS
milestone: Phase 0
epic: P0-E1
issue: https://github.com/ch0992/rollout-proof/issues/8
branch: "feat/8-p0-002-make-targets"
base_commit: 011b9a150f09164c1abf35e85dde08188fdf92ec
work_order_version: 1
evaluation_document: ../evaluations/P0-002-evaluation.md
---

# P0-002 작업지시서: 개발 기본 Make target 정의

## 1. 목적

개발 기본 Make target 정의을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-FOUNDATION-002`
- 엔지니어링 구현 스펙 §14 로컬 개발 workflow

## 4. 작업 범위

- `build`, `test`, `test-race`, `lint` target
- target이 실행하는 실제 Go command 문서화
- 기본 target help 제공

## 5. 제외 범위

- kind cluster target
- release packaging
- CI workflow

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `Makefile` | 생성 또는 수정 | 개발 기본 Make target 정의 |
| `docs/development.md` | 생성 또는 수정 | 개발 기본 Make target 정의 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

Makefile은 얇은 command alias만 제공한다. 로컬 전용 절대 경로와 shell-specific state를 사용하지 않는다.

## 8. Acceptance Criteria

- [ ] AC-1: `make build`가 CLI binary를 build한다.
- [ ] AC-2: `make test`가 `go test ./...`를 실행한다.
- [ ] AC-3: `make test-race`가 race detector를 사용한다.
- [ ] AC-4: `make lint`가 현재 단계에 존재하는 표준 정적 검사를 실행한다.
- [ ] AC-5: `make help`가 target 설명을 출력한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
make help
make build test
make test-race lint
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/8-p0-002-make-targets`
- Commit prefix: `[P0-002]`
- PR title: `[P0-002] 개발 기본 Make target 정의`
- PR 본문: `Closes #8`와 작업지시서/평가서 링크
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
