---
task_id: ENV-011
title: "Project shell activation과 kubeconfig UX"
status: ready
size: S
milestone: Environment Foundation Follow-up
epic: ENV-E1
issue: https://github.com/ch0992/rollout-proof/issues/76
branch: "feat/76-env-011-shell-activation"
work_order_version: 1
evaluation_document: ../evaluations/ENV-011-evaluation.md
---

# ENV-011 작업지시서: Project shell activation과 kubeconfig UX

## 목적

현재 디렉터리와 무관하게 프로젝트 전용 kubeconfig를 안전하게 활성화하고 기존 shell 환경을 복원한다.

## 문제 재현

홈 디렉터리에서 `export KUBECONFIG="$PWD/.work/kubeconfig"`를 실행하면 존재하지 않는 경로가 설정되고 kubectl이 `localhost:8080`으로 fallback한다.

## 작업 범위

- `scripts/env/activate.sh`
- `test/environment/activate_test.sh`
- 환경 Runbook과 개발환경 문서의 shell 사용 절차
- Environment Task 문서 인덱스

## 제외 범위

- 사용자 `.zshrc` 자동 수정
- global kubeconfig current-context 변경
- cluster 생성 또는 삭제
- 제품 CLI 구현

## Acceptance Criteria

- [ ] AC-1: repository 절대경로의 `.work/kubeconfig`를 사용한다.
- [ ] AC-2: 기존 `KUBECONFIG`와 mise trust 환경을 보존하고 복원한다.
- [ ] AC-3: kubeconfig 누락, 잘못된 context, 직접 실행을 명확히 거부한다.
- [ ] AC-4: 홈 디렉터리 실행, 반복 활성화, 비활성화 회귀 테스트가 통과한다.
- [ ] AC-5: Runbook에 안전한 사용법과 상대경로 위험을 기록한다.

## 검증

```bash
bash -n scripts/env/activate.sh
shellcheck scripts/env/activate.sh test/environment/activate_test.sh
test/environment/activate_test.sh
git diff --check
```

## 형상관리

- Issue: #76
- Branch: `feat/76-env-011-shell-activation`
- Commit prefix: `[ENV-011]`
- 평가 PASS 전에는 merge하지 않는다.
