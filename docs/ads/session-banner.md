# 집중·휴식 하단 배너

2026-11-06. [승인된 시안](../design/focus-rest-banner-concept-v1/README.md)의 하단 배너를 Flutter 앱에 연결했습니다.

## 표시와 구매

- 집중·휴식의 진행/일시정지 중 320×50 dp 표준 배너 하나를 하단 가운데에 표시합니다. 위쪽 1 dp 구분선과 시스템 하단 안전 영역을 별도로 확보합니다. 시안의 작은 광고 높이를 유지하기 위해 확장형 배너는 사용하지 않습니다.
- 실제 소재·문구·색은 Google 광고 SDK가 공급합니다. 앱이 광고 안에 임의의 CTA나 닫기 버튼을 추가하지 않습니다.
- 타이머·일러스트·버튼 위치는 광고 로드 전후 동일합니다. 작은 화면과 큰 글자에서는 조작 영역만 스크롤하며 배너 위에서 잘립니다.
- 광고 폭을 확보할 수 없는 320 dp 미만 창, 대기, 완료, 종료, 체험에서는 요청하지 않습니다.
- 기존 UMP 준비가 광고 요청을 허용한 뒤 요청합니다. 동의 미허용/실패 또는 광고 로드 실패는 타이머를 막지 않습니다. 로드 실패 시 해당 광고를 해제하고 다음 세션/화면 복귀 때 다시 요청합니다.
- 비활성화·백그라운드에서는 네이티브 광고를 즉시 해제합니다. 설정 시트/종료 확인 등 다른 Flutter route가 열려도 배너를 해제합니다. 복귀 시 동의를 확인하고 새 광고를 요청합니다.
- `remove_ads`와 `all_friends` 보유 상태는 집중·휴식 배너에도 적용됩니다. 결제 대기 상태는 광고 제거 권한이 아닙니다.
- 화면 켜두기 설정과 타이머/집중 기록 로직은 그대로 유지합니다.

## 실제 광고 연결

1. AdMob에서 이 앱용 **배너** 광고 단위를 만들고 자동 새로고침을 Google 최적화로 설정합니다. 기록·설정의 네이티브 광고 ID를 재사용하지 않습니다.
2. git에서 제외된 `admob.json`에 `ADMOB_BANNER_SESSION_ID`를 추가합니다. 키 형식은 루트의 `admob.example.json`에 있습니다.
3. 기존처럼 `--dart-define-from-file=admob.json`을 사용해 릴리스 빌드합니다.

2026-11-06 사용자 제공: AdMob에 생성한 `banner`(배너) 광고 단위 ID를 git에서 제외된 `admob.json`의 `ADMOB_BANNER_SESSION_ID`에 등록했습니다. 기존 앱 ID와 게시자 ID가 일치함을 확인했으며 다른 광고 설정은 유지했습니다. 실제 ID는 이 문서에 중복 저장하지 않습니다.

디버그·프로필 또는 배너 ID가 없는 빌드는 Google 테스트 배너를 사용합니다. 테스트 광고는 실제 광고 매출을 만들지 않습니다. 등록된 실제 ID는 이 설정 파일을 포함한 릴리스 빌드에 적용됩니다. AdMob 자동 갱신 설정 확인·변경, 실제 광고 송출 검증, Play Console 게시, 앱 배포는 수행하지 않았습니다. Play 상품 설명은 로컬 등록 문서와 앱의 4개 언어 안내를 갱신했으며 Console에는 별도로 반영해야 합니다.

일반 갱신은 SDK/AdMob 설정에 맡기며 앱의 250 ms 타이머 갱신마다 광고를 요청하지 않습니다. 수익·노출수는 AdMob의 이 배너 단위 보고서에서 확인합니다. 사용자군 분할이나 유지율 분석 SDK는 이번 변경 범위에 포함하지 않습니다.

## 검증

- `flutter test --no-pub test/session_banner_ad_test.dart test/purchases_test.dart test/widget_test.dart`
- `python3 tool/verify_session_banner.py`: 별도 임시 소스 복사본과 `.verification` 패키지로 에뮬레이터에서 Google 테스트 광고를 확인하고 `../design/session-banner-implementation-v1/`에 네이티브 캡처를 저장합니다. 실제 광고는 클릭하지 않습니다.
- SDK 경계 테스트: 동의 대기/거부, 이탈 뒤 늦은 동의, 무광고 응답, 타이머 갱신/일시정지 중 중복 요청 방지, 앱 비활성화, 시트 진입/복귀, 구매 복원, 4개 언어·큰 글자·하단 안전 영역.

공식 참고: [Flutter 배너](https://developers.google.com/admob/flutter/banner), [배치 안내](https://support.google.com/admob/answer/6275335), [자동 갱신 설정](https://support.google.com/admob/answer/3245199).
