# 글씨와 연결된 페이지 넘김

현재 24장 필기에 장식용 손글씨와 12장 페이지 넘김을 추가했습니다. 3초 필기를 6번 반복하는 18초 동안 왼쪽 페이지에 짧은 획 12개가 쌓이고, 이어서 1.5초 동안 오른쪽 종이를 왼쪽으로 넘깁니다. 총 19.5초 주기입니다. 종이가 기존 페이지를 덮는 부분부터 글씨를 가리고, 새 페이지에서는 처음부터 씁니다.

글씨는 실제 문장이나 사용자의 메모가 아닌 짧은 손글씨 획입니다. Flutter Canvas에서 책의 노출된 종이 영역에만 그립니다. 집중 기록과 타이머 저장은 변경하지 않습니다. 페이지를 넘기는 중에도 일시정지·백그라운드·숨겨진 화면에서 같은 자세를 유지하고 재개합니다. 동작 줄이기, 완료, 다음 집중의 초기화는 기존 동작을 따릅니다.

## 원화와 제작 방식

Built-in `image_gen`으로 현재 캐릭터의 첫 번째·마지막 필기 그림을 참조하여 6장씩 두 시트를 생성했습니다. 얼굴·옷·꼬리·몸통·어깨·팔·손·연필·책이 연결된 전체 원화입니다. Python/Pillow는 완성된 그림의 추출, 전체 위치·크기 정렬, 시트와 ZIP 포장에만 사용했습니다. 팔을 떼어 붙이거나 관절을 변형하지 않습니다. 손으로 그린 선·질감과 책 모양에는 작은 변화가 남습니다.

- [처음 6장 원본](source-1.png), [정확한 제작 프롬프트](source-1.prompt.txt)
- [마지막 6장 원본](source-2.png), [정확한 제작 프롬프트](source-2.prompt.txt)
- [앱용 12장 시트](page-turn-atlas.png): 2048×1536, 셀 512×512, 실제 투명 알파.
- [12장 PNG ZIP](page-turn-12-frames.zip), [위치·크기·종이 영역 정보](manifest.json)
- [Flutter에서 그린 전체 19.5초 영상](full-cycle.mp4)
- [마지막 필기와 페이지 넘김 4.5초 발췌 GIF](writing-and-page-turn.gif)
- [글씨가 쌓인 모습](writing.png), [페이지 넘김](page-turn.png), [새 페이지](fresh-page.png)
- [재생·정지·시간 슬라이더 미리보기](index.html). 서버 루트를 `docs/design`으로 두면 이전 필기 시트도 함께 읽습니다.
- 앱 에셋: `../../../assets/images/immersive/redpanda-connected-page-turn-12.png`
- 코드: `../../../lib/reference_study_animation.dart`, `../../../lib/reference_companion.dart`, `../../../lib/reference_notebook_ink.dart`
- 재포장: `../../../tool/package_reference_page_turn.py`
- Flutter 렌더링: `flutter test tool/capture_reference_page_turn_test.dart`.

## 검증

- 서로 다른 완성 그림 12장과 투명 알파를 확인했습니다.
- `flutter analyze --no-pub`: 오류 없음.
- `flutter test --no-pub`: 48개 통과. 기존 대기·일시정지·백그라운드·동작 줄이기와 페이지 넘김 도중 멈춤·재개·새 페이지 초기화를 포함합니다.
- `flutter test test/reference_companion_test.dart tool/capture_reference_page_turn_test.dart`: 마지막 종이 가림 보정 후 관련 테스트와 전체 주기 렌더링 통과. 실제 Flutter painter에서 넘김 그림 12장 모두 관찰하고 주기 끝의 빈 페이지를 확인합니다.
- 브라우저 미리보기에서 페이지를 들어 올리는 자세와 글씨를 확인했습니다. 영상·GIF는 Flutter 테스트가 렌더링한 그림을 12fps로 포장한 것이며 Android 실시간 화면 녹화는 아닙니다.
- 일반 개발 APK를 기존 에뮬레이터에 업데이트했습니다. [집중 기록 보존 비교](data-preservation.json).

Image Gen 원본 파일:
`exec-e258bdf7-b7f2-43bf-9bc4-3314bf23752e.png`,
`exec-c21588e3-ee0f-46c4-915d-3eacd8b2e8f1.png`.
