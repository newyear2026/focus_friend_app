# 업데이트 소식

2026-11-05. 사용자가 선택한 크림색 하단 시안 `selected-mockup.png`를 실제 Flutter 화면으로 구현했습니다. 선택 시안은 built-in Image Gen 결과이며, 실행 화면은 목업 이미지를 붙인 것이 아니라 텍스트·아이콘·버튼·스크롤로 구성됩니다.

## 표시 규칙

- 기존 설치에서 더 높은 Android 빌드로 업데이트한 뒤, 복구·언어·광고 동의 처리가 끝나고 책상이 대기 상태일 때 한 번 표시합니다.
- 처음 설치했을 때는 현재 빌드를 조용히 저장합니다. 기능 도입 이전 설치는 Android의 최초 설치 시각과 마지막 업데이트 시각으로 구분합니다.
- 집중·휴식·체험, 일시정지, 아직 닫지 않은 완료 화면, 다른 탭·모달, 백그라운드에서는 자동 표시를 보류합니다. 소리 설정의 상태 조회 중에도 끼어들지 않습니다.
- `내 책상으로`, X, 바깥 터치, 아래로 밀기, 뒤로 가기로 닫으면 읽음 처리합니다. 설정의 `업데이트 소식`에서 언제든 다시 열 수 있습니다.
- 읽음 기록은 별도 SharedPreferences에 저장합니다. 집중 기록·설정·구매 상태는 변경하지 않습니다. 다운그레이드 때 읽음 빌드 번호를 낮추지 않습니다.
- 저장 실패 시 현재 실행에서 반복 표시하지 않으며 다음 실행에 재시도합니다. 버전 조회 실패 시 자동 표시는 보류하고 앱 복귀 시 다시 조회합니다. 설정의 수동 진입은 계속 사용할 수 있습니다.
- 이 기능은 **설치된 업데이트의 변경 내용 안내**입니다. 스토어 최신 버전 조회·설치 권유·강제 업데이트·원격 푸시 기능은 포함하지 않습니다.

## 릴리스할 때

1. `pubspec.yaml`의 버전/빌드 번호를 올립니다. 안내 여부는 하드코딩한 문구 버전이 아니라 실제 설치된 Android 빌드 번호를 사용합니다.
2. `lib/l10n/app_{ko,en,ja,es}.arb`의 `updateNewsMotion*`, `updateNewsRecords*`, `updateNewsFixes*` 문구를 해당 릴리스의 실제 변경 내용으로 갱신합니다. 현재 문구는 사용자가 선택한 시안의 세 항목입니다.
3. `flutter gen-l10n` 후 테스트하고 배포합니다. 스토어에 적은 릴리스 노트를 자동으로 가져오지는 않습니다.

## 구현과 검증

- UI: `lib/update_news_sheet.dart`
- 버전/읽음 처리: `lib/update_news.dart`, Android `AppUpdateNews`
- 표시 시점과 설정 진입: `lib/main.dart`
- 한국어·영어·일본어·스페인어, 작은 화면·큰 글자·가로 화면을 지원합니다. 내용은 스크롤하고 닫기와 하단 버튼은 고정합니다.
- 전체 단위/위젯 테스트 199개 통과. 새 기능은 저장 10개, 흐름 11개, 화면 7개 테스트가 포함됩니다.
- Android 에뮬레이터 `emulator-5554`의 별도 `.verification` 패키지에서 실제 빌드 정보 조회, 영구 읽음 저장, 재조회, 설정 재진입 테스트 통과.
- `flutter analyze --no-pub`: 문제 없음. Android 디버그 APK 빌드 통과.
- 화면 캡처: `flutter test --no-pub tool/capture_update_news_test.dart`
- 실제 Android 검증: 먼저 `flutter build apk --debug --no-pub --dart-define=FOCUS_FRIEND_VERIFICATION=true`, 다음 `flutter test --no-pub integration_test/update_news_test.dart -d emulator-5554 --dart-define=FOCUS_FRIEND_VERIFICATION=true`.

기기 테스트의 첫 시도는 설정 항목이 내비게이션 경계에 걸쳐 탭되지 않아 실패했습니다. 테스트 스크롤을 화면 중앙 정렬로 보정한 뒤 통과했습니다. 사용자 앱이나 연결된 실제 휴대폰에 설치·데이터 변경은 하지 않았습니다.

실제 화면은 `sheet.png`, 시안과 같은 비율은 `sheet-reference-size.png`, 큰 글자는 `sheet-compact-large-text.png`, 가로 화면은 `sheet-landscape.png`입니다. 시각 비교는 [design-qa.md](design-qa.md)에 있습니다.
