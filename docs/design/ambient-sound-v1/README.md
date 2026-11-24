# 소리 확장 시안 (2026-11-23)

수면 소리 앱을 따로 만들기 전에, Deskmate 안에서 소리를 넓혀 수요를 먼저 본다. 지금 앱은 소리 하나(비·숲·장작)를 고르고 집중이 끝나면 끈다. 점선이 새로 얹는 부분이다. 앱 코드는 바꾸지 않았다.

| # | 제안 | 크기 | 시안 |
|---|---|---|---|
| 1 | 소리 섞기: 6개(기존 3 + 카페·연필·백색소음) 중 최대 3개, 소리별 음량, 끄는 시점 선택 | 중간 | `01.png` |
| 2 | 잠들기 전: 밤 9시 이후 ‘잠들 때까지’ 30–90분, 어두운 방 화면. 수면 앱을 만들지 정하는 시험 | 중간 + 익명 집계 | `02.png` |
| 3 | 친구 방 소리: 유료 친구 4명에 방 소리 하나씩, 묶음은 4개 모두. 새 상품 없음 | 작음(소리 4개 준비) | `03.png` |

판단 기준(예시): 4주 동안 밤 사용자 중 잠들기 사용 20% 이상, 평균 30분 이상이면 같은 친구로 수면 앱을 검토. 지금 앱은 사용 기록을 밖으로 보내지 않으므로, 이걸 재려면 익명 이벤트와 개인정보처리방침·Data safety 갱신이 필요하다.

- 바탕 화면: `base/night-*.png`는 실제 위젯 렌더링(22:00, 랫서팬더, 소품 3개). `base/ko-*.png`는 구매 화면(가짜 가격).
- 새 소리 타일(카페·연필·백색소음)은 그림이 없어 이모지 자리표시. 잠든 친구 그림도 없음, 2번은 지금 밤 그림을 어둡게만 했다.

다시 만들기:

```sh
flutter test --no-pub tool/capture_ambient_sound_test.dart
flutter test --no-pub --dart-define=PURCHASE_CAPTURE_OUTPUT=docs/design/ambient-sound-v1/base tool/capture_purchases_test.dart
cd docs/design/ambient-sound-v1
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for i in 1 2 3; do "$C" --headless=new --hide-scrollbars --allow-file-access-from-files --force-device-scale-factor=2 --window-size=1180,930 --screenshot="$PWD/0$i.png" "file://$PWD/boards.html#b$i"; done
```
