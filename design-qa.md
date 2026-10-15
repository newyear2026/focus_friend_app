# 랫서팬더 홈 · 필기 동작 구현 검증

> 최신 네 친구의 아침·낮·저녁·밤 적용: [friend-time-of-day-implementation/design-qa.md](docs/design/friend-time-of-day-implementation/design-qa.md) — final result: passed. 승인한 4단계 시안과 16개 실제 Flutter·Android 화면, 필기·휴식 유지, 시간대 전환·복귀, 전체 테스트 92개, 업데이트 후 저장 데이터 보존을 확인했습니다.

> 최신 집중 종료 패널의 책장·책갈피 테두리: [book-frame/design-qa.md](docs/design/session-stop/book-frame/design-qa.md) — final result: passed. 선택 원본과 같은 크기의 전체·확대 비교, 작은 화면·큰 글자·가로 화면 및 종료 동작을 확인했습니다.

> 집중 종료 하단 패널: [session-stop/design-qa.md](docs/design/session-stop/design-qa.md) — final result: passed. 선택 시안과 같은 뷰포트의 전체·확대 비교, 큰 글자, 계속하기·종료하기 및 취소 동작을 확인한 별도 범위입니다.

> 하단 메뉴의 2D 셀 아이콘 적용 검증: [navigation-implemented/design-qa.md](docs/design/navigation-implemented/design-qa.md) — final result: passed. 책상·기록·설정 아이콘과 선택 표시만 변경한 별도 범위입니다.

> 최신 구현: [2D 컷아웃 리그 검증](docs/design/puppet-motion/design-qa.md). 아래 포즈 교체 및 연속 메시 방식은 이전 구현 이력이며, 사용자 피드백에 따라 대체했습니다.

final result: passed


## 대상과 비교 조건

- 선택 시안: `docs/design/character-concepts/redpanda-writing-study.png` (1536×1024). 루틴 앱의 `redpanda_teashop/v1/approved/focus.png`를 캐릭터 정체성 참고로만 읽었습니다.
- 시안은 방과 세 가지 포즈를 보여주는 보드입니다. 이번 범위는 그 캐릭터와 동작을 기존 Flutter 홈에 적용하는 것입니다. 별도의 집중 화면을 만들지 않으며, 기존 타이머·보상·시간대 배경을 재사용합니다.
- 실제 구현: Android 16 / emulator-5554, 1080×2160px, density 2.75 (약 393×786dp). `integration_test/study_scene_test.dart`에서 실제 Flutter 화면을 2배로 캡처한 PNG는 786×1571px입니다. 메모리 저장소와 주입된 시계로 동일 상태를 만듭니다.
- `docs/design/redpanda-study/source-comparison.jpg`: 선택 시안의 방 영역(0,0–960,1024)과 실제 낮·필기 화면의 방 영역(124,244–660,854)을 비율 유지하여 같은 패널 높이로 정규화하고, 전체 앱 화면도 함께 배치했습니다. 시안 상단의 지붕이 잘린 것은 원본 보드의 크롭이며 실제 앱은 방 전체를 보여줍니다.
- `docs/design/redpanda-study/pose-comparison.jpg`: 시안 오른쪽의 필기·확인·페이지 넘김 세 포즈와 실제 같은 세 상태의 캐릭터 영역을 함께 비교했습니다. 실제 캡처를 확대했으므로 확대본의 픽셀은 원본 자산 해상도 문제가 아닙니다.
- `time-of-day-comparison.jpg`: 네 실제 홈 캡처를 각각 393×786px로 줄여 나란히 비교했습니다. 기기 시스템 시간을 변경하지 않았습니다.

## 필수 시각 항목

- **글꼴과 위계:** Pretendard와 남색/파랑 위계를 유지했습니다. 최초 캡처는 제목 40/900·타이머 72/900이며, 같은 작업공간의 병행 UI 변경이 반영된 최종 화면은 제목 34/900·보조 문구 20·집중 타이머 38/900입니다. 사운드 버튼·티켓 선택·타이머 한 줄 배치 등 병행 기능은 되돌리지 않았습니다. 전체 화면과 확대 비교에서 새 문구가 잘리거나 이웃 요소와 겹치지 않습니다. 기본 화면의 긴 캐릭터 선택 문구도 한 줄입니다. 360×740dp·글자 1.6배에서는 스크롤로 조작에 접근하는 테스트를 통과했습니다.
- **간격과 배치:** 같은 `DeskIllustration` 요소와 정확히 같은 화면 좌표를 유지하며 집중을 시작합니다. 1182×1330 방 좌표계에서 캐릭터 전체 셀을 (342,335), 440×440에 놓았습니다. 노트는 책상 위에, 몸통은 의자 앞에 배치되고 꼬리·귀·책장이 잘리지 않습니다. 실제 버튼과 하단 메뉴는 그림에 포함하지 않았습니다.
- **색:** 기존 paper #FFFEFA, ink #07143C, blue #4752CE, green #3D956D를 유지했습니다. 주황 털·크림색 얼굴·초록 앞치마·갈색 앞발은 선택 시안을 따릅니다. 저녁·밤은 캐릭터도 방의 조도에 맞춰 조절하며 UI 글자는 밝은 바탕에서 읽을 수 있습니다.
- **이미지:** built-in Image Gen으로 생성한 진짜 투명 PNG 1774×887, 4×2 셀입니다. 셀 전체를 비율 유지해 그리며 임의 알파 경계 크롭을 하지 않았습니다. 443.5px 소스 셀 크기를 실수로 처리하고 최대 0.5px 등록 보정만 합니다. 선택 시안의 얼굴·앞치마·꼬리와 연필·노트가 유지되고, 필기/연필 내려놓기/책장 들기 상태가 구분됩니다. 실제 화면에서 눈에 띄는 배경 박스나 투명 테두리 번짐은 보이지 않습니다.
- **문구와 아이콘:** ‘랫서팬더가 골라주기’, ‘차근차근, 함께 써 내려가요’, ‘천천히, 한 줄씩 써봐요’로 행동과 문구를 맞췄습니다. 기존 Material 아이콘과 실제 Flutter 버튼을 유지했습니다. 접근성 이미지 설명도 현재 시간대와 랫서팬더 행동을 읽습니다.

## 동작과 검증 결과

- 24초 주기: 약 16초 필기 → 3초 확인 → 책장 잡기/넘기기 → 연필을 들고 다시 필기. 8개 포즈의 160ms 전환을 사용합니다. 노트 기준점은 고정하며 손·고개·시선·책장만 포즈에 따라 달라집니다.
- 일시정지는 연필을 내려놓은 정지 포즈입니다. 재개 시 저장된 동작 시각부터 이어집니다. 백그라운드와 기기의 동작 줄이기 설정에서는 애니메이션을 멈추며, 타이머 계산과 영구 저장은 독립되어 있습니다.
- `flutter test`: 최종 34개 통과 (이번 캐릭터·홈·기존 타이머 범위 29개와 병행 기능 5개). 필기 순서, 같은 홈/같은 방 위치, 일시정지·재개, 동작 줄이기, 시간대 경계·앱 복귀, 작은 화면/확대 글자, 기존 세션 저장·복구·보상 포함.
- `flutter analyze`: No issues found.
- 실제 Android 통합 테스트: 낮 필기 → 확인 → 페이지 넘김 → 일시정지 → 재개 → 정상 완료 → 화분 → 휴식 → 종료 → 홈 통과. `docs/design/redpanda-study/integration.log`.
- 증거: `writing.png`, `reviewing.png`, `turning-page.png`, `paused.png`, `completed.png`, `rest.png`, `returned-home.png`, `home-{morning,day,evening,night}.png`.
- 소품 화면의 별도 고양이도 같은 `DeskIllustration` 랫서팬더로 통일했습니다.
- 시간대는 기존 현지 시각 기준(05:30/08:00/17:30/20:00 경계)입니다. 실제 일출·일몰 계산은 이번 범위가 아닙니다.

## 비교 이력과 결과

첫 정지 장면의 전체/포즈 비교에서는 P0/P1/P2가 없었지만, 후속 실제 녹화에서 P2 전환 불투명도 문제가 발견되어 아래와 같이 수정했습니다. 참고 보드의 배경은 기존 방과 소품 배치를 재사용하도록 적용했고, 새 캐릭터의 모양과 행동을 기준으로 판단했습니다. 앱 화면 자체를 보드 이미지로 대체하거나 보드의 주석 문구를 UI에 추가하지 않았습니다.

일반 앱과 다른 `.verification` 패키지를 먼저 빌드한 뒤 격리 실행기로 테스트했습니다. 종료 후 일반 앱만 설치되어 있었고, 일반 앱 SQLite는 작업 전 스냅샷과 SHA-256까지 같았습니다 (`ce721bc67fa97b99531117dca0f5ba8c5b525edfe7ff3e959087e161b5fcb79f`). 정상 완료 1회·5분·화분과 기존 중도 종료 기록을 보존했습니다. 검증 종료를 확인한 뒤 일반 APK를 빌드하고 `adb install -r`로 업데이트했습니다.

## 후속 다듬기 (P3)

- 포즈 시트 방식이므로 연속 본 애니메이션처럼 손의 모든 궤적을 표현하지는 않습니다. 손글씨 스트로크와 고개 움직임은 작고, 페이지를 넘길 때 변화가 가장 큽니다.
- 참고 보드와 책 각도가 조금 다르고, 내려놓은 연필은 실제 방의 왼쪽 책 더미 가장자리에 놓입니다. 필기와 페이지 넘김의 의미와 책상 위 배치는 유지됩니다.
- 기존 보상 그림과 벽·책·매트의 고양이 장식은 원래 시안에도 있는 방 장식입니다. 이번 캐릭터 교체 범위에서 유지했습니다.

자산 생성 프롬프트와 좌표: `assets/images/redpanda-study-sheet.prompt.txt`. 이전 독서 구현의 QA는 `docs/design/study-scene/design-qa.md`에 보관했습니다.

최종 일반 앱에서도 소품 화면의 랫서팬더를 접근성 설명과 캡처로 확인했습니다. 기록 없는 체험 레이블을 확인한 뒤 26초 녹화하고 중도 종료해 홈으로 복귀했습니다. `writing-demo-native.mp4`가 원본, `writing-demo.mp4`가 크기만 줄인 표시용 녹화입니다. `collection-native.png`, `final-home-native.png`, `writing-motion-contact.png`를 확인했고, 체험 전후 history·completedMs·completedCount·unlocks 전체 값이 같고 active=null임을 검증했습니다 (`data-preservation.json`).

후속 실제 녹화 검사에서 P2: 포즈 전환 중 이전/다음 이미지를 각각 알파로 겹쳐 내부 합성 알파가 낮아지고 배경이 캐릭터를 통과하는 문제가 발견되었습니다. `pre-fix/writing-motion-contact.png`의 필기 포즈가 증거입니다. `StudyCompanionPainter`에서 독립된 투명 레이어에 가산 합성하여 내부 불투명도를 유지하도록 수정했습니다. 중간 포즈의 내부 알파가 255인지 검증하는 회귀 테스트도 추가했습니다.


## 최종 재비교 — P2 해결

- `source-comparison-final.jpg`: 선택 시안과 수정 후 일반 Android 앱의 낮·필기 장면을 함께 비교했습니다. 최종 원본 캡처 `writing-demo-start.png`는 1080×2160px입니다. 방 영역 (110,315–968,1290)을 비율 유지하여 참고 방과 같은 패널 높이로 배치하고 전체 앱을 함께 표시했습니다.
- `pose-comparison-final.jpg`: 같은 필기 상태를 얼굴·앞발·노트 중심으로 확대 비교했습니다. 기존 보상 화분이 오른쪽에 있는 것은 사용자의 원래 해금 상태입니다.
- `writing-motion-contact.png`: 수정 후 실제 영상에서 1초 간격으로 추출한 연속 장면입니다. 필기·확인·페이지 넘김에서 방의 줄무늬가 얼굴이나 몸통을 통과하지 않습니다. 마지막 빈 칸은 영상 끝 뒤의 타일 패딩입니다.
- 최신 `writing-demo-native.mp4` / `writing-demo.mp4`는 불투명도 수정 후 다시 녹화한 파일입니다. 녹화 요청은 26초이며 에뮬레이터가 출력한 영상 타임스탬프 길이는 벽시계와 다를 수 있습니다. 이전 영상은 `pre-fix/`에 분리했습니다.
- 최종 녹화 전후에도 history·completedMs·completedCount·unlocks 전체가 같고 active=null입니다. `data-preservation.json`에 결과를 기록했습니다.
- 설치가 병행 작업의 Android 검증과 겹쳐 지연될 때 제 설치 프로세스만 중단했습니다. 다른 검증 완료를 확인한 뒤 일반 APK를 별도 파일에 고정하고 `--no-streaming -r`로 업데이트했습니다. 다른 채팅을 중단하거나 그 변경을 되돌리지 않았습니다.

최종 캐릭터·홈 범위에 미해결 P0/P1/P2 없음. 루틴 앱 원본은 수정하지 않았으며 배포·커밋은 하지 않았습니다.


## 기록 · 목표 · 사운드 기능 QA (별도 범위)

새 메뉴·저장·오프라인 사운드의 최종 비교와 실행 검증은 [docs/design/features/design-qa.md](docs/design/features/design-qa.md)에 있습니다. 이 문서의 기존 필기 동작 검증 이력과는 별도 범위입니다.


## 후속 연속 모션 개선

필기 손목·호흡·고개·꼬리의 연속 움직임, 얼굴 유지, 일시정지 자세 보존을 적용했습니다. 최신 동작·검증 결과는 [docs/design/natural-motion/design-qa.md](docs/design/natural-motion/design-qa.md)에 있습니다. 위의 8포즈/160ms 전환 및 일시정지 정지 포즈 설명은 이전 구현 이력입니다.

## 쿠션에서 차 마시는 휴식 애니메이션

선택한 휴식 시안의 구현, 실제 움직임 영상, 일시정지·재개·완료 검증은 [docs/design/rest-tea-motion/design-qa.md](docs/design/rest-tea-motion/design-qa.md)에 있습니다.

## 공유 시안 기반 몰입형 2D 책상 — 최신 QA

**Findings**: 최종 비교에서 미해결 P0/P1/P2 없음. 정지 시안과 실제 필기 애니메이션의 공책·손 모양 차이, 실제 Android의 OS 표시줄은 P3이며 사용성에 영향 없음.

**Open Questions**: 없음.

**Implementation Checklist**: 같은 논리 화면의 전체·확대 비교, 작은 화면·큰 글자·상태별 캡처, Flutter 분석/테스트, Android 업데이트 및 저장 데이터 보존 확인 완료.

원본 시각 기준은 [reference.png](docs/design/immersive-room/reference.png) 853×1844 px. 구현은 [home-evening.png](docs/design/immersive-room/home-evening.png) 780×1688 px, 논리 뷰포트 390×844 dp, devicePixelRatio 2이다. 두 이미지를 각각 390×844 px로 정규화한 [전체 비교](docs/design/immersive-room/comparison-final.jpg)와 [상·하단 확대 비교](docs/design/immersive-room/detail-final.jpg)를 열어 검토했다. 상태는 25:00 준비·오늘 50분·소품 세 개 해금인 픽스처이며, [설치 앱 화면](docs/design/immersive-room/installed-app-final.png) 1080×2160 px에는 실제 저장된 목표·오늘 5분·해금된 화분이 보인다. 모든 화면과 근거는 [상세 QA](docs/design/immersive-room/design-qa.md)에 있다.

비교 이력: 첫 비교에서 공책과 `오늘의 집중` 사이 간격이 부족한 P2를 발견해 캐릭터 크기·위치를 조정했다. 초기 기본 내비게이션 아이콘의 선화 스타일도 시안에 맞는 이미지 자산으로 교체했다. 최종 전체·확대·실제 Android 캡처에서 두 문제 모두 해결됐다. Pretendard 글꼴·줄바꿈·간격·색 대비·일러스트 크롭·투명 아이콘·문구·집중/일시정지/완료/휴식 조작을 함께 확인했다. `flutter analyze` 이상 없음, 전체 Flutter 테스트 45개 통과, 최종 화면 캡처 테스트 통과. APK 업데이트 후 저장 스냅샷 SHA-256과 revision 61·기록 13개가 이전과 같다.

**Follow-up Polish**: 추후 OS 상태 표시줄 처리와 실제 애니메이션 공책의 그림 스타일을 더 맞출 수 있다.

final result: passed


## 하단 친구 탭과 다섯 친구 선택 — 최신 QA

선택한 책상·친구·기록·설정 배치, 친구 선택→방 미리보기→적용의 시각 비교와 검증은 [친구 탭 QA](docs/design/friend-picker-implementation/design-qa.md)에 있습니다. 실제 Flutter 전체·확대 비교, 작은 화면과 큰 글자, 네 언어, 오류·취소·적용·선택 저장을 확인했습니다. 79개 테스트 통과, 정적 분석 이상 없음, Android 업데이트 후 기존 일시정지 세션과 저장 JSON이 동일합니다. 새 네 친구는 정지 장면이며 랫서팬더의 기존 애니메이션은 유지합니다.

final result: passed

## 펭귄 · 해달 1차 애니메이션 — 2026-10-15

두 캐릭터에 36초 필기 → 6.3초 페이지 넘김과 14초 찻잔 휴식을 연결했습니다. 실제 앱 캡처·동일 Painter 영상·검증 결과는 [모션 QA](docs/design/penguin-otter-motion-v1/design-qa.md)에 있습니다. 전체 테스트와 앱 캡처 합계 85개 통과, 분석 이상 없음, Android 업데이트 후 저장 JSON 동일입니다. 페이지 원화의 작은 윤곽 차이와 일부 손·종이 혼합 잔상은 P3 다듬기 항목입니다. 앞선 ‘새 네 친구 정지 장면’ 설명은 해당 시점의 구현 이력입니다.


## 사막여우 · 다람쥐 창가 찻잔 휴식 — 2026-10-15

승인한 창밖을 보며 차 마시는 시안을 휴식과 친구 미리보기에 적용했습니다. 22초 반복, 연결 원화·고정된 책과 방, 일시정지·재개·네 시간대 전환을 검증했습니다. [제작·QA 기록](docs/design/fennec-squirrel-window-tea-v1/README.md)에 실제 앱 캡처와 전체 영상을 보관했습니다. 테스트 98개 통과, 분석 이상 없음, Android 업데이트 후 저장 JSON과 revision 30·기록 4개가 동일합니다. 원화별 작은 몸통·꼬리 윤곽 차이와 중간 혼합 흔적은 P3입니다.
