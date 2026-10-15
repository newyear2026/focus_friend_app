# 사막여우 · 다람쥐 창가 찻잔 휴식

승인한 [창밖 보며 차 한 잔 시안](../fennec-squirrel-rest-concepts-v1/04-window-tea.png)을 기존 Flutter 앱의 휴식과 친구 미리보기에 적용했습니다. 두 캐릭터 모두 창가로 고개를 향한 상태에서 잔을 감싸고 쉬다가 한 모금 마시고 같은 자세로 돌아옵니다.

- [움직이는 미리보기](http://127.0.0.1:8126/docs/design/fennec-squirrel-window-tea-v1/)
- [사막여우 전체 22초 영상](fennec-window-tea.mp4)
- [다람쥐 전체 22초 영상](squirrel-window-tea.mp4)
- 실제 앱 화면: [사막여우](fennec-evening-app.png), [다람쥐](squirrel-day-app.png)

앱에서는 **친구 → 사막여우 또는 다람쥐 → 미리보기**에서 동작을 볼 수 있습니다. 적용하면 해당 친구의 휴식 시간에 같은 모션을 사용합니다. 집중 시간의 두 캐릭터는 기존 정지 필기 장면을 사용하며, 펭귄·해달·랫서팬더의 집중 모션은 유지됩니다.

## 동작

한 번에 22초입니다. 처음과 마지막에는 잔을 낮게 감싼 채 머무는 시간을 길게 두고, 중간에 약 3초 동안 올린 뒤 한 모금 마시고 천천히 내립니다. 사용한 자세를 역순으로 돌아오며 시작과 마지막은 같은 원화입니다. 모션 시계는 세션 타이머와 독립되어 있고, 일시정지·앱 비활성·TickerMode 비활성에서는 현재 자세를 보존합니다. 동작 줄이기를 켜면 기본 휴식 자세를 보여줍니다.

방과 앞쪽 소품, 닫힌 책·내려놓은 연필은 고정합니다. 어깨·몸통·팔이 연결된 원화를 사용하고, 전환 중 찻잔과 연결된 팔의 위치를 연속적으로 맞춰 이중 윤곽을 줄입니다. 얼굴과 안경은 한 원화씩 보여주며 목 아래는 부드럽게 연결합니다. 원화별 작은 윤곽 차이는 남아 있는 1차 버전입니다.

아침·낮·저녁·밤은 기존 현지 시간 구간을 사용합니다. 기존 집중 장면과 별도로, 캐릭터를 제거한 휴식용 빈 방 8장을 만들어 원래 방과 시간대의 구도를 유지했습니다. 방 전환 중에도 모션 재생 위치가 이어집니다.

## 이미지 제작 기록

모든 새 그림은 **built-in ImageGen 편집 모드**로 제작했습니다. 각 캐릭터에 12장짜리 투명 연결 원화 시트를 만들고, 그중 정렬과 동작이 적절한 기본·상승·한 모금 자세를 골라 역순 복귀에 재사용합니다. 같은 폴더의 `fennec-rest-raw.png`, `squirrel-rest-raw.png`가 생성 원본입니다.

최종 요청문은 [사막여우 원화](fennec-rest.prompt.txt), [다람쥐 원화](squirrel-rest.prompt.txt)와 `*-morning/day/evening/night.prompt.txt`입니다. 각 원본 경로·참고 이미지는 [asset-manifest.json](asset-manifest.json)에 기록했습니다. `tool/package_window_tea.py`는 셀을 자르고 동일 비율로 크기·위치를 정렬해 포장하며 그림을 다시 그리지 않습니다. 정렬은 컵이 들어오지 않는 머리 위쪽 범위를 기준으로 합니다.

실행 자산은 `assets/images/friends/motion/{fennec,squirrel}/rest.png`와 `rooms/{morning,day,evening,night}.png`입니다. 원화 한 칸은 384×384px이고, 방은 853×1844px입니다. 생성된 사막여우 저녁 방은 높이가 1843px여서 1844px로 비율을 맞췄습니다.

## 검증

전체 Flutter 테스트와 실제 앱 화면 캡처 합계 **98개 통과**, 정적 분석 이상 없음, Android 디버그 APK 빌드 성공입니다. 전체 영상은 앱의 동일 Painter와 시각 시계를 12fps로 22초 전부 렌더했으며 재생 속도를 바꾸지 않았습니다. 앱 자체는 약 30fps로 화면을 갱신합니다. [검증 결과](verification.json), [테스트](tests.log), [분석](analyze.log), [빌드](build.log), [QA](design-qa.md)를 참고하세요.

기존 에뮬레이터의 설치본을 업데이트했고, 저장 JSON·revision 30·기록 4개와 친구 선택·진행 세션이 이전과 동일합니다. 결과는 [데이터 보존 기록](data-preservation.json)에 있습니다. 검증용 앱 화면은 MemoryStore 픽스처로 캡처하여 사용자의 기록이나 친구 선택을 바꾸지 않았습니다. [네 시간대 앱 화면 비교](time-of-day-apps.jpg)와 [브라우저 재생 검증](browser-verification.json)도 보관했습니다.
