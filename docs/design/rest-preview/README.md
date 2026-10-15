# 현재 휴식 UI 렌더

2026-10-08, 현재 Flutter 위젯을 수정 없이 렌더했습니다. 임의 시계를 주입한 메모리 저장소로 25분 집중 완료 → 5분 휴식 시작 → 28초 경과(04:32) → 휴식 완료를 실행했습니다. 일반 Android 앱과 저장 데이터에는 접근하지 않았습니다.

실행: `flutter test tool/capture_rest_preview_test.dart`

- 논리 화면 393×786, 2배 PNG 786×1572. Pretendard와 Material Icons 실폰트를 로드했습니다.
- 휴식 동안 DeskIllustration.studying=false, animate=false를 확인했습니다. 현재는 별도 휴식 애니메이션 없이 책상 앞 대기 자세를 표시합니다.
- 5분 경과 후 휴식 완료 상태를 표시하고, 정상 집중 완료 횟수가 추가되지 않음을 확인했습니다.
- `current-rest-flow.jpg`는 두 실제 렌더를 비율 유지 축소하여 나란히 배치한 설명용 이미지입니다. 위의 상태 제목은 이미지 보드의 설명이며 앱 UI에 추가한 문구가 아닙니다.
