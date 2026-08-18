# RolloutProof 환경 자동화 스펙

> 상태: 0.1-draft
> Task: ENV-001
> Issue: [#47](https://github.com/ch0992/rollout-proof/issues/47)

## 1. 목표

새 Mac 또는 CI runner에서 동일한 입력으로 local Kubernetes 환경을 검사, 구축, 검증하고 machine-readable evidence를 남긴다.

## 2. 자동화 계층

```text
Brewfile / tool versions / provider config / kind YAML
                         ↓
                      Makefile
                         ↓
                provider + lifecycle scripts
                         ↓
                    env-verify/report
```

선언 파일이 source of truth다. script에 version, cluster 이름, resource 값을 중복 하드코딩하지 않는다.

## 3. Mode

| Mode | 의미 | Mutation |
|---|---|---|
| check | 상태와 drift만 검사 | 없음 |
| plan | 실행할 변경과 명령 출력 | 없음 |
| apply | 승인된 설치/생성 수행 | 있음 |
| verify | acceptance suite 실행 | test namespace 내부 |
| cleanup | 명시 target 정리 | opt-in 필수 |

모든 command의 기본 mode는 check 또는 plan이다.

## 4. 공통 명령 계약

```bash
make env-check
make env-plan
make env-bootstrap APPLY=true
make runtime-up CONTAINER_PROVIDER=docker-desktop
make cluster-up K8S_MINOR=1.36
make env-verify
make env-report
make cluster-down ALLOW_DELETE=true
```

각 command는 시작 시 task, mode, provider, Docker context, cluster, kubeconfig category를 출력한다.

## 5. Provider Interface

provider adapter는 다음 operation을 구현한다.

- `check`: 설치, daemon과 context 상태
- `plan`: 필요한 변경 설명
- `start`: 명시 provider 시작
- `wait`: readiness timeout
- `inspect`: version/resource/context evidence
- `stop`: project-owned runtime만 중지

Docker Desktop adapter는 설치, 약관, factory settings를 변경하지 않는다. Colima adapter는 `rolloutproof` profile만 소유한다.

## 6. 멱등성

- 같은 config의 두 번째 apply는 변경 0이어야 한다.
- cluster/config drift는 자동 삭제 대신 FAIL과 diff를 반환한다.
- partial failure 후 같은 명령으로 재개 가능해야 한다.
- 중복 profile, cluster, namespace를 만들지 않는다.

## 7. 파일 구조

```text
Brewfile
mise.toml
Makefile
infra/local/providers/
infra/local/kind/
scripts/env/
test/environment/
.work/artifacts/environment/
```

## 8. Exit Code

- `0`: 성공/READY
- `2`: 사용법/config 오류
- `3`: tool 누락/version 불일치
- `4`: provider/runtime 오류
- `5`: Kubernetes 오류
- `6`: isolation/safety 위반
- `7`: cleanup 실패
- `10`: INCONCLUSIVE

## 9. Evidence

모든 apply/verify는 command, exit code, duration, sanitized environment metadata와 artifact checksum을 남긴다. token, certificate와 kubeconfig 본문은 금지한다.

## 10. Definition of Done

- check/plan/apply/verify/cleanup이 분리된다.
- Docker Desktop과 Colima가 같은 provider interface를 사용한다.
- kind/kubeconfig/test logic은 provider와 독립적이다.
- destructive operation은 정확한 target과 opt-in을 요구한다.
- 환경 report가 exit code와 같은 verdict를 갖는다.

