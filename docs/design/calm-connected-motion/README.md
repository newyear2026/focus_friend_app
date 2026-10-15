# 편안하게 연결되는 필기와 페이지 넘김

필기 그림을 교체할 때 얼굴·몸통·꼬리까지 흔들려 보이던 부분을 수정했습니다. 기본 원화를 유지하고, 연결된 필기 팔과 연필 영역의 픽셀만 자세별 원화로 교체합니다.

- 책·표지·글씨의 위치는 하나의 고정 좌표를 사용합니다. 캐릭터 원화 전체를 바꾸면서 책까지 이동하던 이전 방식과 달리, 연결된 캐릭터만 교체합니다.
- 필기 중 기본 그림의 얼굴·몸통·꼬리를 유지합니다. 연결된 팔과 연필 영역에는 동일한 좌표에 있는 완성 원화의 해당 영역을 사용합니다. 원화를 겹쳐 그리지 않고 영역 안팎을 나눠 그려, 연필과 팔의 선이 이중으로 남지 않도록 했습니다.
- 필기는 작은 왕복 동작 6장으로 4초 동안 반복합니다. 이전 3초에서 33% 길게 조정하고, 이동 중간보다 방향을 바꾸는 구간을 조금 더 길게 잡았습니다. 매 주기 시작·끝에 각각 약 0.58초 멈추던 준비·복귀 구간을 없앴습니다.
- 36초 필기 뒤 5.5초 동안 페이지를 넘깁니다. 이전 4초보다 37.5% 길게 조정했습니다. 종이의 책등 두 점은 고정되고, 모서리는 손 위치를 따릅니다. 종이는 몸 앞에서 보이고 손에 가려지도록 깊이를 맞췄습니다.
- 손을 뻗고 돌아오는 연결된 상반신 원화와 추가 중간 자세를 실제 손 위치에 맞춰 선택했습니다. 원화는 총 37장이고, 30장의 서로 다른 원화를 사용합니다. 종이를 내려놓는 자세를 돌아오는 구간에도 재사용하므로 시트에는 38개 항목이 있습니다. 페이지 넘김 시작과 끝은 필기의 **동일한 원화**로 연결합니다. 필기 4번 그림과 종이를 드는 25번 그림의 배경 잔여물도 정리했습니다.
- 전체 주기는 41.5초입니다. 일시정지·백그라운드·숨겨진 화면에서는 그림과 글씨, 재생 위치를 보존합니다. 종료·완료·동작 줄이기에서는 기본 자세를 사용합니다.

## 결과

- [몸 고정 후 전체 41.5초 영상](stable-writing-full-cycle.mp4)과 [전체 GIF](stable-writing-full-cycle.gif): 앱과 동일한 Flutter painter로 렌더링했습니다. 필기부터 시작하며 전체 주기가 반복됩니다.
- [브라우저 재생 미리보기](index.html), [앱 전체 화면](home-evening.png), [페이지 넘김 화면](turning-page.png)
- [새 렌더링 프레임 정보](stable-writing-rendered-frames.json): 499프레임. 마지막 자세와 빈 페이지가 다음 주기로 연결됩니다.
- [필기 중 픽셀 비교](stable-writing-pixel-check.json): 필기 432프레임 전체에서 얼굴·몸통·꼬리의 검사 영역 픽셀이 동일합니다. 별도 회귀 테스트는 팔·연필 영역 바깥의 전체 렌더링 픽셀을 비교하며, 영역 안의 필기 동작은 계속 변하는지도 확인합니다.
- 비교용 이전 영상: [몸 전체 원화가 바뀌던 41.5초 영상](slow-full-cycle.mp4), [이전 40초 영상](full-cycle.mp4).

이 영상과 GIF는 Flutter 테스트로 그린 앱 렌더링이며 Android 실시간 녹화가 아닙니다. 손으로 그린 프레임 교체 방식이라 원화의 선과 질감에는 작은 변화가 남습니다.

## 원화와 제작 프롬프트

Built-in **image_gen**으로 원화를 편집·생성했습니다. Python/Pillow는 완성 그림을 추출하고 전체 위치·크기를 정렬한 뒤 시트로 포장하는 데만 사용했습니다. 별도 관절 스프라이트, 회전, 워핑이나 크로스페이드는 사용하지 않습니다. 필기는 Flutter Canvas에서 기본 완성 원화와 자세별 완성 원화를 동일한 크기·위치에 그리되, 연결된 팔과 연필의 영역 안팎을 나눠 그립니다. 원본 이미지 파일은 변경하지 않습니다. 종이는 고정된 책등에 연결되는 Flutter Canvas 도형으로 그립니다.

| 원화 | 정확한 프롬프트 |
|---|---|
| [책을 뺀 필기 6장](writing-body-source.png) | [필기 프롬프트](writing-body.prompt.txt) |
| [첫 넘김 6장](turn-body-clean-1-source.png), [마지막 넘김 6장](turn-body-clean-2-source.png) | [첫 편집](turn-body-1.prompt.txt), [두 번째 편집](turn-body-2.prompt.txt), [종이 제거](remove-moving-paper.prompt.txt) |
| [연결 자세 6장](arm-bridges-source.png) | [연결 자세 프롬프트](arm-bridges.prompt.txt) |
| [추가 중간 자세 6장](page-inbetweens-source.png) | [중간 자세 프롬프트](page-inbetweens.prompt.txt) |
| [고정된 책](fixed-notebook.png) | [책 프롬프트](fixed-book.prompt.txt) |
| [추가 자세 6장](slow-inbetweens-source.png): 실제 위치에 맞춰 31·33·34번을 사용 | [중간 자세 프롬프트](slow-inbetweens.prompt.txt) |
| [내려놓기와 돌아오기 연결 자세](settling-bridge-source.png): 36·37번은 동일한 그림 | [연결 자세 프롬프트](settling-bridge.prompt.txt) |
| [배경 정리](alpha-cleanup-source.png): 왼쪽 그림만 4번으로 사용 | [배경 정리 프롬프트](alpha-cleanup.prompt.txt) |
| [종이 드는 자세의 배경 정리](lift-cleanup-source.png): 25번으로 사용 | [종이 드는 자세 프롬프트](lift-cleanup.prompt.txt) |

앱 에셋:
`assets/images/immersive/redpanda-slow-connected-body-38.png` (3072×3584, 6×7, 512px 셀, 마지막 4칸은 비어 있음),
`assets/images/immersive/redpanda-fixed-notebook.png`.

[앱용 원화 시트](body-atlas-slow.png), [정렬·원화 출처 정보](slow-manifest.json).
재포장: `tool/package_slow_reference.py`. 기존 원화 30장과 원본 프롬프트도 보존했습니다.
코드: `lib/reference_companion.dart`, `lib/reference_study_animation.dart`, `lib/reference_notebook_page.dart`.

## 검증과 설치

- `flutter test --no-pub test tool/capture_reference_page_turn_test.dart tool/capture_calm_scene_test.dart`: **52개 통과** (기능·회귀 50개 + 렌더링 2개). 필기 영역 바깥의 몸 고정과 영역 안의 필기 동작, 책의 고정 위치, 글씨 초기화, 반복 경계, 멈춤·재개, 동작 줄이기 및 기존 기능을 검사했습니다. [최종 테스트 로그](stable-writing-tests.log)
- `flutter analyze --no-pub`: 문제 없음. [분석 로그](stable-writing-analyze.log)
- 전체 41.5초 주기를 499프레임으로 렌더링하고, 필기 432프레임에서 얼굴·몸통·꼬리의 검사 영역 픽셀이 동일한지 확인했습니다.
- 실제 앱 레이아웃의 대기·집중·넘김·일시정지·재개 화면은 테스트 저장소로 캡처했습니다.
- 브라우저에서 영상 길이 41.5초, 1배속, 반복 재생과 재생 오류 없음을 확인했습니다.
- 최종 렌더러 소스가 빌드 작업공간과 일치하고, 원화 SHA-256이 APK 내부 에셋과 일치함을 확인한 뒤 ARM64 개발 APK를 **emulator-5554**에 `adb install -r`로 업데이트했습니다. [APK 정보](stable-writing-apk.json), [빌드 로그](stable-writing-build.log)
- 설치 전후 저장 상태를 비교해 기존 기록 보존을 확인했습니다. [저장 상태 비교](stable-writing-data-preservation.json)
