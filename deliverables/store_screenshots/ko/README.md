# Deskmate 스토어 스크린샷 · 한국어

2026-10-15 · 6장 · 1080×1920px · RGB PNG/JPEG

01부터 06 순서로 사용할 수 있습니다. PNG와 JPEG는 같은 디자인입니다. 스토어에는 둘 중 한 형식의 6장만 선택하세요.

- overview.png: 3×2 전체 미리보기
- strip.png: 6장 가로 미리보기
- sources/: 현재 앱 위젯으로 새로 캡처한 원본
- alt-text.tsv: 이미지별 한국어 대체 텍스트
- manifest.json: 제작 방법, 원본 연결, 이미지 크기, 해시

## 구성

- 01_together: 혼자 말고, 함께 집중해요
- 02_friends: 내 마음에 드는 친구와 함께
- 03_day_and_night: 아침부터 밤까지, 나만의 집중방
- 04_focus_sounds: 편안한 소리로 몰입해요
- 05_small_habits: 작은 집중이 쌓이는 하루
- 06_little_rewards: 집중 끝에 만나는 작은 선물

## 제작 및 재현

현재 앱의 실제 Flutter 화면과 기존 앱 아이콘만 사용했습니다. 새 일러스트나 가상 UI는 생성하지 않았습니다. 기록·해금 상태는 2026년 10월 15일 기준의 독립된 메모리 예시입니다. 실제 앱과 사용자 저장 데이터는 수정하지 않습니다.

캡처: flutter test --no-pub tool/capture_store_screenshots_test.dart --reporter expanded

레이아웃/문구 편집 및 재출력: tool/create_store_screenshots.cjs (NODE_PATH에 @napi-rs/canvas와 sharp가 필요합니다.)

글꼴: assets/fonts/PretendardVariable.ttf, OFL 라이선스는 assets/fonts/OFL.txt.

[Google Play 프리뷰 에셋 안내](https://support.google.com/googleplay/android-developer/answer/9866151?hl=ko)
