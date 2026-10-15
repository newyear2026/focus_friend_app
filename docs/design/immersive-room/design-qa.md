# 몰입형 2D 책상 화면 QA

**Findings**

- 최종 비교에서 미해결 P0/P1/P2 없음. 제목·타이머·캐릭터·선택 버튼·집중 시작·하단 내비게이션의 계층과 배치가 공유 시안과 일치한다.
- [P3] 필기 캐릭터의 공책과 손 모양은 정지 시안과 정확히 같지 않다. 앱에서는 기존 실제 필기·생각·페이지 넘김 애니메이션을 사용하므로 정지 그림을 그대로 넣으면 동작이 사라진다. 현재 공책의 크기와 위치는 버튼 및 `오늘의 집중`을 가리지 않는다.
- [P3] Android 실기기 캡처에는 상태 표시줄과 시스템 제스처 바가 보인다. 시안은 이 OS 영역이 없는 컨셉 이미지다. 앱 내용과 조작부를 가리지는 않는다.

**시각 근거와 조건**

- 원본: [공유 시안](reference.png), 853×1844 px.
- 구현: [최종 Flutter 렌더](home-evening.png), 780×1688 px, 논리 화면 390×844 dp, devicePixelRatio 2. 원본과 구현을 각각 390×844 px로 정규화해 [전체 비교](comparison-final.jpg)와 [상단·하단 확대 비교](detail-final.jpg)를 열어 확인했다.
- 실제 Android 화면: [설치 앱 캡처](installed-app-final.png), 1080×2160 px. 픽스처 렌더는 25:00 준비 상태·오늘 50분·세 소품 해금이고, 설치 앱은 실제 저장된 목표·오늘 5분·화분 해금을 그대로 표시한다. 이 동적 데이터 차이는 의도된 차이다.
- 전체 흐름 캡처: `home-morning.png`, `home-day.png`, `home-night.png`, `records.png`, `settings.png`, `goal.png`, `sound.png`, `focusing.png`, `paused.png`, `completed.png`, `rest.png`, `compact.png`, `compact-large-text.png`.

**검토한 표면**

- 글꼴: Flutter UI는 Pretendard를 사용하고 크림색 굵은 타이머·제목, 작은 설명, 단추 문구의 위계를 유지한다. 배경 포스터와 책등 글자는 그림에 포함된 텍스트다. 작은 화면에서 줄바꿈·말줄임 및 1.6배 글자 크기를 확인했다.
- 배치: 전체 화면 책상/창문 크롭, 캐릭터·공책 위치, 25/50 선택과 둥근 CTA, 하단 메뉴 간격을 같은 논리 화면에서 비교했다. 최종 캡처에서 공책과 `오늘의 집중`이 겹치지 않고 메뉴와 CTA가 잘리지 않는다.
- 색과 대비: 짙은 자주색 배경, 크림색 전경, 앰버색 선택 상태와 CTA를 비교했다. 움직이는 장면 위 상태 메시지에는 어두운 표면을 깔아 읽을 수 있게 했다.
- 이미지와 아이콘: 방 4개, 보상 소품 3개, 책상/기록/설정 아이콘은 생성된 래스터 자산이다. 선명도·알파 가장자리·크롭을 390 dp와 Android 캡처에서 확인했다. 실제 필기·휴식 캐릭터는 애니메이션 자산이다.
- 앱 문구와 동작: `나의 책상`, `함께 집중할 시간`, 타이머, 오늘의 집중, 25/50분, 집중 시작, 책상/기록/설정이 시안과 맞는다. 집중·일시정지·완료·휴식·목표·사운드의 실제 상태도 캡처했다.

**비교 이력**

1. 초기 비교([비교 초안](comparison-initial.jpg))에서 P2: 공책이 `오늘의 집중`과 너무 가까워 가독성을 떨어뜨렸다. `DeskIllustration`의 캐릭터 크기와 위치를 조정했다. 수정 후 [전체 비교](comparison-final.jpg)와 [Android 캡처](installed-app-final.png)에서 분리되어 보인다.
2. 하단 메뉴의 기본 시스템 아이콘이 공유 시안의 2D 선화와 달랐다. 시안에 맞는 투명 PNG 세 장을 생성해 적용했다. [하단 확대 비교](detail-final.jpg)에서 스타일과 크기를 확인했다.

**Open Questions**

- 없음.

**Implementation Checklist**

- [x] `flutter analyze`: 문제 없음.
- [x] `flutter test --no-pub`: 45개 통과. 최종 아이콘 이후 `flutter test --no-pub tool/capture_immersive_preview_test.dart`: 통과.
- [x] Android 별도 검증 패키지의 필기·정지·완료·휴식 동작 검사 통과.
- [x] 실제 개발 앱을 데이터 삭제 없이 업데이트 설치. [저장 상태 검사](data-preservation.json): 스냅샷 SHA-256 동일, revision 61, 기록 13개 유지.

**Follow-up Polish**

- 필요할 때 실제 디바이스별 OS 표시줄 처리와 애니메이션 공책의 그림 스타일을 추가로 다듬을 수 있다. 현재 핵심 동작이나 가독성에 영향을 주지 않는다.

final result: passed
