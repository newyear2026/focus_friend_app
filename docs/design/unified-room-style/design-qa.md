# 배경·캐릭터 그림체 통일

2026-10-08. 사용자가 첨부한 현재 홈 화면에서 배경의 입체적인 광택과 캐릭터의 만화 윤곽선이 서로 달라 보이는 문제를 수정했다.

## 변경

- 승인된 랫서팬더를 기준으로 방과 화분·머그컵·조명을 다시 제작했다. 짙은 갈색 윤곽선, 무광 색연필/과슈 질감, 단순한 명암을 사용하고 나뭇결·잎사귀·금속의 사실적인 광택을 줄였다.
- 낮 배경을 기준으로 아침·저녁·밤의 조명만 바꿨다. 모든 방은 1182×1330 투명 PNG이고 가구 배치, 책상 높이, 캐릭터 좌표는 유지했다.
- 기존 캐릭터 시트, 눈, 부분 합성 모션과 22초 반복 시간은 변경하지 않았다.
- 소품에도 캐릭터와 같은 시간대 조명 색을 적용한다.
- 원본은 그대로 보관하고 앱은 `assets/images/storybook/`의 새 7개 PNG를 사용한다. UI와 타이머는 실제 Flutter 위젯이다.

## 제작 기록

Built-in Image Gen의 편집 모드를 사용했다. CLI/API 우회나 프로그램을 통한 재채색은 사용하지 않았다. `character-reference.png`는 기존 12프레임 시트의 첫 칸을 기계적으로 잘라 만든 스타일 참고이며 앱 에셋은 아니다.

| 앱 에셋 | 정확한 프롬프트 |
| --- | --- |
| [낮](../../../assets/images/storybook/room-day.png) | [room-day.prompt.txt](room-day.prompt.txt) |
| [아침](../../../assets/images/storybook/room-morning.png) | [room-morning.prompt.txt](room-morning.prompt.txt) |
| [저녁](../../../assets/images/storybook/room-evening.png) | [room-evening.prompt.txt](room-evening.prompt.txt) |
| [밤](../../../assets/images/storybook/room-night.png) | [room-night.prompt.txt](room-night.prompt.txt) |
| [화분](../../../assets/images/storybook/reward-plant.png) | [reward-plant.prompt.txt](reward-plant.prompt.txt) |
| [머그컵](../../../assets/images/storybook/reward-mug.png) | [reward-mug.prompt.txt](reward-mug.prompt.txt) |
| [조명](../../../assets/images/storybook/reward-lamp.png) | [reward-lamp.prompt.txt](reward-lamp.prompt.txt) |

## 검증

- `flutter analyze`: 문제 없음.
- `flutter test --no-pub`: 기존 테스트 41개 통과. 얼굴·귀·꼬리의 고정 렌더링, 집중/정지/재개, 기록 저장 검사 포함.
- `flutter test --no-pub tool/capture_storybook_preview_test.dart`: 네 시간대에 소품을 모두 표시한 실제 `DeskIllustration` 위젯 렌더링 통과. 새 PNG 7개는 RGBA이며 실제 투명 영역을 포함한다.
- [낮 합성](scene-day.png), [밤 합성](scene-night.png), [아침 합성](scene-morning.png), [저녁 합성](scene-evening.png)에서 캐릭터와 책상·소품의 위치 및 그림체를 검토했다.

- 안드로이드 통합 테스트 통과: 네 시간대의 홈, 필기·생각·페이지 넘김, 일시정지/재개, 다음 반복, 완료와 화분 보상, 휴식과 홈 복귀. 별도 패키지와 메모리 저장소를 사용했다. [실행 로그](integration.log), [실행 영상](native-animation.mp4).
- [집중 중 실제 화면](writing.png)과 [밤 홈 화면](home-night.png)을 확인했다. 일시정지 화면 두 장은 2초 간격으로 픽셀이 동일했다. 영상의 타이머는 검증용 고정 시각을 사용하므로 25:00으로 유지된다.
- 검증용 소스 복사본과 현재 앱 소스/새 에셋이 동일함을 확인하고 일반 개발 앱을 데이터 보존 방식(`adb install -r`)으로 업데이트했다. 설치 전후 저장소 본문 해시가 동일하며 기존 기록 7개가 유지됐다. [저장 상태 검증](data-preservation.json).
- [설치된 개발 앱의 실제 홈](installed-app.png)에서도 새 방과 보상 화분이 표시되는 것을 확인했다.
