# 작은 집중방 — 앱 아이콘 시안

제작일: 2026-10-14
제작 도구: built-in `image_gen__imagegen` (opaque square PNG).
용도: 이미지 시안 비교. 런처에 연결하기 전의 원본 탐색안.

## 방향

| 시안 | 파일 | 의도 |
| --- | --- | --- |
| 1. 레서팬더 얼굴형 | `01-redpanda-face.png` | 캐릭터를 크게 보여주어 친근함과 작은 크기의 식별성을 우선함. 추천 방향. |
| 2. 공부하는 친구형 | `02-study-buddy.png` | 레서팬더와 노트·연필을 함께 사용해 공부·집중 앱이라는 성격을 표현함. |
| 3. 작은 집중방형 | `03-cozy-room.png` | 황혼의 창문·책상·조명으로 아늑한 집중 공간을 표현함. |
| 4. 시간을 안은 레서팬더 | `04-redpanda-timer.png` | 레서팬더가 둥근 타이머를 안아 집중 타이머라는 성격을 표현함. |
| 5. 꼬리로 감싼 책 | `05-tail-book-emblem.png` | 줄무늬 꼬리와 책을 결합한 단순한 상징으로 표현함. |
| 6. 레서팬더 책갈피 | `06-redpanda-bookmark.png` | 청록색 책 위로 얼굴을 내밀어 공부와 친근함을 표현함. |
| 7. 말랑한 클레이 | `07-clay-redpanda.png` | 라벤더 배경과 입체 클레이 캐릭터로 부드러운 재질감을 표현함. |
| 8. 모던 미니멀 | `08-geometric-focus.png` | 코발트블루와 단순한 도형으로 조명·책을 표현함. |
| 9. 레트로 픽셀 | `09-pixel-study.png` | 레서팬더의 공부 장면을 레트로 픽셀아트로 표현함. |
| 10. 2D 애니메이션 원화 | `10-cel-animation-study.png` | 선택한 픽셀 시안의 구도를 유지하며 매끈한 윤곽선과 셀 채색으로 변환함. |

현재 앱의 레서팬더 캐릭터와 몰입형 홈 원화를 참고했습니다. 열 이미지 모두 별도 PNG로 보존했습니다.

추가 4–6번의 입력과 최종 프롬프트는 [additional-concepts-04-06.md](additional-concepts-04-06.md)에 있습니다.

다른 스타일의 7–9번 입력과 최종 프롬프트는 [additional-styles-07-09.md](additional-styles-07-09.md)에 있습니다.

선택한 픽셀 시안의 2D 애니메이션풍 변환(10번)은 [pixel-to-cel-animation.md](pixel-to-cel-animation.md)에 기록했습니다.

## 입력과 최종 프롬프트

### 시안 1 · 레서팬더 얼굴형

- Reference: `/Users/jaewook/dev_app/focus_friend_app/assets/images/immersive/redpanda-reference.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-3efffa1c-9ce9-4d45-bf92-bd31d50994e5.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/01-redpanda-face.png`

```text
Use case: style-transfer / logo-brand.
Asset type: square mobile app launcher icon concept for the existing Korean cozy focus app "작은 집중방" (Focus Friend).
Input image 1 is an authoritative CHARACTER IDENTITY reference. Transform this existing red panda character into an extremely polished, simple character-portrait app icon. Preserve the recognizable orange red panda identity: ivory inner ears and cheek patches, two cream eyebrow dots, warm brown eyes, rounded dark nose, tiny friendly smile, subtle pink cheeks and a small dark teal overall neckline.
Composition: a single large front-facing head with both ears fully visible, very small shoulders, centered and symmetrical, occupying about 75 percent of the canvas width. Face is the unmistakable focal point; no paws, notebook, pencil or tail in this portrait. Use big clear shapes with a charming calm, encouraging expression. Clean dark warm-brown outlines, matte 2D storybook illustration, much simpler and bolder than the reference, restrained paper grain and minimal cel shading. Warm pale buttery cream background filling the entire square edge to edge, with a very subtle amber warmth behind the face. Saturated burnt orange and deep teal accents to match the app.
Output: ONE finished square icon artwork only, 1024x1024 if possible; opaque full bleed square. No rounded tile drawn inside the image; the operating system will mask the square. Keep all important face/ears inside central 78 percent so it survives both a circle and rounded square crop. Must remain immediately legible at 48px.
Avoid text, letters, numerals, labels, caption, wordmarks, watermarks, comparison boards, phone mockups, external margin, badges, outer border, glossy 3D, excessive furry detail.
```

### 시안 2 · 공부하는 친구형

- Reference: `/Users/jaewook/dev_app/focus_friend_app/assets/images/immersive/redpanda-reference.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-84f9a3ef-3714-4cbf-ad8c-d49f9ce4cb5d.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/02-study-buddy.png`

```text
Use case: style-transfer / logo-brand.
Asset type: square mobile launcher icon concept for "작은 집중방", an existing cozy focus timer app.
Input image 1 is the authoritative red panda CHARACTER IDENTITY reference. Recompose the existing character into a bold, simplified mobile app icon: a large warm orange red panda head and compact upper torso peeking over ONE open ivory notebook. Two small brown paws rest on the book, one holding a short golden pencil diagonally, with its tip touching the page. Retain ivory inner ears, cream cheek patches and two eyebrow dots, warm brown eyes, tiny nose, pink cheeks, dark teal overall straps. Calm absorbed expression, eyes gently looking downward toward the notebook. The face and open book should form ONE compact readable silhouette. The large head dominates; the notebook has only two broad pages and a central seam, no writing or rules. No tail or room.
Style: premium flat hand-drawn 2D storybook icon, thick warm dark outlines, broad simple shapes, muted matte texture and minimal cel shading. Deep dusky plum-charcoal background (#292630) full bleed, with subtle warm amber illumination around the character. Orange, warm ivory (#FFEBC5), gold (#FFC16F), dark teal. Strong clarity and contrast.
Composition: single centered icon, head in the upper middle, book below, everything important within central 76 percent of the square for circular and squircle masks. Face remains large and identifiable at 48px, notebook is a bold pale shape. Keep both ears and entire notebook visible.
Output ONE finished square icon artwork, opaque 1024x1024 if possible, edge-to-edge background. No rounded rectangle or app-tile outline drawn inside. No text, letters, numbers, labels, tiny book scribbles, logo type, watermark, comparison grid, phone mockup, badges, furniture, photorealism or 3D.
```

### 시안 3 · 작은 집중방형

- Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/immersive-room/reference.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-ed174820-1b72-40f1-a8f0-a22fd394df74.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/03-cozy-room.png`

```text
Use case: style-transfer / logo-brand.
Asset type: square mobile launcher icon concept for the existing cozy focus room app "작은 집중방".
Input image 1 is a MOOD AND ROOM-STYLE reference only. Distill the cozy dusk desk room into a beautifully simple emblem, with far fewer objects than the reference and without any UI or character. Primary subject: a single large softly arched window with a thick warm wooden frame, dusty indigo dusk sky and one low amber sun. In front of the window is a short dark warm wooden desk ledge supporting ONE small open ivory book and ONE compact golden desk lamp with a bent neck and simple downward bell-shaped shade. The lamp casts a soft triangular amber light onto the book. The arched window, lamp and open book form a compact emblem filling central 76 percent of the square; window is large, book and lamp are large bold readable shapes. No tiny scenery, no city buildings, no plants, no shelves, no mug, no extra objects.
Style: warm hand-drawn matte 2D storybook app icon with dark clean thick outlines, broad simple shapes, restrained paper texture and two-tone shading. Rounded friendly geometry, comfortable and inviting mood. Solid deep forest-teal background edge-to-edge; burnt terracotta wood, muted dusty blue-violet window, warm amber and cream accents echo the source room. Strong silhouette and contrast at 48px. No pictorial full room view, no intricate diorama.
Output ONE polished square icon artwork only, opaque full-bleed 1024x1024 if possible. Do not draw an internal rounded tile or badge; operating system handles cropping. All important shapes safely inside central 76 percent for circular and squircle crops. No text, letters, numerals, timer readout, UI, captions, watermarks, labels, phone mockups, comparison grid, external white margins, glossy 3D or photorealism.
```

