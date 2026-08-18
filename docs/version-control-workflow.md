# RolloutProof Issue 및 형상관리 Workflow

> 상태: 0.1-draft  
> 적용 범위: 모든 구현, 문서, 평가 및 재작업 Task

## 1. 연결 원칙

모든 Task는 다음 traceability chain을 가져야 한다.

```text
Requirement ID
  → Work order
  → Evaluation document
  → GitHub Issue
  → Branch
  → Commit
  → Pull Request
  → CI evidence
  → Evaluated commit SHA
  → Evaluation verdict
  → Merge commit
```

Issue가 없는 production code 변경은 허용하지 않는다. repository bootstrap과 Issue template 도입 같은 최초 기반 작업만 예외로 하며 initial commit에 그 사유를 기록한다.

## 2. 식별자

- 안정 식별자: `P0-001` 같은 Task ID
- GitHub 식별자: Issue 생성 후 부여되는 `#123`
- 두 식별자를 branch, commit, PR에 함께 기록한다.

Task ID는 문서와 requirement 추적에 사용하고 Issue 번호는 GitHub 형상관리 연결에 사용한다.

## 3. Branch

```text
{type}/{issue-number}-{task-id}-{short-desc}
```

예:

```text
feat/12-p0-001-go-module-entrypoint
docs/13-p0-005-adr-single-process
fix/47-p0-014-watch-reconnect
refactor/52-p0-008-event-sequencer
chore/61-p0-004-ci-unit-build
```

type은 `feat`, `fix`, `docs`, `refactor`, `chore`만 사용한다. Task 문서 front matter의 placeholder는 Issue 생성 직후 실제 번호로 교체한다.

## 4. Commit

```text
{type}: [{task-id}] 변경 내용
```

예:

```text
feat: [P0-001] initialize Go module and CLI entrypoint
test: [P0-014] reproduce watch EOF reconnect
docs: [P0-005] record single-process CLI decision
```

한 commit은 하나의 Task만 다룬다. 평가 실패 재현 test와 수정은 가능하면 별도 commit으로 남긴다. main의 공개 history는 force push나 reset으로 다시 쓰지 않고 `git revert`로 되돌린다.

## 5. Pull Request

1인 개발이어도 독립 평가와 evaluated commit 고정을 위해 PR을 필수로 사용한다.

- 제목: `[P0-001] Go module과 CLI entrypoint 생성`
- 본문에 `Closes #<issue-number>` 포함
- 작업지시서와 평가서 링크 포함
- base/head commit SHA 포함
- AC별 구현 evidence 포함
- 평가 전에는 draft PR 유지
- 평가서 PASS와 required CI PASS 후에만 merge

평가 이후 새 commit이 push되면 evaluated commit이 달라졌으므로 영향 항목을 재평가한다.

## 6. Issue

Issue 본문은 다음을 포함한다.

- Task ID와 parent Epic
- work order permalink
- evaluation document permalink
- requirement ID
- scope/non-goal
- acceptance criteria
- expected files
- verification commands
- branch와 PR link

Issue 생성 직후 두 문서의 `issue` field를 실제 URL로 변경한다.

## 7. 상태 전이

```text
Draft docs
  → Issue created
  → Ready
  → Branch created
  → Implementation
  → Draft PR
  → Self-verified
  → Evaluation
  → PASS
  → Merge
  → Issue closed
```

FAIL이면 PR을 merge하지 않고 evaluation 문서에 rework 범위를 고정한다. INCONCLUSIVE이면 필요한 evidence를 추가하되 기능 범위를 확장하지 않는다.

## 8. Merge 및 rollback

- merge 방식은 초기에는 squash merge를 기본으로 한다.
- squash message에 Task ID를 유지한다.
- branch protection이 설정되면 required CI와 PR review/evaluation gate를 적용한다.
- merge 전 rollback은 branch 폐기로 처리한다.
- merge 후 rollback은 `git revert <merge-commit>`을 사용한다.
- main force push와 destructive reset은 금지한다.

## 9. 자동 검증

향후 CI에서 다음을 검사한다.

- 변경된 Task의 work order/evaluation 두 문서 존재
- front matter Task ID 일치
- Issue URL, PR URL, evaluated commit 누락 여부
- branch/PR title의 Task ID
- 평가서 verdict PASS
- evaluated commit이 PR head 또는 허용된 ancestor인지 여부
- requirement ID가 존재하는지 여부

