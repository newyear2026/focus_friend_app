# 작은 집중방 — 2D 애니메이션풍 배경 시안

제작일: 2026-10-14
제작 도구: built-in `image_gen__imagegen` (style-transfer).
용도: 선택한 2D 캐릭터 그림체를 확장한 세로형 앱 배경 이미지 시안.

## 방향

| 시안 | 파일 | 분위기 |
| --- | --- | --- |
| 1. 노을 창가 | `01-sunset-window.png` | 보랏빛 노을, 따뜻한 나무 책상과 조명 |
| 2. 비 오는 밤 | `02-rainy-night.png` | 빗방울 맺힌 창, 짙은 남색 방과 황금빛 조명 |
| 3. 아침의 작은 서재 | `03-morning-library.png` | 크림색 벽, 아치 창문과 부드러운 아침 햇살 |

캐릭터와 공부 장면을 아래쪽에 배치하고 위쪽 중앙에는 타이머와 문구를 놓을 여백을 요청했습니다. 세 이미지 모두 글자나 UI가 없는 불투명 배경 원화입니다.

## 입력과 최종 프롬프트

### 배경 시안 1 · 노을 창가

- Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/10-cel-animation-study.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-1007dc59-3c28-4720-8660-9de571841c67.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cel-room-background-concepts/01-sunset-window.png`

```text
Use case: style-transfer.
Asset type: a portrait 9:16 illustrated background concept for the mobile cozy focus app "작은 집중방".
Input image 1 is the authoritative CHARACTER IDENTITY AND 2D CEL-ANIMATION STYLE reference. Expand its isolated studying scene into a complete inviting little study room. Preserve the SAME appealing red panda identity: orange fur, cream cheeks and eyebrow dots, cream-lined ears, brown eyes with small highlights, pink blush, small smiling mouth, large orange-and-cream striped tail, teal overalls with gold buttons, dark brown paws, yellow pencil and open cream notebook. Keep the gentle three-quarter writing pose and calm absorbed expression. Redraw the whole environment in matching smooth dark warm-brown outlines, clean shaped cel shading, rounded animated-film shapes and flat local colors. No grainy storybook texture, pixelation, clay or 3D rendering.
Composition: tall full-bleed portrait, aspect 9:16, ideally 1080x1920. It must read as a ROOM BACKGROUND for a phone, rather than a close-up icon. The seated character is a medium-small resident in the lower-middle, its head about 28 percent of total canvas width, not a giant mascot floating in front. Full ears, tail, hands, notebook and lamp visible. Put the character and active study scene between approximately 47 and 81 percent of canvas height, desk surface around 77–84 percent height. Keep the upper central area from approximately 10–36 percent height visually calm and low-detail for future app text and timer overlays, without drawing any text or overlays. Keep the bottom 12 percent simple and uncluttered for future controls. Richer room details at the peripheral sides only. Warm amber desk lamp illuminates the notebook. Cozy livable scale, no clutter.
Constraints: ONE complete beautifully composed portrait illustration only. Opaque background edge-to-edge. No UI, timer digits, title, text, letters, numbers, labels, visible writing, watermark, logos, borders, phone frame, comparison board, multiple panels or extra characters.
Scene/backdrop: a small warm wooden study nook by a large wooden-framed window. Outside, a soft peach-and-lavender dusk sky with simple distant tree silhouettes and a few tiny distant warm lights near the horizon. Keep the UPPER CENTER as broad quiet dusty-indigo sky without bright clouds, crossbars or a sun behind the eventual timer. Window frame near the side edges, horizon in the lower part of the window. The red panda writes at the lower-middle wooden desk with the familiar brass lamp to its right, striped tail curving gently left. At far left edge, a short shelf with only three plain muted books and one trailing green plant. On the far right of the desk, one simple small cream mug. Background walls in muted mauve, honey-colored wood, dusty lavender twilight, teal fabric chair. Warm sunset rim light and golden lamp pool, restrained bright highlights. Mood: comfortable, welcoming, nostalgic, a gentle animated-film evening. Match the clean 2D animation rendering of the input, not watercolor.
```

### 배경 시안 2 · 비 오는 밤

- Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/10-cel-animation-study.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-e9f76ea3-1bfc-4e85-b5e7-f97f0279cd8a.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cel-room-background-concepts/02-rainy-night.png`

```text
Use case: style-transfer.
Asset type: a portrait 9:16 illustrated background concept for the mobile cozy focus app "작은 집중방".
Input image 1 is the authoritative CHARACTER IDENTITY AND 2D CEL-ANIMATION STYLE reference. Expand its isolated studying scene into a complete inviting little study room. Preserve the SAME appealing red panda identity: orange fur, cream cheeks and eyebrow dots, cream-lined ears, brown eyes with small highlights, pink blush, small smiling mouth, large orange-and-cream striped tail, teal overalls with gold buttons, dark brown paws, yellow pencil and open cream notebook. Keep the gentle three-quarter writing pose and calm absorbed expression. Redraw the whole environment in matching smooth dark warm-brown outlines, clean shaped cel shading, rounded animated-film shapes and flat local colors. No grainy storybook texture, pixelation, clay or 3D rendering.
Composition: tall full-bleed portrait, aspect 9:16, ideally 1080x1920. It must read as a ROOM BACKGROUND for a phone, rather than a close-up icon. The seated character is a medium-small resident in the lower-middle, its head about 28 percent of total canvas width, not a giant mascot floating in front. Full ears, tail, hands, notebook and lamp visible. Put the character and active study scene between approximately 47 and 81 percent of canvas height, desk surface around 77–84 percent height. Keep the upper central area from approximately 10–36 percent height visually calm and low-detail for future app text and timer overlays, without drawing any text or overlays. Keep the bottom 12 percent simple and uncluttered for future controls. Richer room details at the peripheral sides only. Warm amber desk lamp illuminates the notebook. Cozy livable scale, no clutter.
Constraints: ONE complete beautifully composed portrait illustration only. Opaque background edge-to-edge. No UI, timer digits, title, text, letters, numbers, labels, visible writing, watermark, logos, borders, phone frame, comparison board, multiple panels or extra characters.
Scene/backdrop: a peaceful small corner study room on a rainy night. A tall rain-speckled window occupies the upper-left and middle background; a simple deep navy wall occupies the upper-center/right, leaving a wide calm dark region for future timer text. Window raindrops are sparse simple clean highlights and a few long trails, with only softly simplified indigo-blue tree silhouettes and distant amber bokeh outside. No highly detailed city view. The red panda writes at a warm walnut desk below, centered slightly right; the familiar small brass desk lamp is on its right, glowing amber. Tail curves left behind the teal chair, matching the reference. One plain small closed book and one cream mug sit far left on the desk. A single small leafy plant silhouette at the far right edge. Deep midnight navy and cool desaturated blue environment contrasted with honey-orange panda and warm cream pages. Lamplight reaches the cheeks, pencil and paws. The lamp's light is a soft local pool, not an exaggerated spotlight filling the upper screen. Mood: rainy lo-fi concentration, sheltered, quiet, cinematic but cute. Strongly consistent clean 2D cel animation lines and shaped shadows, no painterly texture.
```

### 배경 시안 3 · 아침의 작은 서재

- Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/app-icon-concepts/10-cel-animation-study.png`
- Generated source: `/Users/jaewook/.codex/generated_images/01a13c10-9942-7240-acb0-f9af887a6868/exec-c3e6cb41-fd1b-41f4-b685-455c7bd808ca.png`
- Saved output: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cel-room-background-concepts/03-morning-library.png`

```text
Use case: style-transfer.
Asset type: a portrait 9:16 illustrated background concept for the mobile cozy focus app "작은 집중방".
Input image 1 is the authoritative CHARACTER IDENTITY AND 2D CEL-ANIMATION STYLE reference. Expand its isolated studying scene into a complete inviting little study room. Preserve the SAME appealing red panda identity: orange fur, cream cheeks and eyebrow dots, cream-lined ears, brown eyes with small highlights, pink blush, small smiling mouth, large orange-and-cream striped tail, teal overalls with gold buttons, dark brown paws, yellow pencil and open cream notebook. Keep the gentle three-quarter writing pose and calm absorbed expression. Redraw the whole environment in matching smooth dark warm-brown outlines, clean shaped cel shading, rounded animated-film shapes and flat local colors. No grainy storybook texture, pixelation, clay or 3D rendering.
Composition: tall full-bleed portrait, aspect 9:16, ideally 1080x1920. It must read as a ROOM BACKGROUND for a phone, rather than a close-up icon. The seated character is a medium-small resident in the lower-middle, its head about 28 percent of total canvas width, not a giant mascot floating in front. Full ears, tail, hands, notebook and lamp visible. Put the character and active study scene between approximately 47 and 81 percent of canvas height, desk surface around 77–84 percent height. Keep the upper central area from approximately 10–36 percent height visually calm and low-detail for future app text and timer overlays, without drawing any text or overlays. Keep the bottom 12 percent simple and uncluttered for future controls. Richer room details at the peripheral sides only. Warm amber desk lamp illuminates the notebook. Cozy livable scale, no clutter.
Constraints: ONE complete beautifully composed portrait illustration only. Opaque background edge-to-edge. No UI, timer digits, title, text, letters, numbers, labels, visible writing, watermark, logos, borders, phone frame, comparison board, multiple panels or extra characters.
Scene/backdrop: a light airy compact attic study with creamy warm plaster walls and a softly sloped ceiling. A medium arched window at the left-middle background reveals soft blue morning sky and a simple leafy tree. Broad quiet cream wall occupies the UPPER CENTER with a very subtle pale warm shadow, clear of objects and strong architectural lines where future text will sit. A low built-in bookshelf only along the right peripheral edge holds several plain sage, terracotta and teal books, no titles. A tiny hanging plant near the left edge, no busy vines in the center. The reference red panda is seated at a honey-oak desk below, centered slightly left, writing the same notebook; familiar brass lamp stands to its right with very subtle glow, striped tail visible to its left. One small terracotta plant pot far right on the desk, no extra desk objects. Soft morning sunlight entering from the left forms a restrained diagonal light patch on the desk and warm rim on the character, NOT across the upper text area. Muted cream, pale apricot, soft sage green and dusty teal palette, orange panda as the focal accent. Mood: fresh calm morning, hopeful, gentle and clean. Clean 2D cel animation rendering with controlled line weight, broad shaped highlights, no watercolor, sketch marks or paper grain.
```

