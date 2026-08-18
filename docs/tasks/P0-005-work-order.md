---
task_id: P0-005
title: "ADR-0002 Go 단일 프로세스 결정 기록"
status: backlog
size: XS
milestone: Phase 0
epic: P0-E1
issue: https://github.com/ch0992/rollout-proof/issues/11
branch: "docs/11-p0-005-adr-single-process"
work_order_version: 1
evaluation_document: ../evaluations/P0-005-evaluation.md
---

# P0-005 작업지시서: ADR-0002 Go 단일 프로세스 결정 기록

## 1. 목적

ADR-0002 Go 단일 프로세스 결정 기록을 독립적으로 구현하고 후속 Task가 의존할 수 있는 검증된 계약을 만든다.

## 2. 선행조건

- Phase 0 dependency graph의 선행 Task가 PASS 상태여야 한다.
- 작업 시작 시 Issue URL과 base commit을 front matter에 기록한다.

## 3. 참조 계약

- Requirement ID: `ENG-ARCH-001`
- 엔지니어링 구현 스펙 §3 설계 원칙
- 엔지니어링 구현 스펙 §4 프로세스 아키텍처

## 4. 작업 범위

- Go 단일 프로세스 CLI 결정
- no-controller/no-CRD 기본 원칙
- 대안과 consequences 기록

## 5. 제외 범위

- client-go version 결정
- LIST/WATCH 상세 설계
- internal probe mutation 설계

## 6. 예상 변경 파일

| 파일 | 변경 유형 | 책임 |
|---|---|---|
| `docs/adr/0002-single-process-cli.md` | 생성 또는 수정 | ADR-0002 Go 단일 프로세스 결정 기록 |
| `docs/README.md` | 생성 또는 수정 | ADR-0002 Go 단일 프로세스 결정 기록 |

예상하지 않은 주요 파일이 2개 이상 필요하면 구현을 중단하고 Issue를 재검토한다.

## 7. 구현 계약

ADR은 Context, Decision, Alternatives, Consequences를 포함하며 구현 스펙과 모순되지 않아야 한다.

## 8. Acceptance Criteria

- [ ] AC-1: ADR 번호가 기존 ADR과 충돌하지 않는다.
- [ ] AC-2: Go 단일 binary와 기본 cluster 설치물 없음이 명시된다.
- [ ] AC-3: controller 방식과 runtime 방식의 trade-off가 기록된다.
- [ ] AC-4: 문서 인덱스에서 ADR을 찾을 수 있다.

## 9. 구현 절차

1. Acceptance Criteria를 증명하는 실패 test 또는 inspection check를 먼저 준비한다.
2. 위 예상 파일 안에서 최소 구현을 수행한다.
3. targeted command를 실행한다.
4. diff에서 제외 범위 침범과 불필요한 dependency를 확인한다.
5. 완료 evidence와 commit SHA를 평가서에 전달한다.

## 10. 검증 명령

```bash
test -f docs/adr/0002-single-process-cli.md
rg -n 'Context|Decision|Alternatives|Consequences' docs/adr/0002-single-process-cli.md
rg -n '0002-single-process-cli' docs/README.md
```

## 11. 산출물

- 위 source/test/document
- command별 exit code와 핵심 결과
- AC별 evidence
- 평가 대상 commit SHA

## 12. 형상관리 계약

- Issue: 생성 후 front matter에 기록
- Branch: `docs/11-p0-005-adr-single-process`
- Commit prefix: `[P0-005]`
- PR title: `[P0-005] ADR-0002 Go 단일 프로세스 결정 기록`
- PR 본문: `Closes #11`와 작업지시서/평가서 링크
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

