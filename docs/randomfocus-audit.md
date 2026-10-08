# RandomFocus 읽기 전용 진단

확인 경로: `/Users/jaewook/dev_app/randomfocus_app`. `git fetch`, checkout, commit, 수정 또는 실행을 하지 않았습니다. origin 아래 정보는 **현재 로컬 원격 추적 ref**이며 GitHub 서버의 실시간 최신 상태를 주장하지 않습니다.

## 확인된 사실

- 로컬 `main`과 `origin/main`: `007d86620a877c8edd848e3c1326031ca32bcfd8`.
- 현재 체크아웃: `fix/banner-ad-continuity`, HEAD `6cbd0a5be28b1aff46339d50d0471b96df9326b0`. 같은 이름의 원격 추적 ref와 일치합니다.
- main보다 앞선 커밋 4개: `945857e`, `0ea103e`, `80a5635`, `6cbd0a5`. 커밋된 timer_page/history_service는 해당 main과 차이가 없습니다.
- 작업 트리는 깨끗하지 않습니다. `timer_page.dart`, 알림 서비스, 완료 대화상자, 테스트, 플랫폼 설정 등 수정/미추적 파일이 있습니다. 이 변경을 기존 main 코드와 혼동하지 않았습니다.
- 최신 작업 트리의 타이머는 `_deadline`, `_remainingDuration`으로 백그라운드 복귀 시 시간을 보정합니다. 그러나 `_sessionId`, 실행 상태, 잔여 시간, `_deadline`, `_elapsedSeconds`는 StatefulWidget 메모리에만 있습니다. 프로세스 재시작 복구 저장이 없습니다.
- `HistoryService.saveHistory`는 SharedPreferences `timer_history` JSON 목록 앞에 삽입하고 100개로 자릅니다. 누적 통계는 이 목록에서 다시 계산하므로 오래된 기록이 제거되면 줄어들 수 있습니다. 세션 ID upsert와 원자적 보상 ledger는 없습니다.
- 현재 `_stopTimer`는 중도 종료를 `_saveSession`으로 저장하고 `_sessionSaved=true`로 만듭니다. 이후 `_startTimer`는 같은 세션을 재개하지만 이 플래그를 초기화하지 않습니다. 완료 시 `_saveSession(completed)`는 `_sessionSaved` 조건에서 반환합니다.
- 알림 서비스의 로컬 미커밋 변경은 POST_NOTIFICATIONS와 정확한 알람 권한 요청 및 exact/inexact 분기, 집중/휴식 알림을 포함합니다. 기존 완료 흐름은 자동 휴식 전환도 포함합니다.

## 사실과 추정의 경계

Stop → Start → Complete가 완료 기록을 갱신하지 않는 **실제 코드 경로**는 확인했습니다. 기존 앱 자체를 실행해 사용자 저장 데이터로 재현하지 않았으므로 발생 건수, 사용자의 과거 기록 손상 여부는 알 수 없습니다. 미커밋 테스트를 기존 프로젝트에서 실행하거나 수정하지 않았습니다.

## 새 프로젝트에서의 선택

종료 시각에 기초한 시간 계산 원칙을 사용하되 저장·상태 전환·보상은 새로 구현했습니다. UI, 설정, 알림, Firebase/광고 파일을 복사하지 않았습니다. 새 식별자는 `dev.jaewook.prototype.focus_friend_app`, 기존 RandomFocus는 `com.randomfocus.app`입니다. Routineapp와 Sobrita 파일·데이터·브랜치는 접근/수정하지 않았습니다.
