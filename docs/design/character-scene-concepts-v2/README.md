# 다람쥐·토끼 집중방 이미지 시안

2026-10-14. 카피바라 외의 후보를 비교하기 위해 routine_app의 탐험가 다람쥐와 우편배달부 토끼를 Focus Friend의 부드러운 2D 그림체로 재해석했습니다. 두 이미지는 built-in ImageGen의 독립적인 호출로 제작한 정적 시안입니다.

이번 대화에서 표시된 이미지 순서는 다음과 같습니다. 이전 고양이·해달·카피바라 시안은 `../character-scene-concepts-v1/`에 그대로 보관합니다.

| 이번 표시 순서 | 시안 | 이미지 | 전체 생성 프롬프트 |
| --- | --- | --- | --- |
| 1 | 탐험가 다람쥐의 숲속 작업방 | [explorer-squirrel.png](explorer-squirrel.png) | [explorer-squirrel.prompt.txt](explorer-squirrel.prompt.txt) |
| 2 | 우편배달부 토끼의 햇살 편지 서재 | [postman-rabbit.png](postman-rabbit.png) | [postman-rabbit.prompt.txt](postman-rabbit.prompt.txt) |

모든 호출에 현재 앱 화면 `../calm-connected-motion/home-evening.png`를 구도 참고로, 승인 디자인 `../immersive-room/reference.png`를 그림체 참고로 첨부했습니다. 각 캐릭터 원본도 실제로 첨부했습니다.

- 다람쥐: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/squirrel_explorer/v1/approved/idle.png`
- 토끼: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/rabbit_postman/v1/approved/idle.png`

두 결과를 직접 확인했습니다. 다람쥐의 도토리 모자·잎·크게 말린 꼬리·탐험 장비, 토끼의 긴 귀·크림색 털·빨간 스카프·갈색 가방을 유지하며, 연결된 팔로 노트에 필기하는 장면을 보여줍니다. 다람쥐는 지도와 나침반이 있는 숲속 방, 토끼는 편지와 정원 우체통이 있는 밝은 방입니다.

앱 코드와 현재 캐릭터 선택은 변경하지 않았습니다. 실제 적용 시에는 UI를 앱 코드로 렌더하고, 캐릭터·배경·소품과 애니메이션 프레임을 별도로 제작합니다. 토끼 이미지의 하단 두 비선택 탭은 아이콘만 표시되어 있습니다.
