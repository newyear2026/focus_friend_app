# 실제 화면과 Library 저장 결과

Android 16 에뮬레이터의 실제 화면 원본 7개입니다. 각 이미지의 Library 저장 성공과 로컬 식별자 기록을 확인했습니다.

| 화면 | Library 파일 ID |
|---|---|
| 01-home.png | `libfile_2d6cfdb252788191b0923f552b4452b5` |
| 02-focusing.png | `libfile_c385aaf678788191ab9baf95fc66f282` |
| 03-paused.png | `libfile_ff024b28c70c8191a540a24b5b03e0fd` |
| 04-first-reward.png | `libfile_90d74a390fd88191991612a219609d07` |
| 05-room-with-plant.png | `libfile_ccc76add67a081918ad441594f1688f0` |
| 06-collection.png | `libfile_208c93bc99c88191a70801a73bd9694a` |
| 07-history.png | `libfile_7c2bdff9a06881919c7e90c2bcca777b` |

로컬 원본: `/Users/jaewook/Documents/Codex/2026-10-07/task/screenshots/`.

APK SHA-256: `eb9091c80529df529049af4163411d6560d7ebbeb8ba012b263b379e677b2056`.


## 홈 디자인 변경 후

사용자 첨부 참고 이미지의 첫 번째 화면을 기준으로 홈을 다시 구현했습니다. 다음은 업데이트된 개발 앱에서 직접 캡처한 화면입니다.

- `docs/design/home-final-full.png`: 참고 비율의 실제 에뮬레이터 원본, 1045×2470.
- `docs/design/home-final.png`: 시스템 표시줄을 제외하고 380×850으로 정규화한 앱 화면.
- `docs/design/home-compact-final.png`: 원래 에뮬레이터 1080×2160에서의 최종 홈.
- `docs/design/home-comparison.png`: 원본과 구현을 같은 크기로 나란히 비교.
- `docs/design/controls-comparison.png`: 하단 조작 영역 확대 비교.

실제 기록 5분, 화분 해금 상태를 사용했고 목업의 예시 50분을 데이터에 넣지 않았습니다. 기존 위쪽 Library ID와 APK 해시는 초기 버전의 기록이며 새 홈 빌드의 식별자가 아닙니다. 새 홈 검증은 프로젝트 루트 `design-qa.md`를 참고하세요.
