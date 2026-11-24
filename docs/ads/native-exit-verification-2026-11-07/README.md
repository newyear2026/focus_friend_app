# 종료 네이티브 광고 검증 — 2026-11-07

결과: 통과. `native_exit` (`ca-app-pub-2706404530136726/5712437115`)를 사용한 소형·중형 테스트 광고의 서버 응답과 표시를 확인했습니다.

## 확인 결과

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| 위젯·단위 테스트 | 83개 통과 | `unit-widget-tests.log` |
| 실제 Android SDK 통합 테스트 | 1개 통과 | `integration.log` |
| 소형 광고 | AdMob Network 응답, 미디어·CTA 표시 | `small.png`, 응답 ID `EcDvauKLE6CfnM8Pio6l6A8` |
| 중형 광고 | AdMob Network 응답, 미디어·CTA·AdChoices 표시 | `medium.png`, 응답 ID `EcDvaqeQE7ql2ukP0ObjyAg` |
| SDK 네이티브 검증 | 두 배치 모두 `No implementation issues found` | 두 광고 화면의 검증 안내 |
| 광고 제거 상태 | 광고 제거 후 종료 버튼 위치 유지 | `removed-open.png`, 통합 테스트 |
| 광고 없는 종료 팝업 | 정상 표시·취소 | `no-ad.png`, 통합 테스트 |
| 광고 실패·동의·중복 뒤로 가기·종료·타이머 보존 | 통과 | `test/app_exit_test.dart` 포함 83개 테스트 |
| 기존 일반 앱 데이터 | 전체 저장 스냅샷 동일, 기록 14개 유지 | `data-preservation.json` |
| 배포용 APK | 빌드 성공, 새 ID가 ARM64 실행 바이너리에 포함 | `release-build.log`, `release-verification.json` |
| Android 설정 | 실제 AdMob App ID 및 일반 앱 패키지 확인 | `release-verification.json` |
| 변경한 통합 테스트 정적 분석 | 문제 없음 | `analyze.log` |

첫 소형·중형 요청은 30초 제한을 넘겼습니다. 검증 도구가 다음 요청 주기를 시작한 뒤 두 형식 모두 로드되어 테스트를 완료했습니다. 성공한 응답의 광고 단위 매핑은 위 `native_exit` ID와 일치하며 AdMob 어댑터 오류는 없습니다. 시간 초과 자체는 영구 장애로 판정하지 않았고 최초 요청 성공을 주장하지 않습니다.

검증용 앱은 별도 `dev.jaewook.deskmate.verification` 패키지이며 에뮬레이터의 테스트 광고 모드로 실행했습니다. SDK 로그에서도 테스트 기기 요청임을 확인했고, 캡처에는 테스트 광고 표시가 있습니다. 실제 수익 광고의 송출·노출 집계는 이 검증 범위에 포함되지 않습니다. [Google 테스트 광고 안내](https://developers.google.com/admob/flutter/test-ads).

검증 후 화면 설정은 기존 1080×1920, 440 dpi로 복원했고 일반 앱의 소형 광고 종료 팝업으로 돌아왔습니다.

## 실행

```sh
flutter test --no-pub test/app_exit_test.dart test/session_banner_ad_test.dart test/purchases_test.dart test/widget_test.dart test/session_engine_test.dart

FOCUS_EXIT_DEVICE=emulator-5556 \
FOCUS_EXIT_USE_CONFIGURED_UNIT=1 \
FOCUS_EXIT_OUTPUT_DIR="$PWD/docs/ads/native-exit-verification-2026-11-07" \
python3 tool/verify_app_exit.py

flutter build apk --release --target-platform android-arm64 --dart-define-from-file=admob.json
flutter analyze --no-pub integration_test/app_exit_test.dart
```

통합 테스트 직후 `--no-pub` 릴리스 빌드는 테스트 플러그인 등록 캐시가 남아 실패했습니다. 의존성·자동 생성 등록 정보를 갱신하는 위 릴리스 명령으로 빌드에 성공했습니다. 검증 도구의 첫 빌드도 등록 정보를 갱신하도록 정리했습니다.

APK: `build/app/outputs/flutter-apk/app-release.apk` (일반 앱, ARM64). 빌드 결과의 SHA-256은 `release-verification.json`에 기록했습니다. 스토어 업로드는 수행하지 않았습니다.
