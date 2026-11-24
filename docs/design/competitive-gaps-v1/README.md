# 경쟁 앱 대비 보완 제안 v1 (2026-11-19)

이전 리뷰(`../competitive-review-2026-10-14/`) 이후 친구 선택·구매·주간/월간 통계·업데이트 소식이 추가된 상태를 기준으로 다시 비교했다. 시안은 기존 실제 앱 캡처 위에 새 UI만 덧그린 것이며 앱 코드는 바꾸지 않았다. 점선 테두리가 새로 추가되는 부분이다.

| # | 제안 | 비교 근거 | 우선순위 / 크기 | 시안 |
|---|---|---|---|---|
| 1 | 다음 선물까지 진행도 + 소품 로드맵(3 → 7개 이상) | Forest 나무, Focus Friend 양말 | 1 / S~M | `01.png` |
| 2 | 진행 중 알림(카운트다운) + 홈 위젯 2종 | Focus Friend 위젯 업데이트, Forest 리뷰 요청 | 2 / M | `02.png` |
| 3 | 태그(공부·작업·독서)와 태그별 주간 통계 | Forest 태그 통계, 열품타 과목별 타이머 | 3 / M | `03.png` |
| 4 | 다른 앱으로 나가면 친구가 조용히 부르고, 돌아오면 반겨줌 | Forest 나무 죽음, Focus Friend 슬픈 친구 | 4 / S | `04.png` |
| 5 | 완료 인증 카드 공유 | 스터디 인증 문화, Focus Friend SNS 확산 | 5 / S | `05.png` |

텍스트로만 남긴 후보: 직접 입력 시간 / 뽀모도로 자동 반복(집중→휴식→집중), 하루 목표 시간, 연속 일수 홈 표시.

다시 렌더링:

```sh
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for i in 1 2 3 4 5; do "$C" --headless=new --hide-scrollbars --allow-file-access-from-files --force-device-scale-factor=2 --window-size=1180,1260 --screenshot="$PWD/0$i.png" "file://$PWD/boards.html#b$i"; done
```

근거
- https://techcrunch.com/2025/08/18/hank-greens-focus-friend-app-is-climbing-the-app-store-charts-and-its-extremely-cute
- https://apps.apple.com/US/app/id6742278016 (Focus Friend: 위젯, 세션 통계)
- https://apps.apple.com/us/app/id866450515 (Forest: 태그 통계, 함께 심기)
- https://clickup.com/learn/topic/productivity/tools/forest/
- https://www.mindfulsuite.com/reviews/best-focus-timer-apps
