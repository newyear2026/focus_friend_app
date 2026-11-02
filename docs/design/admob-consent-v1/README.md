# AdMob 광고 동의 흐름

2026-10-30. 그린 시안이 아니라 실제 앱 캡처입니다. `.verification` 패키지를 Pixel 3 에뮬레이터(Android 16)에 설치하고 `--dart-define=ADMOB_DEBUG_EEA=true`로 유럽 위치를 흉내 냈습니다.

[보드](admob-consent-board.png) · [첫 실행](1-first-launch-consent.png) · [설정](2-settings-ad-privacy.png) · [다시 선택](3-privacy-options.png)

1. **첫 실행:** 첫 화면이 뜬 뒤 Google UMP 동의 창이 나타납니다. 한국 등 유럽 밖에서는 창 없이 지나갑니다.
2. **설정:** 동의 변경이 법적으로 필요한 지역에서만 맨 아래에 `광고 개인정보 설정`이 보입니다.
3. **다시 선택:** 이 버튼을 누르면 같은 동의 창이 다시 열립니다.

동의 창 문구와 "Publisher Test Ads"는 Google 샘플 앱 ID의 테스트 메시지입니다. 실제 앱 ID를 쓰면 AdMob의 개인정보 보호 및 메시지에서 만든 메시지가 앱 이름과 사용자 언어로 표시됩니다.
