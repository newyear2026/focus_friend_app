# 작은 집중방 — 픽셀 시안의 2D 애니메이션풍 변환

제작일: 2026-10-14
제작 도구: built-in `image_gen__imagegen`, style-transfer.
산출물: 정지 원화 시안 1장, 불투명 정사각 PNG.

## 방향

사용자가 선택한 픽셀 시안의 캐릭터, 필기 자세, 꼬리, 책상, 책과 조명 구도를 유지하면서 부드러운 윤곽선과 셀 채색으로 변환했습니다.

움직임을 추가할 경우 연필과 손목의 작은 필기 동작, 간헐적인 눈 깜빡임, 아주 약한 꼬리 움직임을 사용하는 방향이 어울립니다.

- Reference: `/Users/jaewook/Downloads/ChatGPT 이미지 2026년 10월 14일 오후 02_31_55.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-8cc9e4a4-d895-4276-ad29-6b36b52c8d97.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/10-cel-animation-study.png`

## 최종 프롬프트

```text
Use case: style-transfer.
Asset type: a single 2D animation-style illustration / app-icon concept for the cozy focus app "작은 집중방".
Edit target: input image 1, the user-selected pixel-art red panda studying at a desk.
Primary request: faithfully REDRAW this exact scene in a polished hand-drawn 2D animated-film cel style. Replace every pixel-art stair-step with graceful, intentional smooth contour lines and simple clean cel shading. Preserve the character identity, pose, composition, proportions, object placement, square framing, and warm cozy mood of the supplied image.

Invariants: the large orange red panda head in a gentle three-quarter pose, large cream-lined pointed ears, cream eyebrow dots and cheek markings, brown eyes with a small bright highlight, blush cheeks, tiny nose and gentle smile; teal overalls with gold buttons; dark brown paws; the left-image paw holding the yellow pencil with pink eraser, pencil tip touching the left page of the open book; the other paw resting on the right page; the large orange-and-cream striped tail behind the character on the left; the open cream notebook on the short warm wooden desk; the single brass/golden desk lamp on the right with its soft downward cone of warm light. Keep the ears, full tail, entire book, lamp and desk inside the square. Plain deep midnight-indigo background filling the image edge to edge. No room or new props.

Style: production-quality original 2D animation key-art still, smooth expressive linework of consistent medium thickness, rich dark warm-brown contours, crisp flat local colors with one or two clearly shaped cel-shadow tones, appealing rounded shapes, clean readable silhouettes, restrained warm amber rim-light from the lamp. The orange red panda and creamy paper should contrast strongly with the dark navy background. Warm, calm, thoughtful expression. Clearly TWO-DIMENSIONAL animation art; avoid painterly brush marks, watercolor or rough storybook paper texture. The image should feel ready to be used as a key pose for a gentle studying animation.

Composition: very closely match the reference layout and scale, one coherent centered scene, no cropping of important features. Single opaque square illustration only. No movement blur, no multiple frames, no sprite sheet, no drawn rounded app tile, no border, no captions, writing, numbers, text, UI, wordmarks or watermarks.
Avoid: ALL pixelation, mosaic patterns, stair-stepped edges, tiny pixel clusters, photorealism, clay, plush, 3D rendering, glossy plastic surfaces, excessively detailed fur, new accessories or extra objects.
```

