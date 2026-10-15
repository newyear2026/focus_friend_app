# 네 친구 모션 포즈 시안

기존 앱에 적용한 캐릭터와 방 그림을 참조하여 built-in ImageGen으로 만든 이미지 네 장입니다. 각 그림은 왼쪽부터 **필기 → 페이지 넘기기 → 휴식**을 보여줍니다.

| 캐릭터 | 이미지 원본 | 생성 프롬프트 | 휴식 동작 |
|---|---|---|---|
| 펭귄 | [penguin.png](penguin.png) | [penguin.prompt.txt](penguin.prompt.txt) | 양 날개로 찻잔 감싸기 |
| 해달 | [otter.png](otter.png) | [otter.prompt.txt](otter.prompt.txt) | 두 손으로 찻잔 들기 |
| 다람쥐 | [squirrel.png](squirrel.png) | [squirrel.prompt.txt](squirrel.prompt.txt) | 앉아서 작게 기지개 켜기 |
| 사막여우 | [fennec.png](fennec.png) | [fennec.prompt.txt](fennec.prompt.txt) | 한 손으로 안경 고쳐 쓰기 |

각 원본은 1536×1024 PNG입니다. 입력 그림은 `assets/images/friends/{penguin,otter,squirrel,fennec}-scene.png`이며, 얼굴·의상·소품·방 분위기를 유지하도록 전달했습니다. 생성 출처와 파일 검증값은 [manifest.json](manifest.json)에 있습니다.

현재 결과물은 동작 방향을 비교하는 **정지 시안**입니다. 프레임별 좌표·크기·책 기준점이 검증된 재생용 스프라이트나 실제 애니메이션은 아닙니다. 앱 코드와 기존 실행용 자산은 변경하지 않았습니다. 구현 단계에서는 캐릭터 크기와 어깨·팔 연결을 고정하고, 동작 사이 중간 프레임과 책을 닫고 여는 전환을 추가해야 합니다.
