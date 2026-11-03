# 하단 배너 광고 배치 시안

책상 화면에 하단 고정 배너를 넣었을 때의 모습입니다. 실제 앱에 임시 배너 위젯(높이 50dp)을 넣고 에뮬레이터에서 캡처했습니다. 캡처한 뒤 코드는 되돌렸습니다.

- 비교 보드: [bottom-banner-board.png](bottom-banner-board.png)
- 책상 대기: [desk-banner.png](desk-banner.png) — 하단 메뉴 바로 위
- 집중 중: [focusing-banner.png](focusing-banner.png) — 하단 메뉴가 숨겨지므로 화면 맨 아래
- 배너 없음 비교: [redpanda-home.png](../friend-picker-implementation/redpanda-home.png)

책상 대기 화면에서는 배너 높이만큼 콘텐츠가 위로 밀립니다. 그래서 `오늘의 집중`이 친구 몸 위에, 시간 선택 칩이 책 위에 겹칩니다. 실제로 적용할 때는 책상 화면의 세로 배치를 다시 잡아야 합니다.

광고 문구와 아이콘은 예시입니다. 실제 배너는 AdMob이 고른 광고로 채워지며, 적응형 배너는 기기 너비에 따라 50dp보다 조금 더 높을 수 있습니다.
