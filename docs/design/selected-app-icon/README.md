# 작은 집중방 — 선택한 앱 아이콘

제작일: 2026-10-14
제작 도구: built-in `image_gen__imagegen`.
원본: 사용자가 선택한 ‘비 오는 밤’ 2D 애니메이션풍 배경.

## 결과와 적용

- 원본 생성물: `generated-original.png`
- 배포용 마스터: `../../../assets/icon/app_icon.png` (1024×1024, 불투명 RGB PNG)
- 기본 아이콘: Android `mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi/ic_launcher.png` (48/72/96/144/192px)
- Android 8 이상: `mipmap-anydpi-v26/ic_launcher.xml`에서 남색 배경과 그림 레이어를 조합.
- 그림 레이어는 각 방향 20% inset을 두어 캐릭터, 책, 조명을 마스크 안쪽에 배치.
- `AndroidManifest.xml`의 기본 아이콘과 roundIcon이 같은 새 리소스를 사용.
- 형태별 예상 표시: `preview.html`. 실제 기기 캡처와는 별도의 CSS 미리보기.

리소스 레이어와 마스크 구성은 [Android 적응형 아이콘 지침](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive?hl=ko)을 참고했습니다.

## 검증

- `flutter build apk --debug --no-pub` 성공.
- AAPT2로 APK의 기본 아이콘이 새 adaptive XML과 그림 리소스에 연결된 것을 확인.
- Pixel 3 / Android 16 에뮬레이터에 `adb install -r` 성공.
- 실제 앱 목록의 ‘작은 집중방 Dev’ 항목에 새 원형 아이콘이 표시되는 것을 확인: `launcher.png`, `launcher.xml`.
- CSS 미리보기에서 원형·둥근 사각형과 96px·48px 표시를 시각 확인.
- 아이콘 변경 파일의 `git diff --check` 통과.

## 입력과 최종 프롬프트

- Reference: `/Users/jaewook/Downloads/ChatGPT 이미지 2026년 10월 14일 오후 02_38_44.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-02ee329f-833b-4de7-822d-db13e6db380f.png`

```text
Use case: style-transfer.
Asset type: a final square mobile launcher icon for the cozy focus app "작은 집중방".
Input image 1 is the user-selected authoritative rainy-night study-room illustration. Recompose this artwork into ONE polished, immediately readable SQUARE APP ICON. Faithfully preserve the same warm 2D cel-animation character design and linework, orange red panda with ivory cheeks, cream-lined ears, two cream eyebrow dots, expressive brown eyes, pink cheeks, tiny friendly smile, dark brown paws and teal overalls with golden buttons. Preserve the calm slightly tilted studying pose: one paw holding a yellow pencil with pink eraser touching an open ivory notebook, the other paw on the right page. One compact brass-gold desk lamp to the right with warm amber light on the book. Small part of the orange-and-cream striped tail peeks at the left, only if it fits without reducing the face. A very short warm wooden desk ledge beneath the book. The character face is THE focal point, large and clear, occupying about 48 percent of the square width. The face, book and little lamp form ONE compact silhouette.
Background: deep midnight navy matching the source, very simplified. At the far left, only a subtle narrow blue rainy-window suggestion with a few broad raindrop streaks and one muted distant amber glow, no elaborate scenery. The rest is a quiet solid navy field, especially the corners; no shelves, plants, picture frames, chair, mug, stacks of books or room clutter.
Composition: centered compact illustration, ears at about 17 percent from the top, bottom of book around 80 percent from the top. Entire meaningful silhouette fits within the CENTRAL 72 percent of square width and height. Ensure the ears, eyes, book corners, lamp shade and base all sit safely inside a centered circular crop; outer 14 percent on every edge is only quiet navy background. The lamp is smaller and tucked close to the right cheek, not far off at the edge. Keep all features large, avoid tiny details. No pre-drawn rounded app-tile shape; opaque navy fills the whole square edge to edge.
Style: exactly the smooth expressive 2D animation ink-and-cel finish of the reference, strong clean warm-brown contours, warm orange and ivory, deep teal and gold, shaped two-tone shading, restrained warm lamplight. Very appealing as a real launcher icon at 48px.
Output: ONE finished opaque square icon artwork only, 1024x1024 if possible. No text, words, letters, numerals, timer digits, labels, watermarks, logo typography, phone mockup, comparison board, external margins, app-tile border, rounded frame, pixel art, photorealism, clay, 3D, watercolor texture or detailed fur.
```

