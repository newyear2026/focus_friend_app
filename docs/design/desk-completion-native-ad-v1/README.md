# 책상 집중 완료 후 네이티브 광고 시안

기존 책상의 렛서팬더와 노을 방을 바탕으로 만든 집중 완료 화면 제안입니다. 완료 메시지와 이번 집중·오늘 누적 기록을 먼저 보여주고, 아래에 네이티브 광고 카드 한 개와 다음 집중 시작 버튼을 배치합니다.

- 결과: [desk-completion-native-ad.png](desk-completion-native-ad.png)
- 최종 생성 프롬프트: [prompt.txt](prompt.txt)
- 책상 원본: [redpanda-home.png](../friend-picker-implementation/redpanda-home.png)
- 광고 카드 참고: [month-native-ad.png](../native-ad-records-placement-v1/month-native-ad.png)
- 제작: 내장 ImageGen, 두 참고 이미지를 첨부한 단일 화면 생성

광고 카드에는 `광고` 표시, 가상 광고주, 광고 정보 아이콘과 별도의 `자세히 보기` 버튼을 표시했습니다. 광고 내용은 예시입니다. 광고를 보거나 클릭해야 다음 세션을 시작할 수 있는 보상·차단 흐름은 제안하지 않습니다.

완료 화면, 버튼 동작과 광고 SDK를 구현한 결과가 아닌 이미지 시안입니다. 앱의 기존 집중·휴식 전환 로직은 수정하지 않았습니다. 실제 구현 시 휴식 전환과의 연결 및 SDK 광고 요소 배치를 검토해야 합니다.
