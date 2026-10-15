# 캐릭터 이미지 사용 구조 설명 시안

2026-10-14. 사용자가 이미지 사용 구조를 그림으로 요청해, 사용자 흐름과 화면 구성 방식을 하나의 설명용 보드로 제작했습니다. built-in ImageGen을 사용했습니다.

- 원본 이미지: [usage-structure.png](usage-structure.png)
- 실제 사용한 전체 프롬프트: [usage-structure.prompt.txt](usage-structure.prompt.txt)

## 실제 첨부한 자료

- 친구 선택: `../character-selection-flow-v1/selection.png`
- 방 미리보기: `../character-selection-flow-v1/preview.png`
- 적용된 홈: `../character-selection-flow-v1/home.png`
- 선택한 사막여우 원본: `../bookish-fennec-app-concept-v1/selected-character.png`

## 그림의 의미

위쪽은 친구 선택 → 방 미리보기 → 내 책상에 적용 → 집중·휴식 흐름입니다. 아래쪽은 배경 그림 + 연결된 캐릭터 동작 그림 + 앞쪽 소품 + 앱에서 동작하는 타이머·버튼을 겹쳐 화면을 구성하는 개념입니다.

현재 앱의 `lib/study_scene.dart`와 `lib/main.dart`에서 배경·캐릭터·앞쪽 소품과 실제 UI를 구분해 렌더하는 구조를 확인해 설명에 반영했습니다. 새 캐릭터를 고르고 적용하는 화면과 새 사막여우의 휴식 포즈는 앞으로 제작할 동작의 설명용 표현입니다.

생성 결과를 직접 확인했습니다. 선택·미리보기·홈은 앞서 제작한 시안과 같은 사막여우, 방, 버튼 흐름을 사용합니다. 캐릭터는 선택한 둥근 안경과 큰 귀를 유지하며, 필기와 차 마시기 상태를 그림으로 구분합니다. 보드에 ‘앱 적용 전 구조 설명 시안’을 표시했습니다.

이 이미지는 앱에 바로 넣는 배경·스프라이트·버튼 에셋이나 실제 작동 화면이 아닙니다. 현재 앱 코드와 데이터는 변경하지 않았습니다.
