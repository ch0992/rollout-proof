---
task_id: P0-004
title: "CI unit/build workflow 생성"
status: draft
size: S
milestone: Phase 0
epic: P0-E1
issue: null
branch: "feat/<issue-number>-p0-004-ci-unit-build"
work_order_version: 1
evaluation_document: ../evaluations/P0-004-evaluation.md
---

# P0-004 작업지시서: CI unit/build workflow 생성

## 1. 목적

CI unit/build workflow 생성을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-CI-001`
- 엔지니어링 구현 스펙 §15.1 CI pipeline

## 4. 작업 범위

- pull request와 main push CI
- Go 1.26 setup
- module verify, test, vet, build
- least-privilege workflow permissions

## 5. 제외 범위

- kind E2E
- release/tag workflow
- SBOM/signing

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `.github/workflows/ci.yml` | 생성 또는 수정 | CI unit/build workflow 생성 |
| `docs/development.md` | 생성 또는 수정 | CI unit/build workflow 생성 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

third-party action은 immutable commit SHA로 pin하고 최소 permissions를 선언한다. job은 checkout 후 module verification, test, vet, build 순으로 수행한다.

## 8. Acceptance Criteria

- [ ] AC-1: workflow가 pull_request와 main push에서 실행된다.
- [ ] AC-2: Go 1.26 계열을 사용한다.
- [ ] AC-3: `go mod verify`, `go test ./...`, `go vet ./...`, CLI build가 모두 gate다.
- [ ] AC-4: workflow permissions가 read-only 최소 권한이다.
- [ ] AC-5: YAML syntax validation이 통과한다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml")'
go mod verify && go test ./... && go vet ./...
go build ./cmd/rollout-proof
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `feat/<issue-number>-p0-004-ci-unit-build`
- Commit prefix: `[P0-004]`
- PR title: `[P0-004] CI unit/build workflow 생성`
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

