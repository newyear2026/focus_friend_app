# 기존 앱 캐릭터의 집중방 장면 시안

2026-10-14. 기존 routine_app과 Sobrita 캐릭터의 특징을 유지하면서 Focus Friend의 부드러운 2D 그림체와 타이머 화면 구도로 재해석한 정적 이미지 시안입니다. 앱 코드나 현재 선택된 캐릭터를 변경하지 않았습니다.

세 이미지는 각각 독립적인 built-in ImageGen 호출로 제작했습니다. 대화에 표시된 결과 순서가 아래 순서와 같습니다.

| 표시 순서 | 시안 | 이미지 | 실제 사용한 전체 프롬프트 |
| --- | --- | --- | --- |
| 1 | 유성 관측 고양이의 별밤 서재 | [stargazer-cat.png](stargazer-cat.png) | [stargazer-cat.prompt.txt](stargazer-cat.prompt.txt) |
| 2 | 햇살 해달의 바닷가 작업방 | [sunshine-otter.png](sunshine-otter.png) | [sunshine-otter.prompt.txt](sunshine-otter.prompt.txt) |
| 3 | Tranqui의 숲속 서재 | [tranqui-capybara.png](tranqui-capybara.png) | [tranqui-capybara.prompt.txt](tranqui-capybara.prompt.txt) |

## 첨부한 원본 자료

모든 호출에 현재 앱 화면 `../calm-connected-motion/home-evening.png`를 구도 참고로, 기존 승인 디자인 `../immersive-room/reference.png`를 그림체 참고로 첨부했습니다. 각 캐릭터 원본도 해당 호출에 실제로 첨부했습니다.

- 고양이: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/cat_stargazer/v1/approved/idle.png`
- 해달: `/Users/jaewook/dev_app/routine_app/flutter_app/assets/characters/otter_seaside/v1/approved/idle.png`
- 카피바라: `/Users/jaewook/dev_app/sobra_app/design/store/iap-icons/sobra.character.capybara-512.png`

## 시각 확인

세 결과를 직접 확인했습니다. 고양이의 남색 털·금색 눈·별 모자와 망토, 해달의 황금빛 털·흰 수염과 조개, Tranqui의 긴 주둥이·작은 둥근 귀·청록색 목걸이와 금색 버클을 유지합니다. 세 이미지 모두 책상에서 필기하는 연결된 상반신과 앱의 기존 타이머·시간 선택·시작 버튼·하단 내비게이션을 포함합니다.

애니메이션 프레임이나 실행 가능한 새 테마 팩은 아직 제작하지 않았습니다. 생성형 이미지 시안이므로 실제 적용 시에는 UI를 앱 코드로 렌더하고 캐릭터·배경·소품을 별도 에셋으로 제작합니다.
