# 캐릭터 선택 → 방 미리보기 → 홈 적용 화면 시안

2026-10-14. 사용자가 캐릭터 선택 화면 구성을 이미지로 요청해, 안경 쓴 사막여우를 고르는 하나의 흐름을 세 장으로 제작했습니다. built-in ImageGen의 독립적인 호출 세 번을 사용한 정적 UI 이미지 시안입니다.

이번 대화에서 표시된 생성 결과 순서입니다. 세 화면이 이어지는 하나의 흐름을 구성합니다.

| 표시 순서 | 화면 | 원본 PNG | 전체 생성 프롬프트 |
| --- | --- | --- | --- |
| 1 | 함께할 친구 선택 | [selection.png](selection.png) | [selection.prompt.txt](selection.prompt.txt) |
| 2 | 선택한 사막여우의 방 미리보기 | [preview.png](preview.png) | [preview.prompt.txt](preview.prompt.txt) |
| 3 | 사막여우가 적용된 홈 | [home.png](home.png) | [home.prompt.txt](home.prompt.txt) |

## 실제 첨부한 자료

- 선택 화면: `../immersive-room/reference.png`, `../animated-character-scene-set-v1/penguin.png`, `otter.png`, `squirrel.png`, `fennec.png`.
- 미리보기: `../animated-character-scene-set-v1/fennec.png`, `../immersive-room/reference.png`.
- 적용된 홈: `../animated-character-scene-set-v1/fennec.png`, `../calm-connected-motion/home-evening.png`.

## 흐름과 시각 확인

결과를 직접 확인했습니다. 선택 화면은 랫서팬더·펭귄·해달·다람쥐·사막여우 다섯 카드를 두 열로 배치합니다. 랫서팬더에는 현재 사용 중 표시, 사막여우에는 미리 볼 선택을 나타내는 체크를 넣었습니다. 아래의 ‘미리보기’가 다음 화면으로 이어집니다.

미리보기에서는 타이머 없이 방과 캐릭터를 크게 보여주고, 아래에 캐릭터 이름·방 테마·‘이 친구와 함께하기’ 버튼을 둡니다. 적용된 홈에는 사막여우 방과 기존 집중 타이머가 표시되며, ‘나의 책상’ 제목 옆의 작은 캐릭터 얼굴과 펼침 표시가 선택 화면의 진입점입니다. 좌우의 기존 시간 무작위 선택과 소리 버튼도 보여줍니다.

세 이미지는 UI 시안입니다. 현재 앱 코드·캐릭터 선택은 변경하지 않았으며 선택·미리보기·적용 기능은 아직 구현하지 않았습니다. 실제 적용 시 UI는 앱 코드로 렌더하고 장면 원화는 별도 에셋으로 제작합니다.
