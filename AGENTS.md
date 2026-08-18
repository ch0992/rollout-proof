# RolloutProof AI 작업 규칙

## 시작 전 필수 읽기

작업 종류에 따라 다음 순서로 읽는다.

1. 해당 GitHub Issue
2. `docs/tasks/<TASK-ID>-work-order.md`
3. `docs/evaluations/<TASK-ID>-evaluation.md`
4. 작업지시서가 링크한 specification과 ADR
5. `docs/ai-development-playbook.md`
6. `docs/version-control-workflow.md`

환경 작업은 추가로 다음을 읽는다.

- `docs/environment-automation-spec.md`
- `docs/ai-environment-runbook.md`
- `docs/development-environment.md`
- `docs/local-environment-validation.md`

## 작업 시작 조건

- Issue label이 `ready`여야 한다.
- 작업지시서와 평가서가 모두 존재해야 한다.
- branch 이름에 Issue 번호와 Task ID가 있어야 한다.
- 선행 Task가 PASS여야 한다.
- 예상 변경 파일과 non-goal을 재진술한 후 작업한다.

## 환경 안전 규칙

- 기본 동작은 read-only check다.
- 설치와 mutation은 `--apply` 또는 문서화된 opt-in이 있어야 한다.
- 현재 Mac의 provider는 `docker-desktop`, context는 `desktop-linux`다.
- 사용자의 global kubeconfig current-context를 바꾸지 않는다.
- `default`, `kube-system` namespace에 fixture를 만들지 않는다.
- `rolloutproof-*` 이외의 kind cluster를 삭제하지 않는다.
- Docker Desktop factory reset, image/container 전체 삭제를 실행하지 않는다.
- Colima default profile을 생성·수정·삭제하지 않는다.
- `.work` 밖을 환경 artifact/cleanup 대상으로 사용하지 않는다.
- cleanup은 정확한 cluster/namespace/run ID를 확인한 뒤 수행한다.

## 구현 규칙

- 선언 파일이 기준이고 script는 얇은 실행 adapter다.
- 명령은 반복 실행 가능해야 한다.
- drift가 있으면 자동 재생성하지 않고 diff와 복구 명령을 출력한다.
- secret, token, kubeconfig 내용과 URL query를 출력하지 않는다.
- 실패를 자동 retry해 PASS로 덮지 않는다.
- library code에서 `os.Exit`, `log.Fatal`, panic을 사용하지 않는다.

## 형상관리

- branch: `{type}/{issue-number}-{task-id}-{short-desc}`
- commit: `{type}: [{task-id}] description`
- PR에 `Closes #<issue>`, 작업지시서와 평가서 링크를 포함한다.
- 평가 대상 commit SHA를 평가서에 기록한다.
- 평가 PASS와 required CI PASS 전에는 merge하지 않는다.
- main force push와 destructive reset은 금지한다.

## 완료 보고

```text
Task:
Issue:
Implemented:
Changed files:
Verification:
Acceptance evidence:
Safety evidence:
Known limitations:
Commit SHA:
```
