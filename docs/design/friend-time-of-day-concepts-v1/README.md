# 친구별 아침·점심·저녁 배경 시안

2026-10-14. 사용자 요청에 따라 앱 적용 전에 검토할 이미지 시안을 제작했습니다. built-in ImageGen을 사용했으며, 네 친구를 각각 독립 호출로 생성했습니다. 각 보드의 왼쪽부터 아침·점심·저녁입니다.

| 캐릭터 | 이미지 시안 | 실제 생성 프롬프트 |
| --- | --- | --- |
| 펭귄 | [penguin.png](penguin.png) | [penguin.prompt.txt](penguin.prompt.txt) |
| 해달 | [otter.png](otter.png) | [otter.prompt.txt](otter.prompt.txt) |
| 다람쥐 | [squirrel.png](squirrel.png) | [squirrel.prompt.txt](squirrel.prompt.txt) |
| 사막여우 | [fennec.png](fennec.png) | [fennec.prompt.txt](fennec.prompt.txt) |

## 실제 사용한 참고 이미지

각 호출에 해당하는 현재 앱 이미지 하나를 직접 첨부했습니다.

- 펭귄: ../../../assets/images/friends/penguin-scene.png
- 해달: ../../../assets/images/friends/otter-scene.png
- 다람쥐: ../../../assets/images/friends/squirrel-scene.png
- 사막여우: ../../../assets/images/friends/fennec-scene.png

## 시안 방향과 확인

같은 캐릭터와 방을 기준으로 창밖 시간대, 자연광, 실내 조명의 대비를 바꿉니다. 펭귄은 설경, 해달은 바다, 다람쥐는 숲, 사막여우는 사막과 오아시스를 유지했습니다. 네 생성 결과를 직접 확인했으며, 시간대 라벨과 캐릭터의 주요 특징이 표시됩니다.

이 파일들은 분위기 비교용 정적 이미지 보드입니다. 생성 과정에서 원본 대비 작은 작화·비례 차이가 있으며, 앱에서 바로 교체할 개별 배경 자산이나 애니메이션 프레임으로 검증된 결과는 아닙니다. 앱 코드, 실행용 이미지, 시간대 설정은 변경하지 않았습니다. 랫서팬더는 기존 구현을 참고했으며 새 시안을 생성하지 않았습니다.
