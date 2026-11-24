# 집중·휴식 배너 구현 검증

2026-11-06. 시안을 실제 Flutter/Google Mobile Ads SDK에 연결한 Android 에뮬레이터 캡처입니다. 생성 이미지나 광고 합성이 아닙니다.

- [집중 중 테스트 배너](focus.png)
- [휴식 중 테스트 배너](rest.png)
- [광고 제거 복원 후](removed.png)
- [Android 통합 검증 로그](integration.log)
- [구현·실제 광고 연결 안내](../../ads/session-banner.md)

Google 테스트 광고의 `Test Ad` 표시와 소재가 실제로 렌더링되는 것을 확인했습니다. 집중·휴식에서 하단 배너를 표시하고, 일시정지에서는 유지하며, 집중 완료에서는 제거합니다. `remove_ads` 보유 상태를 복원하면 진행 중인 휴식에서도 즉시 배너가 사라집니다. 테스트에서는 구매 권한을 대역으로 전달했으며 실제 결제를 수행하지 않았습니다.

`flutter analyze --no-pub` 통과. `test/session_banner_ad_test.dart`, `test/purchases_test.dart`, `test/widget_test.dart` 합계 49개 테스트 통과. 별도 임시 체크아웃과 `dev.jaewook.deskmate.verification` 패키지의 Android SDK 통합 테스트 1개 통과.

첫 캡처에서는 SDK의 로드 완료 이후 플랫폼 뷰 렌더링 전에 화면을 읽어 배너 영역이 비어 있었습니다. 검증 하네스에서 실시간 프레임과 플랫폼 뷰 준비 시간을 확보한 뒤 다시 촬영해 이 폴더의 최종 캡처를 확인했습니다. 테스트 실패를 감추기 위한 이미지 편집은 하지 않았습니다.

이 캡처와 통합 검증은 Google 테스트 광고로 수행했으며 실제 광고 매출은 발생하지 않습니다. 이후 2026-11-06 사용자가 AdMob에서 생성한 `banner` 광고 단위 ID를 로컬 `admob.json`의 `ADMOB_BANNER_SESSION_ID`에 등록했습니다. 실제 광고 송출, 자동 갱신 설정, Play 배포는 이 검증 결과에 포함하지 않습니다.
