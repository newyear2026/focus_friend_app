# Rest tea animation sprite asset

- Mode: built-in `image_gen.imagegen`, reference-guided generation, transparent background.
- Asset: `assets/images/rest/redpanda-tea-sheet.png`.
- Original: `/Users/jaewook/.codex/generated_images/01a11dc7-897b-7a33-b100-df10bb431c7c/exec-bacafca2-0d29-429b-8e3f-c57aa5f89a0e.png`.
- Reference 1 (selected rest pose/design): `/var/folders/1d/f_54vtrd34b966kbj7vfrncc0000gn/T/codex-clipboard-3458b503-4482-4022-8d4e-e646af2cd84f.png`.
- Reference 2 (current character identity/style): `docs/design/calm-study-motion/home-day.png`.
- Requested dimensions: 2048 × 1536. Observed dimensions: **1448 × 1086 RGBA**, a regular 4 × 3 grid with **362 × 362 px** cells.
- Saved image is the unmodified original; genuine alpha ranges from 0 to 255. No cushion, furniture, background, ground shadow, labels, or grid lines.
- Frame order: left-to-right, top-to-bottom, 0–11.
- Stable opaque silhouette (alpha > 128): left x=58, right exclusive x=348 across all frames; upper y=45–48; bottom exclusive y=349–350.
- Suggested contact/bottom anchor in every cell: x≈155 (body/feet center), y=349. Tail extends right; do not center the full silhouette on the cushion, since that includes the tail.
- Nonzero low-alpha edge specks occur outside the opaque silhouette, including at cell borders; these are original output data. Opaque pixels remain inside their cells.
- Frames 0 and 11 are near-matching loop poses; slight art variation remains. Avoid rapid playback/crossfade every few milliseconds; use the requested slow sip rhythm.
- Asset-only task: no app code, scene, pubspec, or tests changed here.

## Exact generation prompt

```text
Use case: illustration-story
Asset type: production 2D game animation sprite sheet, transparent PNG
Primary request: Create ONE 4-column by 3-row sprite sheet containing exactly 12 equal SQUARE cells of a seated red panda slowly drinking tea. Requested overall canvas 2048 x 1536 pixels; each cell 512 x 512 pixels. No gaps or outer padding in grid layout (safe transparent margins WITHIN each cell).
Input images: Image 1 is the selected rest design and pose reference: use ONLY the orange/cream seated red panda at lower right, with green overalls and striped tail extending to viewer RIGHT, holding cream mug with green leaf. Image 2 is current character identity/style reference: preserve its hand-drawn storybook appearance, orange fluffy cheeks, cream muzzle and brows, round eyes, black-brown outline, green overalls, warm brown paws.
Scene/backdrop: genuine alpha transparency, no background. This asset will be composited onto an existing cushion in the app, so REMOVE ALL CUSHIONS, furniture, floor, background, ground shadows and interface text.
Subject: Exactly one same red panda in every cell, feet forward and slightly apart, brown soles/paw pads visible, seated rear between feet, striped fluffy tail curves to viewer RIGHT. Both hands hold the same small cream ceramic mug with one green leaf marking.
Style/medium: softly shaded flat hand-drawn 2D cel/storybook mascot illustration. Clean readable silhouettes, warm dark outline, limited cel shading. Match reference mascot, not realistic and not 3D.
Composition/framing: locked camera, fixed scale, same seated figure location, exactly same torso/head/feet/tail placement across ALL cells. Use identical bottom anchor y=460 within each 512-square cell, center body around x=226, tail to right fits to x=470. Whole character including tail fits within ~8% internal margins. No clipping. No perspective, scale, or body proportion changes between cells. Only forearms/paws/cup height, eyelids and tiny neck tilt change.
Animation: Row-major chronological order (left-to-right, top-to-bottom).
Top row: cell 0 cup low at lap eyes open relaxed; cell 1 same lap position briefly blinking; cell 2 cup rising halfway toward face; cell 3 cup just below mouth eyes softening.
Middle row: cell 4 rim reaches mouth eyes closed; cell 5 slight mug tilt to take sip, rim at mouth; cell 6 sip hold eyes closed; cell 7 mug returns upright still by mouth.
Bottom row: cell 8 cup lowering halfway; cell 9 cup back at lap eyes open soft smile; cell 10 same lap cup contented closed eyes; cell 11 exactly matches cell 0 for seamless loop.
Constraints: Mug and both paws move together, connected anatomically through forearms to shoulders. Exactly two arms, two hands, two feet, one tail in every frame. Same mug, outfit and leaf decoration all frames. Eyes move from open to relaxed closed and back. No steam (will be separate effect).
Avoid: text, numbers, cell borders, separators, gridlines, cushion, chair, carpet, floor, shadows, scenery, UI, random props, extra paws, deformed muzzle, moving body anchor, inconsistent scales. Real transparent background, not painted checkerboard.
```

