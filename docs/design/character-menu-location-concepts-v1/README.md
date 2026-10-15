# 친구 메뉴 위치 이미지 시안 3종

2026-10-14. 사용자가 친구 선택 메뉴 위치를 세 가지 이미지로 요청해, 같은 캐릭터와 앱 디자인을 기준으로 상단 바로가기·하단 탭·설정 항목을 비교했습니다. built-in ImageGen의 독립적인 호출 세 번을 사용했습니다.

이번 대화에서 표시된 생성 결과 순서입니다. 이후 사용자의 번호 선택은 이 순서에 대응합니다.

| 표시 순서 | 메뉴 위치 | 원본 PNG | 전체 생성 프롬프트 |
| --- | --- | --- | --- |
| 1 | 홈 제목 옆 ‘친구’ 버튼 | [header-friend.png](header-friend.png) | [header-friend.prompt.txt](header-friend.prompt.txt) |
| 2 | 하단 ‘친구’ 탭 | [bottom-friend-tab.png](bottom-friend-tab.png) | [bottom-friend-tab.prompt.txt](bottom-friend-tab.prompt.txt) |
| 3 | 설정 첫 항목 ‘친구와 방’ | [settings-friend-row.png](settings-friend-row.png) | [settings-friend-row.prompt.txt](settings-friend-row.prompt.txt) |

## 실제 첨부한 자료

상단·하단 시안에는 `../character-selection-flow-v1/home.png`와 `../bookish-fennec-app-concept-v1/selected-character.png`를 첨부했습니다. 설정 시안에는 실제 현재 설정 화면 `../competitive-review-2026-10-14/fresh/settings.png`와 같은 사막여우 원본을 첨부했습니다.

## 비교 기준과 확인

세 결과를 직접 확인했습니다. 상단 안은 작은 캐릭터 얼굴·‘친구’ 글자·펼침 표시를 하나의 버튼으로 두고 기존 하단 세 항목을 표시합니다. 하단 안은 헤더의 친구 버튼을 없애고 책상·친구·기록·설정 네 항목을 표시합니다. 설정 안은 현재 설정 화면의 첫 행에 친구와 방을 넣고 세 하단 항목과 기존 설정 내용을 보여줍니다. 각 안의 친구 메뉴 진입점은 한 곳입니다.

홈에서 친구를 고른 뒤 집중을 시작하는 흐름을 기준으로는 상단 안을 우선 추천합니다. 하단 안은 주요 메뉴와 나란히 보여 주는 위치이며, 설정 안은 홈 화면의 별도 진입 버튼 없이 설정 안에서 친구와 방을 찾는 위치입니다. 이는 디자인 판단이며 사용자 테스트 결과가 아닙니다.

현재 앱 코드·캐릭터 선택·내비게이션은 변경하지 않았습니다. 세 이미지는 적용 전 정적 시안이며 실제 동작 기능은 아직 구현하지 않았습니다.
