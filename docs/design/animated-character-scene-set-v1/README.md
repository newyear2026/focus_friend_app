# 2D 애니메이션풍 캐릭터 장면 시안 4종

2026-10-14. 사용자 요청에 따라 펭귄·해달·다람쥐·사막여우를 같은 공통 작화 지침과 앱 화면 구도로 제작한 정적 이미지 시안입니다. 부드러운 명암과 선명한 윤곽, 읽기 쉬운 색 면으로 기존 랫서팬더와 어울리는 2D 애니메이션풍을 목표로 했습니다. built-in ImageGen의 독립적인 호출 네 번을 사용했습니다.

이번 대화에서 표시된 생성 결과 순서는 다음과 같습니다.

| 표시 순서 | 시안 | 원본 PNG | 전체 생성 프롬프트 |
| --- | --- | --- | --- |
| 1 | 펭귄의 겨울 서재 | [penguin.png](penguin.png) | [penguin.prompt.txt](penguin.prompt.txt) |
| 2 | 해달의 바닷가 작업방 | [otter.png](otter.png) | [otter.prompt.txt](otter.prompt.txt) |
| 3 | 다람쥐의 숲속 기록방 | [squirrel.png](squirrel.png) | [squirrel.prompt.txt](squirrel.prompt.txt) |
| 4 | 안경 사막여우의 노을빛 서재 | [fennec.png](fennec.png) | [fennec.prompt.txt](fennec.prompt.txt) |

## 실제 첨부한 참고 자료

모든 호출에 공통 작화와 구도 참고로 `../immersive-room/reference.png`를 첨부했습니다. 캐릭터 원본은 각 호출에 하나씩 실제로 첨부했습니다.

- 펭귄: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/penguin_snow_walk/v1/approved/idle.png`
- 해달: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/otter_seaside/v1/approved/idle.png`
- 다람쥐: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/squirrel_explorer/v1/approved/idle.png`
- 사막여우: `../bookish-fennec-app-concept-v1/selected-character.png`

## 시각 확인

네 결과를 직접 확인했습니다. 펭귄은 눈꽃 목도리·이마 무늬·주황색 부리, 해달은 흰 수염·금빛 털·조개, 다람쥐는 도토리 모자·잎·크게 말린 꼬리·탐험 장비, 사막여우는 사용자가 선택한 둥근 안경·큰 귀·부드러운 눈매를 유지합니다. 네 장 모두 책상에서 연결된 상반신으로 필기하는 모습과 기존 타이머·시간 선택·시작 버튼·세 하단 탭 구도를 포함합니다.

이미지 시안이며 실제 애니메이션 영상이나 프레임 세트는 아닙니다. 현재 앱 코드·캐릭터 선택은 변경하지 않았습니다. 실제 적용 시 UI는 앱 코드로 렌더하고 배경·소품·캐릭터 포즈를 별도 에셋으로 제작합니다.
