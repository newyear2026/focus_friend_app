# 비슷한 앱과 비교한 다음 기능 시안 (2026-11-20)

지금 앱(친구 동작, 시간대별 방, 소리 3종, 달력·주간·월간, D-day, 다음 선물 진행도, 로컬 저장)을 기준으로, 아직 없는 것만 골랐다. 점선이 새로 얹는 부분이다. 화면 속 시간 숫자는 시안용 예시다. 앱 코드는 바꾸지 않았다.

다음 선물 진행도(`../next-gift-progress-v1/`)는 이미 들어가 있어서 여기 넣지 않았다.

| # | 제안 | 비교 | 크기 | 시안 |
|---|---|---|---|---|
| 1 | 태그(공부·작업·독서)와 한 줄 메모, 주간 색 막대 | Forest 태그, Focus Friend 2025-08 태그 세션, Study Bunny 색 태그, 열품타 과목 | 중간 | `01.png` |
| 2 | 집중 중 카운트다운 알림, 홈 위젯 2종 | Focus Friend 2025-05 위젯, 잠금 화면 남은 시간 | 중간 | `02.png` |
| 3 | 하루 목표, 연속 일수, 직접 시간, 선택적 4세트 | Forest 연속·뽀모도로, Focus Friend 휴식, 열품타 하루 목표 | 작음~중간 | `03.png` |
| 4 | 창밖의 비를 켜면 유리에 비. 옷은 그다음, 판매하지 않음 | Focus Friend 2025 옷·방 확장. 소리는 이미 있음 | 그림이 큼 | `04.png` |

가져오지 않은 것: Forest의 앱 잠금·나무 시들기, Study Bunny·Focus Friend의 코인 상점, 같이 집중·계정·스터디룸, 플래시카드. 벌과 재화, 계정은 지금 방의 톤과 저장 방식과 맞지 않는다.

다시 렌더링:

```sh
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for i in 1 2 3 4; do "$C" --headless=new --hide-scrollbars --allow-file-access-from-files --force-device-scale-factor=2 --window-size=1180,1280 --screenshot="$PWD/0$i.png" "file://$PWD/boards.html#b$i"; done
```
