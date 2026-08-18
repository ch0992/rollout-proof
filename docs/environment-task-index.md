# Environment Foundation Task 문서 인덱스

> 로컬 개발 인프라를 재현 가능한 코드로 구축하고 검증하기 위한 작업지시서·평가서·GitHub Issue 연결표다.

## 실행 순서

```text
ENV-001 → ENV-002 → ENV-003 → ENV-004 → ENV-006 → ENV-007 → ENV-008 → ENV-009 → ENV-010
                         └────→ ENV-005 ──────────────────────────────────────┘
```

- 현재 Mac의 기본 provider 경로는 Docker Desktop(`ENV-004`)이다.
- Colima adapter(`ENV-005`)는 병렬 구현할 수 있지만 CI matrix(`ENV-010`) 전에는 완료한다.
- 선행 Task가 평가 PASS일 때만 다음 Task를 `ready`로 전환한다.

## Task 연결표

| Task | GitHub Issue | 상태 | 작업지시서 | 평가서 |
|---|---:|---|---|---|
| ENV-001 | [#47](https://github.com/ch0992/rollout-proof/issues/47) | Completed | [작업지시서](./tasks/ENV-001-work-order.md) | [평가서](./evaluations/ENV-001-evaluation.md) |
| ENV-002 | [#48](https://github.com/ch0992/rollout-proof/issues/48) | Completed | [작업지시서](./tasks/ENV-002-work-order.md) | [평가서](./evaluations/ENV-002-evaluation.md) |
| ENV-003 | [#49](https://github.com/ch0992/rollout-proof/issues/49) | Completed | [작업지시서](./tasks/ENV-003-work-order.md) | [평가서](./evaluations/ENV-003-evaluation.md) |
| ENV-004 | [#50](https://github.com/ch0992/rollout-proof/issues/50) | Completed | [작업지시서](./tasks/ENV-004-work-order.md) | [평가서](./evaluations/ENV-004-evaluation.md) |
| ENV-005 | [#51](https://github.com/ch0992/rollout-proof/issues/51) | Backlog | [작업지시서](./tasks/ENV-005-work-order.md) | [평가서](./evaluations/ENV-005-evaluation.md) |
| ENV-006 | [#52](https://github.com/ch0992/rollout-proof/issues/52) | Completed | [작업지시서](./tasks/ENV-006-work-order.md) | [평가서](./evaluations/ENV-006-evaluation.md) |
| ENV-007 | [#53](https://github.com/ch0992/rollout-proof/issues/53) | Completed | [작업지시서](./tasks/ENV-007-work-order.md) | [평가서](./evaluations/ENV-007-evaluation.md) |
| ENV-008 | [#54](https://github.com/ch0992/rollout-proof/issues/54) | Ready | [작업지시서](./tasks/ENV-008-work-order.md) | [평가서](./evaluations/ENV-008-evaluation.md) |
| ENV-009 | [#55](https://github.com/ch0992/rollout-proof/issues/55) | Backlog | [작업지시서](./tasks/ENV-009-work-order.md) | [평가서](./evaluations/ENV-009-evaluation.md) |
| ENV-010 | [#56](https://github.com/ch0992/rollout-proof/issues/56) | Backlog | [작업지시서](./tasks/ENV-010-work-order.md) | [평가서](./evaluations/ENV-010-evaluation.md) |

## 공통 완료 조건

1. 작업지시서의 Acceptance Criteria가 모두 충족된다.
2. 대응 평가서에 재현 가능한 명령과 evidence가 기록된다.
3. 평가 verdict가 `PASS`인 commit만 병합한다.
4. 병합 후 다음 Task의 문서와 Issue 상태를 함께 갱신한다.
