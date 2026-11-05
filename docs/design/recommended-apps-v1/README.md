# 추천 앱 — 선택 시안 구현

2026-11-05. 설정의 **업데이트 소식** 바로 아래에 **추천 앱**을 추가했습니다. 사용자가 선택한 `selected-mockup.png`를 기준으로 실제 Flutter 위젯을 구현했습니다.

## 화면과 동작

- 크림색 바탕, 짙은 갈색 글자, 둥근 카드, 주황색 Google Play 버튼을 사용합니다.
- 카드 순서는 LOOPET, Sobrita, RandomFocus, MultiCal입니다. 약 390dp 화면에서는 2열, 좁은 화면과 큰 글자에서는 1열로 표시합니다. 화면 전체를 스크롤할 수 있습니다.
- 각 버튼은 해당 앱의 Google Play 상세 화면을 열며, Play 앱을 열 수 없으면 HTTPS 링크를 엽니다. 둘 다 실패하면 안내 후 다시 시도할 수 있습니다. 중복 탭과 화면을 닫은 뒤의 비동기 응답을 처리합니다.
- 화면 읽기 기능은 버튼마다 앱 이름을 함께 읽습니다. 한글 제목은 큰 글자에서 어절 중간이 잘리지 않게 줄바꿈하며, 접근성 설명에는 원래 문구를 사용합니다.
- 한국어·영어·일본어·스페인어를 지원합니다. 추천 앱 열기/뒤로 가기는 집중 기록이나 설정 저장소를 변경하지 않습니다.

## 앱과 아이콘

2026-11-05 공식 스토어의 앱 이름·패키지 ID를 확인했습니다.

| 표시 이름 | Google Play | 원본 아이콘 |
| --- | --- | --- |
| LOOPET | [com.dayround.app](https://play.google.com/store/apps/details?id=com.dayround.app) | `sobra_app/assets/apps/loopet.png` |
| Sobrita | [com.sobra.app.sobra_app](https://play.google.com/store/apps/details?id=com.sobra.app.sobra_app) | `routine_app/flutter_app/assets/apps/sobrita.png` |
| RandomFocus | [com.randomfocus.app](https://play.google.com/store/apps/details?id=com.randomfocus.app) | `routine_app/flutter_app/assets/apps/randomfocus.png` |
| MultiCal | [com.casewen.multi_calc](https://play.google.com/store/apps/details?id=com.casewen.multi_calc) | `sobra_app/assets/apps/multical.png` |

형제 프로젝트의 원본 아이콘을 `assets/apps/`로 복사했고 SHA-256이 일치합니다. 원본 파일은 수정하지 않았습니다. 공개 스토어의 개발자 표시가 서로 달라 소개 문구는 “함께 쓰기 좋은 앱을 만나보세요.”로 정했습니다.

## 시각 QA

선택 시안(852×1846px)과 실제 Flutter 캡처 `collection.png`(390×844dp, 780×1688px)를 함께 열어 비교했습니다. 전체 목업을 배경으로 사용하지 않고 모든 글자·버튼·탐색을 실제 위젯으로 구현했습니다.

- 글꼴·위계: Pretendard, 32sp 제목, 18sp 앱 이름, 14sp 본문. 제목·설명·카드·CTA 순서가 시안과 같습니다.
- 배치·간격: 2열의 같은 행 카드 높이와 버튼 위치를 맞췄습니다. CTA는 최소 높이 44dp로 시안보다 조금 높습니다.
- 색·이미지: 종이색 `#FFF8E9`, 카드 `#FFFBF4`, 본문 `#352724`와 실제 아이콘을 사용합니다. LOOPET의 원본 투명 배경과 여백을 그대로 보존했습니다.
- 작은 화면·큰 글자·가로 화면·영어 캡처도 확인했습니다. 큰 글자의 제목이 한 음절만 다음 줄에 남던 문제를 어절 단위 줄바꿈으로 수정하고 다시 캡처했습니다.
- P0/P1/P2 미해결 문제 없음. P3: 시안의 미세한 종이 질감과 버튼 그라데이션은 평면색으로 단순화했습니다. 원본 아이콘을 보존해 생성 시안의 아이콘 배경·내부 여백과 약간 다릅니다.

캡처: `collection.png`, `collection-compact.png`(320×568dp), `collection-large-text.png`(360×740dp, 글자 1.6배), `collection-landscape.png`(740×360dp), `collection-en.png`, `settings-entry.png`.

## 검증

- 전체 Flutter 테스트 213개 통과(`flutter-test.log`).
- 최종 제목 줄바꿈 수정 후 기능·플랫폼 채널·캡처 테스트 20개 재검증 통과(`feature-tests.log`). 네 언어의 320×568dp·글자 2배에서도 네 앱 버튼까지 스크롤하여 접근합니다.
- 정적 분석 이상 없음(`flutter-analyze.log`). Android 검증용 APK 빌드 성공(`android-build.log`).
- 네이티브 실행 검증은 일반 앱과 분리된 `.verification` 패키지 및 `emulator-5554`에서만 수행합니다.
- 실제 Android에서 설정 → 추천 앱 → LOOPET 버튼으로 Google Play 앱 전환을 확인했습니다(`native-store-open.txt`). 에뮬레이터의 Play 계정이 로그인되지 않아 스토어 로그인 화면이 표시되었고, Android 뒤로 가기로 앱 설정에 복귀했습니다. 로그인 후 상세 페이지 렌더링 및 Play 앱이 없는 기기의 브라우저 폴백은 실제 기기에서 확인하지 않았습니다. 네 개 패키지 매핑과 실패 처리는 자동 테스트 및 코드 검토로 확인했습니다.

재현 명령:

```sh
flutter test --no-pub
flutter test --no-pub test/our_apps_test.dart test/play_store_test.dart tool/capture_our_apps_test.dart
flutter analyze --no-pub
flutter build apk --debug --no-pub --dart-define=FOCUS_FRIEND_VERIFICATION=true
```

카탈로그는 `lib/our_apps.dart`, 화면은 `lib/our_apps_screen.dart`, 스토어 연결은 `lib/play_store.dart`와 Android `RecommendedPlayListings`에 있습니다. 앱을 추가할 때는 두 플랫폼 허용 목록과 아이콘 등록, 네 언어 문구도 함께 갱신하세요.
