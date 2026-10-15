# 연결된 필기 동작 — 24장

사용자가 선택한 방식 ②: 몸통·어깨·팔·손이 붙어 있는 완성된 캐릭터 그림을 순서대로 교체합니다. 팔을 별도 이미지로 붙이거나 관절을 회전시키지 않습니다.

## 동작과 앱 연결

- 준비 01–06 → 필기 07–18 → 복귀 19–24.
- 서로 다른 그림 24장, 12fps. 시작·끝 그림을 각각 6틱 더 유지하여 총 36틱, 3초 주기.
- 같은 정사각형 셀에서 완성된 그림 전체를 렌더링합니다. 얼굴의 같은 무늬를 기준으로 위치를 맞추고, 생성 시 생긴 머리 크기 편차는 그림 전체의 동일 비율 확대·축소로 보정합니다. 부위별 변형이나 팔의 별도 덧붙임은 없습니다.
- 홈 대기·완료에는 01번 그림. 집중 중에만 필기 재생. 일시정지·백그라운드·숨겨진 TickerMode에서는 재생 위치를 유지합니다.
- 동작 줄이기 설정에서는 01번 그림을 표시합니다. 집중 기록 저장·남은 시간 계산과 애니메이션 시계는 분리되어 있습니다.

## 제작

Built-in `image_gen`을 사용했습니다. 핵심 자세 3장 → 12장 초안 → 24장 초안 → 6장씩 고해상도 정리 4시트 순서로 제작했습니다. 최종 시트는 **2048×3072**, 각 그림은 **512×512** 투명 PNG입니다. 생성된 시트의 간격이 조금씩 달라서, 투명 알파로 완성된 캐릭터와 책의 연결 범위를 찾아 통째로 잘랐습니다. 그림 전체의 위치를 옮겨 같은 얼굴 무늬에 맞췄으며, 색이나 캐릭터 부위를 다시 그리지는 않았습니다. Python/Pillow는 이 추출·정렬·미리보기·ZIP 포장에 사용합니다. 앱과 미리보기는 같은 전체 그림 확대·축소 보정을 사용합니다.

- [핵심 자세 3장](key-poses.png), [정확한 프롬프트](key-poses.prompt.txt)
- [12장 초안](draft-12.png), [정확한 프롬프트](draft-12.prompt.txt)
- [24장 최종 시트](final-atlas.png), [24장 초기 초안](draft-24.png), [초안 프롬프트](final-24.prompt.txt)
- 고해상도 정리 프롬프트: [01–06](detail/output-1.prompt.txt), [07–12](detail/output-2.prompt.txt), [13–18](detail/output-3.prompt.txt), [19–24](detail/output-4.prompt.txt)
- [Image Gen 원본 경로와 제작 방식](provenance.json)
- [그림별 PNG와 메타데이터 ZIP](writing-24-frames.zip)
- [재생·정지·그림별 확인 미리보기](index.html)
- [캐릭터 GIF](writing-loop.gif), [앱 실행 GIF](app-writing-loop.gif)
- [프레임·재생 시간·위치 정보](manifest.json)
- 앱 에셋: `../../../assets/images/immersive/redpanda-connected-writing-24.png`
- 앱 코드: `../../../lib/reference_companion.dart`, `../../../lib/reference_writing_animation.dart`, `../../../lib/reference_writing_registration.dart`
- 재포장: `../../../tool/package_reference_writing.py`. bundled Python/Pillow/NumPy로 실행하며, 원화 4시트에서 같은 최종 PNG·등록 정보·GIF·ZIP을 다시 만듭니다.

## 검증

- 24개 셀의 픽셀 해시가 모두 다르고, 실제 투명 알파가 있습니다.
- GIF의 총 재생 시간은 정확히 3000ms. 미리보기에서 24 → 01 이동 및 재생을 확인했습니다.
- `flutter analyze --no-pub`: 오류 없음.
- `flutter test --no-pub`: 47개 통과. 반복 경계, 대기, 일시정지, 재개, 백그라운드, 숨겨진 화면, 동작 줄이기, 다음 집중의 초기화 포함.
- [Android 통합 검증 로그](native-final/integration.log): 일반 앱의 기록과 분리된 검증용 패키지에서 24장 표시, 일시정지·재개·완료·휴식 확인.
- [Android 실행 영상](native-final/native-animation.mp4). 통합 테스트가 프레임을 진행시키며 촬영한 영상이므로 실제 12fps 속도를 판단하는 용도는 아닙니다. 설정된 재생 속도는 [캐릭터 GIF](writing-loop.gif)와 [미리보기](index.html)에서 확인할 수 있습니다. 일시정지 캡처 두 장은 전체 픽셀에 변화가 없었습니다.
- 개발용 일반 APK를 기존 `emulator-5554`에 `adb install -r`로 업데이트했습니다. 설치 전후 집중 기록 본문의 SHA-256과 revision이 동일합니다. [데이터 보존 비교](data-preservation.json).
- 추가 실시간 촬영 시도는 공유 에뮬레이터의 다른 앱 실행, 복제 기기의 저장 공간 및 실행 잠금 때문에 완료되지 않았습니다. 앱 코드·에셋과 통합 테스트는 `native-final`에서 통과한 버전입니다.

원화 프레임에는 손으로 그린 선·질감의 작은 변화가 남습니다. 캐릭터의 연결을 유지한 필기 동작이며, 머리·꼬리의 별도 동작과 생각하기·페이지 넘기기는 이 24장에 포함하지 않았습니다.
