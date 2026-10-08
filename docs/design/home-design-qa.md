# 홈 화면 디자인 검증

final result: passed

현재 상태: 홈 구현 범위에서 미해결 P0/P1/P2 없음. 실제 홈 캡처, 세부 비교, 메뉴 이동 확인, 원래 에뮬레이터 크기 복구 완료.

## 비교 기준

- Source visual truth: `docs/design/reference-board.png`, 사용자가 첨부한 4화면 중 첫 번째 홈.
- Source crop: `docs/design/reference-home.png`, 380×850.
- Implementation: Android 16 emulator-5554 실제 실행 화면 `docs/design/home-final-full.png`, 1045×2470.
- 앱 표시 영역은 상태 표시줄 66px와 시스템 제스처 영역 66px를 제외한 1045×2338. 밀도 2.75에서 약 380×850dp. `home-final.png`는 이 영역을 380×850으로 정규화.
- 전체 비교: `docs/design/home-comparison.png` (왼쪽 원본, 오른쪽 구현).
- 세부 비교: `docs/design/controls-comparison.png` (선택, 랜덤 버튼, CTA, 내비게이션).
- 상태: 홈/25분 선택. 원본의 예시 50분·모든 소품과 달리 에뮬레이터의 기존 정상 완료 5분·화분 1개를 그대로 표시. 데이터를 수정하거나 잠긴 소품을 임의로 해금하지 않음.

## 비교와 수정 이력

1. 최초 캡처 `home-v1.png` / 정규화 `home-normalized.png`: [P2] 원본보다 작은 제목·집계 수치·보조 글자. 제목 34→40, 집계 62→72, 보조 글자 18→20, 주요 버튼 22→24, 내비게이션 14→16으로 조정.
2. 동작 검증: [P2] 랜덤 선택 SnackBar가 일시적으로 시작 버튼을 가림. 안내 오버레이를 제거하고 선택된 시간 버튼으로 즉시 결과를 표시. 랜덤 선택 직후 50분 선택·시작 테스트로 재발 방지 확인.
3. 수정 후 캡처 `home-final-full.png` / `home-final.png`: 원본과 같은 순서, 중심 정렬된 방·오늘의 집중, 25/50분 선택, 랜덤 버튼, 초록 CTA, 3개 하단 메뉴 확인. 큰 폰트에서도 조작 가능.
4. 앱 시작 로고만 찍힌 중간 캡처는 검증 증거에서 제외하고 실제 홈이 표시된 캡처로 교체.

## 필수 시각 항목

- **글꼴:** Pretendard v1.3.9 가변 글꼴을 앱에 번들. 짙은 남색 900 굵기 제목과 집계, 파란 보조 글자. 원본의 정확한 폰트 파일은 제공되지 않았으며 가까운 한글 서체로 구현.
- **배치:** 제목 → 그림 → 오늘의 집중 → 25/50분 → 랜덤 선택 → 집중 시작 → 책상/기록/설정 순서. 380×850 앱 영역에서 주요 조작이 스크롤 없이 표시됨. 짧은 화면에서는 방이 축소되고 큰 글자에서는 스크롤로 조작 접근 보장.
- **색:** 배경 #FFFFFEFA, 제목 #07143C, 보조 #4752CE, 버튼 #3D956D. 그림의 따뜻한 목재·녹색 식물·남색 고양이를 반영.
- **이미지:** 전체 목업이 아닌 독립된 투명 PNG 방과 소품 3개를 사용. 코드 도형 대체물 없음. 방 그림은 원본 참조로 재생성했으며 책·식물·고양이의 미세한 형태는 동일하지 않음. 소품은 기존 unlock 상태에 따라 표시.
- **문구:** 나의 책상 / 오늘도 같이 시작해요 / 오늘의 집중 / 25분 / 50분 / 고양이가 골라주기 / 집중 시작 / 책상·기록·설정을 반영. 표시 시간은 실제 저장 데이터 사용.

## 구현 범위와 데이터

홈 화면을 개선한 작업이며 기존 Flutter 프로젝트를 사용. 기록 탭은 기존 기록 화면에 연결. 설정 버튼은 기존 5/15분 시작, 1분 체험, 알림 요청, 소품 화면 진입을 담은 시트를 엶. 참고 이미지의 전체 설정 화면이나 소리/백업 기능을 새로 만든 것은 아님.

홈의 오늘 합계는 보관 중인 최근 100개 기록에서 기기 현지 완료일이 오늘인 정상 집중의 actualMs를 합산. 기존 저장 정책 이상의 일별 보존을 추가하지 않음. 장기적인 일별 통계는 별도 일별 집계 저장이 필요함.

## 테스트

- flutter analyze: 문제 없음.
- flutter test: 23개 통과. 기존 타이머/복구/저장/보상 검증, 오늘 날짜·중도 종료·체험·휴식 제외, 50분 선택·시작, 랜덤 선택 후 즉시 시작, 360×740·글자 1.6배 조작 접근 포함.
- flutter build apk --debug: 성공.
- 기존 SQLite를 유지한 업데이트 설치. 홈 실제 데이터 5분·화분 확인.
- 실제 기록 탭: `history-check.xml`에서 기존 정상 완료 5분·1회 기록 확인. 설정: `settings-check.xml` / `settings-check.png`에서 5/15분·체험·알림·소품 진입 확인.
- 1080×2160 원래 에뮬레이터 크기 복구 후 `home-compact-final.png`에서 모든 주요 버튼과 하단 메뉴가 보이는지 확인. 홈·25분 선택 상태로 남김.
- 최종 Flutter/AndroidRuntime 로그에 오류 없음.
- 실제 에뮬레이터 50분 선택: `home-50-selected.xml` selected=true 확인, 캡처 `home-50-selected.png`.

## P3 후속 다듬기

- 재생성한 그림의 고양이 크기·책장 배치와 원본의 세부 질감 차이.
- 원본의 미세한 버튼 음영과 아이콘 굵기 차이.
- 전체 집중·기록·설정 화면의 일관된 디자인 확장은 다음 범위.

## 에셋·프롬프트·글꼴 출처

모든 이미지: built-in `image_gen__imagegen`, 투명 PNG, 프로젝트에 저장됨.

- `assets/images/home-study-room.png` — `assets/images/home-study-room.prompt.txt`
- `assets/images/reward-plant.png` — `assets/images/reward-plant.prompt.txt`
- `assets/images/reward-mug.png` — `assets/images/reward-mug.prompt.txt`
- `assets/images/reward-lamp.png` — `assets/images/reward-lamp.prompt.txt`

글꼴: [Pretendard 공식 저장소](https://github.com/orioncactus/pretendard), v1.3.9. `assets/fonts/PretendardVariable.ttf`, SIL OFL `assets/fonts/OFL.txt` 동봉.
