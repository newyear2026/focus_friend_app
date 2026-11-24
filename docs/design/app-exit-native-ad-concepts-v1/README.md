# 앱 종료 네이티브 광고 팝업 시안

2026-11-07. 내장 ImageGen으로 만든 독립 이미지 3개입니다. 아래 번호는 채팅에 생성 이미지가 표시된 순서와 같습니다.

| 번호 | 시안 | 이미지 |
| --- | --- | --- |
| 1 | 포근한 중앙 팝업 | [이미지](01-center-dialog.png) |
| 2 | 책상 위 하단 시트 | [이미지](02-bottom-sheet.png) |
| 3 | 친구의 작은 작별 인사 | [이미지](03-friend-goodbye.png) |

랜덤포커스의 `lib/widgets/app_exit_dialog.dart`, `lib/pages/home_page.dart` 및 `output/exit-ad-preview/native-exit-medium-applied-ko.png`, `native-exit-ko.png`를 확인했습니다. 종료 확인 → 네이티브 광고 → 구분선 → 취소/종료 흐름을 참고했습니다.

현재 앱의 `friend-picker-implementation/redpanda-home.png`와 `update-news-v1/sheet.png`를 시각 참고로 첨부했습니다. 따뜻한 크림색 표면, 갈색 글자, 호박색 버튼과 기존 랫서팬더 방 일러스트를 유지했습니다. 전체 생성 프롬프트와 첨부 이미지 경로는 [prompts.json](prompts.json)에 있습니다.

광고는 가상 노트 상품 예시입니다. 세 시안 모두 광고 표시, 예시 광고주, 광고 정보 아이콘, 별도 광고 CTA와 독립된 취소/앱 종료 버튼을 포함합니다. 이미지 시안만 제작했으며 앱 코드나 광고 SDK는 변경하지 않았습니다.

구현 시 참고: 현재 앱은 미디어를 포함한 medium 네이티브 템플릿을 사용합니다. 3번의 가로형 광고는 실제 MediaView를 포함하는 맞춤 레이아웃 또는 지원되는 광고 형식에 맞춰 구성해야 합니다. 랜덤포커스의 사전 로딩·광고 실패 시 생략·버튼 위치 유지 흐름과 현재 앱의 광고 제거 구매 상태를 반영할 수 있습니다. 시안의 광고 정보 아이콘은 예시이며 실제 구현에서는 SDK가 제공하는 요소를 사용합니다.
