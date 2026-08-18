# RolloutProof AI 개발 운영 지침

> 상태: 0.1-draft  
> 목적: AI가 문서와 이슈를 기준으로 작은 단위의 구현·평가·재작업을 반복할 수 있는 개발 계약

## 1. 운영 목표

AI 개발의 기본 단위는 대화나 큰 기능이 아니라 **검증 가능한 하나의 이슈**다.

이 운영 방식은 다음을 목표로 한다.

1. AI가 매 작업마다 전체 문서를 다시 읽지 않게 한다.
2. 구현 범위를 작게 제한해 추론과 평가 token을 줄인다.
3. 완료 기준을 구현 전에 고정한다.
4. 구현 AI와 평가 AI의 역할을 분리한다.
5. 평가 실패 시 전체 기능이 아니라 실패한 이슈만 재작업한다.
6. 모든 결정과 증거가 문서, 이슈, test 및 ADR에 남게 한다.

## 2. 단일 진실 공급원

문서는 다음 우선순위를 갖는다.

| 우선순위 | 문서 | 역할 |
|---:|---|---|
| 1 | 제품 스펙 | 사용자가 보게 되는 동작과 외부 계약 |
| 2 | 엔지니어링 구현 스펙 | 기술 선택과 내부 구현 원칙 |
| 3 | ADR | 이미 확정된 개별 기술 결정 |
| 4 | Epic | 여러 이슈가 달성할 사용자 결과 |
| 5 | Task issue | 한 번에 구현하고 검증할 작업 계약 |
| 6 | 코드와 test | 계약을 실행 가능한 형태로 증명 |

상충할 경우 상위 문서를 따른다. 상위 문서를 변경해야 한다면 구현 이슈에서 몰래 변경하지 않고 별도 `SPEC` 또는 `ADR` 이슈를 먼저 완료한다.

## 3. 작업 계층

```text
Product Goal
  └── Milestone
       └── Epic
            └── Task
                 └── Rework (평가 실패 시에만)
```

- **Milestone**: Phase 0, MVP-A1, MVP-A2, MVP-B와 대응한다.
- **Epic**: 사용자가 확인할 수 있는 end-to-end 결과 하나다.
- **Task**: 하나의 agent가 하나의 context로 구현하고 검증할 수 있는 최소 단위다.
- **Rework**: 평가에서 실패한 acceptance criterion만 수정하는 후속 이슈다.

Epic을 직접 구현하지 않는다. 모든 코드는 Task를 통해서만 변경한다.

## 4. 이슈 크기 기준

기본 S Task는 아래 기준을 모두 만족해야 한다.

- 사용자 또는 내부 동작 변화가 한 가지다.
- 주요 수정 파일은 1~4개다. test/fixture/generated file은 별도 계산할 수 있다.
- production code 순변경은 약 300줄 이하를 목표로 한다.
- acceptance criterion은 3~7개다.
- 검증 명령은 1~3개다.
- 독립적으로 revert할 수 있다.
- 완료 여부를 `PASS` 또는 `FAIL`로 판정할 수 있다.
- 새로운 구조적 결정이 2개 이상 필요하지 않다.

M Task는 adapter나 작은 vertical slice처럼 분리가 오히려 interface 재작업을 만드는 경우에만 허용한다. 이때 주요 파일은 최대 7개이며 이슈에 M이어야 하는 이유를 기록한다. 다음 중 하나라도 해당하면 이슈를 분할한다.

- 서로 다른 package 세 개 이상에 새로운 책임을 동시에 추가한다.
- CLI, Kubernetes adapter, analyzer, renderer를 한 이슈에서 모두 새로 만든다.
- `그리고`, `동시에`, `추가로`가 acceptance criterion에 반복된다.
- unit test와 실제 cluster E2E 실패 원인을 한 번에 수정한다.
- 평가하려면 전체 repository를 다시 이해해야 한다.
- S Task가 300줄을 크게 넘거나 주요 파일이 4개를 넘는데 M 승격 근거가 없다.

예외는 mechanical change, generated code, schema snapshot처럼 판단이 거의 필요 없는 변경이다. 예외 사유를 이슈에 기록한다.

## 5. Token budget

Token은 모델마다 계산과 가격이 다르므로 비용의 절대값보다 **읽기 범위와 산출물 크기**를 먼저 통제한다.

### 5.1 작업 등급

| 등급 | 용도 | 입력 범위 | 예상 구현 난이도 | 구현+자체검증 목표 |
|---|---|---|---|---:|
| XS | 문서, config, 작은 순수 함수 | 관련 문서 1개, 파일 1~2개 | 매우 낮음 | 8k token 이하 |
| S | 일반 Task 기본값 | 문서 section 2개 이하, 파일 1~4개 | 낮음 | 15k token 이하 |
| M | adapter 또는 작은 vertical slice | 문서 section 3개 이하, 파일 3~7개 | 중간 | 30k token 이하 |
| L | 허용하지 않음 | 범위 재분할 필요 | 높음 | Task로 생성 금지 |

평가 agent의 목표 budget은 구현 budget의 25~35%다. 평가가 이를 크게 넘는다면 acceptance criterion이 모호하거나 평가 범위가 넓다는 신호다.

### 5.2 Token 절감 규칙

- 이슈에는 전체 문서 링크 대신 필요한 heading anchor와 requirement ID를 적는다.
- 구현 agent에게 관련 파일 목록을 제공한다.
- 평가 agent는 전체 대화가 아니라 이슈, diff, test 결과와 참조 section만 읽는다.
- command output은 성공 시 요약하고 실패 시 관련 구간만 보존한다.
- 반복되는 build/test 지침은 이 문서와 Make target을 참조한다.
- 코드 설명을 매번 재작성하지 않고 ADR 또는 package doc에 한 번 기록한다.
- 이미 통과한 상위 test를 rework마다 전부 실행하지 않는다. 영향 test 후 merge gate에서 전체 test를 실행한다.

Token budget 초과 자체는 기능 실패가 아니다. 다만 초과 원인과 다음 이슈에서의 분할 개선을 기록한다.

## 6. Requirement ID

제품 및 구현 요구사항에는 안정적인 ID를 부여한다.

```text
PROD-GATE-001       제품 동작
ENG-WATCH-001       Kubernetes watch 구현
ENG-PROBE-001       HTTP probe 구현
ENG-EVENT-001       timeline/event 구현
SEC-REDACT-001      보안
TEST-E2E-001        검증
```

한 Task는 보통 1~3개의 requirement ID만 구현한다. test name, issue 및 PR description에서 같은 ID를 사용한다.

## 7. Task issue 계약

모든 구현 이슈에는 다음 항목이 반드시 있어야 한다.

각 Task는 Issue 생성 전에 [작업지시서 템플릿](./templates/task-work-order.md)과 [평가서 템플릿](./templates/task-evaluation.md)을 복제해 한 쌍으로 준비한다. Issue는 두 문서를 모두 링크하고, 두 문서는 Issue URL과 서로의 경로를 기록한다.

### 7.1 Context

왜 필요한지 3~5문장으로 설명한다. 제품 전체 배경을 복사하지 않는다.

### 7.2 References

정확한 문서와 heading, requirement ID를 적는다.

### 7.3 Scope

이번 이슈에서 구현하는 것만 적는다.

### 7.4 Non-goals

비슷하지만 이번에 구현하지 않는 항목을 적는다. AI의 자발적 범위 확장을 막는 가장 중요한 부분이다.

### 7.5 Expected files

수정 예상 파일과 새 파일을 적는다. 실제 구현 과정에서 달라질 수 있으나 새로운 주요 파일이 2개 이상 추가되면 중단하고 이슈 분할을 검토한다.

### 7.6 Acceptance criteria

관측 가능한 Given/When/Then 또는 boolean 조건으로 작성한다.

나쁜 예:

> watch를 안정적으로 구현한다.

좋은 예:

> WATCH가 EOF로 종료되면 supervisor는 250ms~10s 범위의 jitter backoff 후 마지막 resourceVersion에서 다시 연결한다.

### 7.7 Verification

AI가 실행해야 하는 명령과 예상 결과를 적는다.

### 7.8 Evaluation rubric

정확성, 범위 준수, test, 안전성, 유지보수성을 각각 PASS/FAIL로 판정할 수 있게 만든다.

## 8. 구현 workflow

### Step 1 — Issue readiness

구현 전 `Ready` 조건을 확인한다.

- 상위 Epic과 requirement ID가 있다.
- 선행 이슈가 완료되었다.
- scope/non-goal이 명확하다.
- acceptance criterion이 자동 또는 수동으로 검증 가능하다.
- 필요한 fixture와 API version이 정해졌다.
- Task 크기가 XS/S/M이다.

하나라도 아니면 코딩하지 않고 `Needs refinement`로 돌린다.

### Step 2 — Implementation brief

구현 agent는 코딩 전 이슈를 다음 다섯 줄로 재진술한다.

1. 구현할 결과
2. 변경할 파일
3. 사용하거나 변경할 interface
4. 실행할 test
5. 명시적 non-goal

재진술이 이슈와 다르면 구현하지 않고 이슈를 수정한다.

### Step 3 — Test-first contract

순수 domain logic은 failing unit test를 먼저 만든다. adapter는 재현 fixture 또는 fake server를 먼저 정의한다. 문서·배포 작업은 lint/check command 또는 inspection checklist를 먼저 정의한다.

### Step 4 — Minimal implementation

acceptance criterion을 만족하는 최소 변경만 수행한다. 요청되지 않은 framework, 추상화, fallback 및 future option을 추가하지 않는다.

### Step 5 — Self-verification

구현 agent는 다음 순서로 확인한다.

1. 변경 파일 범위
2. targeted test
3. formatting/static check
4. 인접 package test
5. acceptance criterion 자체 점검

### Step 6 — Independent evaluation

평가 agent는 구현 agent의 설명을 신뢰하지 않고 증거만 확인한다.

입력:

- 원본 이슈
- 관련 requirement section
- diff
- 실행된 test 결과
- 필요한 경우 생성 artifact

출력:

```text
Verdict: PASS | FAIL | INCONCLUSIVE

AC-1: PASS — evidence
AC-2: FAIL — evidence
Scope: PASS | FAIL
Tests: PASS | FAIL
Security: PASS | FAIL | N/A
Maintainability: PASS | FAIL

Required rework:
- 최소 수정 항목
```

평가 agent는 새로운 기능을 제안하지 않는다. 개선 제안은 별도 backlog 후보로 분리한다.

### Step 7 — Merge gate

모든 acceptance criterion과 mandatory rubric이 PASS인 경우에만 완료한다. INCONCLUSIVE는 PASS로 간주하지 않는다.

## 9. 평가 기준

### 9.1 Mandatory rubric

| 항목 | PASS 조건 |
|---|---|
| Correctness | 모든 acceptance criterion에 test 또는 inspection evidence가 있음 |
| Scope | non-goal을 구현하지 않았고 예상 범위에서 벗어난 변경이 없음 |
| Tests | 지정 test와 영향 package test가 통과함 |
| Safety | context 취소, timeout, redaction, RBAC 등 해당 안전 조건을 위반하지 않음 |
| Maintainability | package 책임이 유지되고 불필요한 추상화/전역 상태가 없음 |
| Documentation | 외부 계약 또는 중요한 결정 변화가 문서/ADR에 반영됨 |

필수 항목 하나라도 FAIL이면 전체 verdict는 FAIL이다.

### 9.2 Evidence 우선순위

```text
자동 test 결과 > 재현 가능한 command output > 생성 artifact > code inspection > 구현자의 설명
```

평가 근거가 구현자의 설명뿐이면 INCONCLUSIVE다.

### 9.3 품질 점수 사용 금지

개별 Task는 8/10 같은 평균 점수로 통과시키지 않는다. 보안 FAIL과 스타일 PASS가 상쇄될 수 있기 때문이다. 모든 필수 기준은 boolean gate로 평가한다. 점수는 Epic 회고나 제품 효용성 평가에만 사용한다.

## 10. 실패와 재작업

평가 실패 시 같은 구현 prompt를 처음부터 반복하지 않는다.

1. 실패한 acceptance criterion을 식별한다.
2. 실패 원인이 spec, implementation, test 중 어디에 있는지 분류한다.
3. 원래 이슈를 다시 열거나 `REWORK-<issue>` child issue를 만든다.
4. 변경 가능 파일과 금지 범위를 더 좁힌다.
5. 실패를 재현하는 test를 먼저 추가한다.
6. 해당 test와 인접 test만 우선 실행한다.
7. rework 평가 후 merge gate에서 전체 suite를 실행한다.

### 10.1 재작성 조건

부분 수정이 아니라 구현을 폐기하고 다시 작성하는 조건은 다음과 같다.

- 핵심 interface가 requirement와 반대 방향이다.
- acceptance criterion 절반 이상이 실패한다.
- 잘못된 전역 상태 또는 동시성 구조 때문에 국소 수정이 더 위험하다.
- test가 구현 세부사항만 검증해 제품 동작을 증명하지 못한다.
- security invariant를 구조적으로 만족할 수 없다.

재작성도 기존 이슈 안에서 무제한 반복하지 않는다. 실패 분석을 남기고 새로운 접근과 더 작은 Task로 분할한다.

### 10.2 반복 제한

- 동일 이슈의 rework는 최대 2회다.
- 2회 실패하면 `Needs design review`로 전환한다.
- 세 번째 구현을 바로 시도하지 않고 spec 모호성, 이슈 크기, interface 선택을 먼저 검토한다.

이는 시간 제한이 아니라 같은 정보로 같은 실패를 반복하지 않기 위한 규칙이다.

## 11. 상태 workflow

```text
Draft
  → Needs refinement
  → Ready
  → In progress
  → Self-verified
  → Evaluation
      ├── PASS → Done
      ├── FAIL → Rework
      └── INCONCLUSIVE → Needs evidence
```

상태 변경 조건:

- `Ready`: Definition of Ready 충족
- `Self-verified`: 구현 agent가 verification evidence 첨부
- `Evaluation`: 독립 평가 입력이 완전함
- `Done`: mandatory rubric 전체 PASS

Issue, branch, commit, PR 및 evaluated commit 연결은 [Issue 및 형상관리 Workflow](./version-control-workflow.md)를 따른다.

## 12. 문서 변경 규칙

- 사용자-visible behavior 변경: 제품 스펙 수정
- 내부 구현 원칙 변경: 구현 스펙 수정
- 되돌리기 어려운 기술 결정: ADR 추가
- task 수행법만 명확해짐: 이 playbook 수정
- report/config contract 변경: schema와 golden fixture 수정

문서 변경은 코드 이후 정리 작업이 아니다. 해당 변경의 acceptance criterion에 포함한다.

## 13. AI context package

각 Task의 입력은 다음 순서로 구성한다.

```text
1. Issue 본문
2. 참조된 spec heading
3. 관련 ADR
4. Expected files의 현재 내용
5. 선행 interface 또는 schema
6. 직전 test failure
```

포함하지 않는 것:

- 전체 대화 기록
- 관련 없는 전체 기획서
- 완료된 다른 이슈의 상세 구현 로그
- 전체 repository tree와 전체 test output
- 평가자의 개선 아이디어

## 14. Epic 완료 평가

Task PASS의 합이 Epic 성공을 자동 보장하지는 않는다. Epic 종료 시 사용자 관점의 vertical acceptance test를 한 번 수행한다.

예: `gate --wait-for-revision` Epic

1. kind에 fixture를 배포한다.
2. gate를 baseline 이전에 실행한다.
3. 새 revision을 배포한다.
4. 정상 fixture는 PASS해야 한다.
5. 결함 fixture는 정의된 finding과 함께 FAIL해야 한다.
6. terminal, JSON 및 exit code가 같은 verdict를 가져야 한다.

Epic 평가는 내부 package test를 다시 평가하는 대신 사용자 결과와 artifact의 일관성을 확인한다.

## 15. 운영 지표

AI 개발 방식 자체도 측정한다.

| 지표 | 초기 목표 |
|---|---:|
| Task 첫 평가 PASS 비율 | 70% 이상 |
| Task 평균 rework 횟수 | 0.5 이하 |
| S Task 주요 변경 파일 | 4개 이하 |
| 평가 token / 구현 token | 35% 이하 |
| 동일 원인 2회 재실패 | 0건 |
| spec 누락으로 인한 rework | 전체 실패의 15% 이하 |
| flaky test 비율 | 1% 이하 |

지표가 나쁘면 agent prompt를 늘리기보다 먼저 Task 크기와 acceptance criterion을 개선한다.

## 16. Definition of Done

Task는 다음을 모두 만족해야 완료된다.

- scope와 모든 acceptance criterion이 구현되었다.
- 지정 test와 영향 test가 통과했다.
- formatting, lint 및 static check가 통과했다.
- 보안 및 취소/timeout 조건을 위반하지 않는다.
- 외부 계약 변경이 문서와 schema에 반영되었다.
- 구현 evidence가 이슈에 기록되었다.
- 독립 평가가 PASS다.
- 남은 작업이 별도 이슈로 분리되었다.
