# 앱 종료 네이티브 광고

Android 루트 화면에서 뒤로 가기를 누르면 선택한 3번 시안의 친구 인사 팝업을 엽니다. 취소·바깥 영역·뒤로 가기는 팝업을 닫으며, `앱 종료`만 Android Activity를 종료합니다. 다른 화면이나 시트가 열려 있으면 해당 화면의 기존 뒤로 가기가 우선합니다. 종료는 집중 세션의 중도 종료가 아니며 저장된 타이머 마감 시각을 변경하지 않습니다.

- 큰 화면: 중형 네이티브 광고 320×350 dp 우선.
- 중형 미준비 또는 작은 화면: 준비된 소형 네이티브 광고 320×188 dp.
- 소형은 가로 배치의 120×120 dp MediaView, 중형은 넓은 MediaView를 사용합니다. 이미지·영상, 광고 아이콘·제목·설명·CTA는 실제 SDK 응답으로 표시합니다.
- 둘 다 미준비·실패·시간 초과·동의 거부·광고 제거 구매: 광고 없이 종료 확인.
- 가용 너비 320 dp 미만, 높이 580 dp 미만, 글자 배율 1.4 초과: 광고를 생략하고 종료 버튼 접근성을 우선합니다. 소형은 타이머 진행 중 높이 620 dp, 글자 배율 1.2 초과일 때 높이 640 dp가 필요합니다. 중형은 너비 352 dp 이상, 높이 760 dp 이상(타이머 진행 중 800 dp), 글자 배율 1.2 이하에서 사용합니다.
- 팝업을 열 때 준비된 광고만 사용합니다. 나중에 도착한 광고를 끼워 넣지 않습니다. 열린 상태에서 광고 제거 구매나 동의 변경으로 광고가 사라지면 해당 공간을 유지해 버튼이 광고 자리로 이동하지 않게 합니다.
- 30초 요청 제한, 1시간 캐시 만료, 취소 후 다시 준비, 종료 후 해제를 적용합니다. 광고를 클릭하거나 시청해야 종료할 수 있는 조건은 없습니다.

## 설정

`admob.json`의 `ADMOB_NATIVE_EXIT_ID`를 사용합니다. 로컬 설정에는 종료 전용 `native_exit` 네이티브 광고 고급형 단위를 연결했습니다. 광고 단위 한 개로 소형·중형 두 배치를 별도 요청합니다. 디버그·프로필은 항상 Google 테스트 광고를 사용합니다. `admob.example.json`은 예시 값만 포함합니다.

실제 광고 ID는 다음처럼 로컬 설정을 포함한 릴리스 빌드에 반영됩니다.

```sh
flutter build appbundle --release --dart-define-from-file=admob.json
```

`lib/exit_native_ads.dart`가 사전 로딩·동의·구매 상태를 관리하고, `lib/app_exit_dialog.dart`가 종료와 화면 크기를 처리합니다. Android `ExitNativeAdFactory.kt`는 `focusFriendExit` 팩토리에 소형·중형 실물 NativeAdView를 만듭니다. 배지와 광고 정보는 광고 영역 안에, 취소·종료 버튼은 그 밖에 둡니다.

네 언어(한국어·영어·스페인어·일본어)를 지원합니다. SDK가 보내는 광고 문구와 CTA는 앱에서 번역하거나 바꾸지 않습니다.

## 검증

```sh
flutter test --no-pub test/app_exit_test.dart test/session_banner_ad_test.dart test/purchases_test.dart test/widget_test.dart test/session_engine_test.dart
FOCUS_EXIT_DEVICE=emulator-5580 python3 tool/verify_app_exit.py
```

설정한 종료 광고 단위의 서버 응답까지 확인하려면 다음처럼 실행합니다. 이 모드는 Android 에뮬레이터에서만 허용하며, 별도 검증 패키지에서 `admob.json`의 종료 ID를 직접 사용합니다. 일반 디버그 앱의 테스트 광고 선택은 변경하지 않습니다.

```sh
FOCUS_EXIT_DEVICE=emulator-5556 \
FOCUS_EXIT_USE_CONFIGURED_UNIT=1 \
FOCUS_EXIT_OUTPUT_DIR="$PWD/docs/ads/native-exit-verification" \
python3 tool/verify_app_exit.py
```

에뮬레이터는 SDK가 자동으로 테스트 기기로 처리합니다. 이 검증은 해당 ID의 테스트 광고 응답·표시를 확인하며 실제 수익 광고의 송출·집계를 확인하는 절차는 아닙니다. [Google 테스트 광고 안내](https://developers.google.com/admob/flutter/test-ads).

실기 렌더링 검증은 별도 `dev.jaewook.deskmate.verification` 패키지와 Google 테스트 광고를 사용합니다. 기존 일반 앱의 저장 데이터는 변경하지 않습니다. 캡처·실행 로그는 `docs/design/app-exit-implementation-v1/`에 있습니다.

참고: [Google 네이티브 광고 플랫폼 연결](https://developers.google.com/admob/flutter/native/platforms), [네이티브 광고 필수 요소·MediaView 크기](https://support.google.com/admob/answer/6329638).
