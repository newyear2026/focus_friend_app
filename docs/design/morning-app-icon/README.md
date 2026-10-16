# 작은 집중방 — 아침 햇살 앱 아이콘

제작일: 2026-10-14
제작 도구: built-in `image_gen__imagegen`.
용도: 아침 서재 그림을 정사각형 앱 아이콘으로 변환한 뒤 기본 Android 아이콘으로 적용.

## 2026-10-16 Android 앱 아이콘 적용

사용자가 첨부한 정사각 PNG를 그대로 사용해 기본 앱 아이콘으로 적용했습니다. 그림의 내용은 변경하지 않고 배포 크기에 맞게 축소했습니다.

- 적용 원본: `applied-2026-10-16/source.png`.
- 현재 마스터: `../../../assets/icon/app_icon.png` (1024×1024 RGB).
- 별도 512px 출력: `applied-2026-10-16/icon-512.png`.
- Android 기본 아이콘 5개 밀도(48/72/96/144/192px)와 적응형 아이콘 그림(512px)을 교체했습니다.
- 적응형 아이콘의 주변 색을 아침 그림에 맞는 크림색 `#E6C59F`로 바꾸고 각 방향에 21% 여백을 두었습니다.
- 야간 버전 마스터는 `../../../assets/icon/app_icon_night.png`에 보관했습니다.

### 적용 검증

- `flutter build apk --debug --no-pub` 성공.
- AAPT2로 `dev.jaewook.deskmate` / `Deskmate`의 아이콘이 적응형 리소스로 연결되는 것을 확인.
- 마스터 1024px, 적응형 그림 512px, 기본 아이콘 5개 밀도의 크기와 RGB 포맷을 확인.
- Pixel 3 / Android 16 에뮬레이터에서 `adb install -r` 성공.
- 실제 런처 홈의 Deskmate 원형 아이콘에 아침 그림이 표시되는 것을 시각 확인: `applied-2026-10-16/launcher.png`, `launcher.xml`.
- 아이콘 관련 변경 파일의 `git diff --check` 통과.

### Google Play 등록용 파일

2026-10-16에 `../../../deliverables/store_listing/icon-512.png`를 아침 버전으로 준비했습니다.

- 512×512px, 32비트 RGBA PNG, sRGB 프로파일 포함.
- 파일 크기 332,029바이트(324.2KiB)로 1MB 미만.
- 알파는 전부 255로 불투명하며, 원본 512px 이미지의 RGB 픽셀은 그대로 보존했습니다.
- 모서리 마스크와 아이콘 외부 그림자를 추가하지 않은 전체 정사각형입니다.
- PNG 디코딩, IHDR의 8비트 RGBA, 크기, 용량, 알파, 프로파일과 원본 픽셀 일치를 확인했습니다.
- 참고: [Google Play 아이콘 디자인 사양](https://developer.android.com/distribute/google-play/resources/icon-design-specifications), [메타데이터 정책](https://support.google.com/googleplay/android-developer/answer/9898842).

## 결과

- `generated-original.png`: 원본 생성 이미지.
- `../../../assets/icon/app_icon_morning.png`: 별도로 보관한 1024×1024 불투명 PNG.
- 크림색 배경, 아치 창문과 아침 햇살을 살리고 레서팬더·책·조명을 중심으로 구성했습니다.

## 입력과 최종 프롬프트

- Reference 1: `/Users/jaewook/Downloads/ChatGPT 이미지 2026년 10월 14일 오후 02_38_17.png`
- Reference 2: `/Users/jaewook/dev_app/focus_friend_app/assets/icon/app_icon_night.png` (생성 당시의 야간 버전)
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-d5035078-65cc-4cb8-b736-dbfbc8d0ab3a.png`

```text
Use case: style-transfer.
Asset type: an alternative square mobile app launcher icon for the cozy focus app "작은 집중방".
Input image 1 is the user-selected authoritative SUNNY MORNING STUDY ROOM, defining the character, palette and mood.
Input image 2 is ONLY a reference for the established SQUARE ICON COMPOSITION AND SUBJECT SCALE. Create a sunny morning counterpart with similarly sized face, book and lamp, but take the light warm environment from image 1.

Primary request: recompose image 1 into ONE polished square app icon. Preserve the orange red panda identity exactly: cream cheek markings and cream-lined ears, two cream eyebrow dots, big warm brown eyes, pink cheeks, tiny dark nose and calm smiling mouth, teal overalls with golden buttons, dark brown paws and orange-and-cream striped tail. Preserve the gentle tilted writing pose: yellow pencil with pink eraser touching the left page of the open ivory notebook, other paw on the right page. Put a compact golden brass study lamp immediately to the right. The face, book and lamp form one compact coherent foreground group, similar in layout and scale to image 2. Large face is the clear focal point, book in the lower middle, just a narrow warm honey-oak desk ledge below. A little curled striped tail visible at the left.

Replace the entire night environment with a soft sunny morning setting: pale creamy-apricot wall across the background, a very simplified slender slice of a rounded wooden arched window on the far left, light blue sky and a few broad sage-green leafy shapes visible through it. Soft warm morning sunlight enters from the left and adds a gentle highlight to the character and desk. The corners and the upper background are quiet cream colors, with no busy shapes. Retain the source's cozy morning ambiance. No dark navy, rain, night sky or dramatic spotlight. The lamp glows only gently because daylight is dominant. No shelving, picture frames, mugs, hanging vines or extra furniture.

Style: smooth original 2D animated-film cel illustration, clean medium-weight dark warm-brown lines, expressive rounded shapes, clear two-tone cel shading, warm orange, ivory, deep teal, honey-gold, cream and restrained sage-green. Match the linework of both references. No 3D, rough paper grain, watercolor, pixelation or photorealism.

Composition: one centered icon, all ears, paws, notebook corners and lamp base fully visible. Keep the meaningful group inside the central 76 percent of square width and height, with quiet warm-cream margins so it survives a circular or rounded-square crop. The lamp is tucked near the cheek rather than pushed off to the far edge. Do not shrink the face to make a full room: this is a clear small launcher icon, not a room illustration. No cut-off character features.

Output ONE finished opaque full-bleed SQUARE icon artwork only, 1024x1024 if possible. No pre-drawn rounded app tile, border, external white margins, text, letters, numerals, writing marks, captions, wordmarks, watermark, phone mockup, comparison board, extra characters or additional objects.
```

