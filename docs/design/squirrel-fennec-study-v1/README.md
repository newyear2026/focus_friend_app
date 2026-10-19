# 다람쥐·사막여우 집중 모션

기존 V9에서 두 친구의 집중은 시간대별 정지 일러스트였습니다. 휴식용 차 마시기 원화만 연결되어 있었으므로, 집중 상태에 필요한 연결된 필기·페이지 넘김 원화를 새로 만들고 실제 앱에 적용했습니다.

## 적용 결과

- 각 친구에 4열 × 6행, 384px 정사각 셀 24칸의 투명 PNG 아틀라스.
- 필기 0–5번: 4초 왕복 동작을 9회 반복해 36초.
- 페이지 준비·넘김·복귀 6–23번: 4.5초. 기존 공통 재생 시계가 7번을 건너뛰므로 실제 사용은 23개의 서로 다른 슬롯입니다.
- 22번은 필기 1번 자세를 복귀 연결로 재사용하고, 23번은 기본 0번과 동일하게 마감합니다. 전체 40.5초, 12fps 시간 격자이며 각 그림은 여러 틱 동안 유지합니다.
- 얼굴 상부·귀·꼬리·몸통·가방·찻잔·책 표지는 기본 그림으로 유지하고, 연결된 팔·연필과 페이지 안쪽만 자세별 그림을 사용합니다. 페이지가 높이 올라오는 중간 자세는 손과 종이를 포함하는 영역을 추가합니다.
- 일시정지, 백그라운드, TickerMode, 동작 줄이기, 시간대별 조명 전환은 기존 앱 동작을 따릅니다.

[전체 친구 모션 미리보기](../all-character-motions-v10/index.html) · [필기·페이지 검증](../all-character-motions-v10/verification.json)

| 친구 | 앱에서 사용하는 PNG | 주요 자세 |
| --- | --- | --- |
| 다람쥐 | [study.png](../../../assets/images/friends/motion/squirrel/study.png) | [실제 방에 합성한 6자세](squirrel-contact.jpg) |
| 사막여우 | [study.png](../../../assets/images/friends/motion/fennec/study.png) | [실제 방에 합성한 6자세](fennec-contact.jpg) |

## 이미지 생성·가공 기록

생성 모드는 built-in ImageGen의 **참조 이미지 편집**, 투명 배경입니다. 현재 앱의 캐릭터와 책상 장면을 참고하여 기본 자세 2장과 캐릭터별 6칸 시트 4장을 생성했습니다. 원본 결과는 [raw/](raw/), 참고와 기준 자세는 [reference/](reference/), 개별 완성 셀은 [cels/](cels/)에 있습니다.

- [기본 자세·필기·페이지 A/B 전체 프롬프트](prompts.json)
- [페이지 C 전체 프롬프트](prompts-page-c.json)
- [다람쥐 등록 수치](squirrel-registration.json), [사막여우 등록 수치](fennec-registration.json)
- [재현용 패키징 도구](../../../tool/package_window_study.py)

패키징은 시트 분할, 셀 전체의 균일 크기·위치 정렬, 영역 합성, 아틀라스 배치만 수행합니다. 캐릭터 부위별 왜곡이나 합성 동작 생성은 사용하지 않습니다. 경계 알파 마스크에만 좁은 가드를 두며 원화 자체를 흐리지 않습니다. 기본 원화는 새로 그렸으므로 이전 정지 장면과 모든 픽셀이 같지는 않습니다. 휴식 원화는 그대로 사용합니다.

```sh
python3 tool/package_window_study.py --publish
flutter test --reporter expanded
flutter analyze
```

## 검증

전체 테스트 **125개 통과**, 정적 분석 **문제 없음**. 새 두 친구의 집중에도 필기 중 고정 영역, 페이지 넘김 중 얼굴·꼬리·찻잔·책 표지 고정, 실제 페이지 변화, 일시정지·백그라운드 복귀와 조명 전환 검사를 적용했습니다. [테스트 로그](flutter-test.log), [분석 로그](flutter-analyze.log).

실제 `FocusFriendApp` 위젯에서 두 집중 주기를 각각 486장 캡처했습니다. 시작·마지막 그림은 PNG 해시가 동일하며 필기와 페이지 넘김이 모두 관측됩니다. 기존 나머지 8개 영상은 V9와 디코딩한 프레임 전체가 같습니다. [전체 캡처·비교 기록](../all-character-motions-v10/README.md).

Android ARM64 디버그 APK 빌드와 `emulator-5554` 업데이트 설치를 완료했습니다. 시작 명령의 대기는 시간 초과였으나 이후 앱 프로세스·전면 Activity·그리기 완료가 확인되었고 crash 버퍼는 비어 있었습니다. APK에 포함된 두 study.png는 소스와 SHA256이 같습니다. [에셋 검증](android-assets.json), [실행 상태](android-health.txt), [빌드](android-build.log), [설치](android-install.log), [시작 대기](android-launch.log). 물리 기기 설치나 배포는 수행하지 않았습니다.
