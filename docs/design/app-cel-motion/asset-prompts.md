# App cel animation — asset provenance

Mode: built-in Image Gen, transparent-background edits of the three approved 12-frame contact sheets. Individual outputs retain a 4 × 3 grid of 362 px cells. The shipping atlas mechanically stacks the sheets in writing, thinking, page-turn order; no pose interpolation, repainting, or pixel editing is performed by the atlas packer.

Shipping asset: `assets/images/redpanda-study-animation.png` (1448 × 3258 RGBA, 4 columns × 9 rows).

## writing

Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/writing-12-frames/writing-contact-sheet.png`

Transparent output: `assets/images/redpanda-writing-12.png`

Exact prompt:

```text
Use case: background-extraction. This is a PRECISE BACKGROUND REMOVAL edit of the supplied 12-frame red panda sprite sheet, NOT a redraw.
Remove ONLY the plain ivory background and the horizontal wooden tabletop strips from all twelve cells. Output the red panda character, tail, pencil, paws and entire green-bound notebook with all cream pages as clean cutouts on ACTUAL TRANSPARENT alpha. The internal cream fur, eye whites, cream paper and light highlights must stay fully opaque. Preserve fine outlines without white halos. Preserve the exact supplied facial identity, original small brown eyes, every pose, pencil position, page-turn shape, colours, textures, character size and position in EACH cell. Do not add, redraw, change expression, shift, recenter, rescale, or modify any foreground artwork. Remove the tabletop everywhere outside the notebook/character only; do not remove the notebook's brown/green outline or its pale pages. The twelve cutouts are intended to overlay the existing room table in the app.
Maintain the same source 1448x1086 canvas and its EXACT equal 4-column by 3-row square-cell grid. Each cell stays in the same place, with the same original margins; no automatic tight cropping. Exactly twelve original writing poses, same row-major order. No new title, grid, text, shadows, checkerboard pixels or background. Genuine transparent PNG, not an illustration of a checkerboard.
```

## thinking

Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/thinking-12-frames/thinking-contact-sheet.png`

Transparent output: `assets/images/redpanda-thinking-12.png`

Exact prompt:

```text
Use case: background-extraction. This is a PRECISE BACKGROUND REMOVAL edit of the supplied 12-frame red panda sprite sheet, NOT a redraw.
Remove ONLY the plain ivory background and the horizontal wooden tabletop strips from all twelve cells. Output the red panda character, tail, pencil, paws and entire green-bound notebook with all cream pages as clean cutouts on ACTUAL TRANSPARENT alpha. The internal cream fur, eye whites, cream paper and light highlights must stay fully opaque. Preserve fine outlines without white halos. Preserve the exact supplied facial identity, original small brown eyes, every pose, pencil position, page-turn shape, colours, textures, character size and position in EACH cell. Do not add, redraw, change expression, shift, recenter, rescale, or modify any foreground artwork. Remove the tabletop everywhere outside the notebook/character only; do not remove the notebook's brown/green outline or its pale pages. The twelve cutouts are intended to overlay the existing room table in the app.
Maintain the same source 1448x1086 canvas and its EXACT equal 4-column by 3-row square-cell grid. Each cell stays in the same place, with the same original margins; no automatic tight cropping. Exactly twelve original thinking poses, same row-major order. No new title, grid, text, shadows, checkerboard pixels or background. Genuine transparent PNG, not an illustration of a checkerboard.
```

## page-turn

Reference: `/Users/jaewook/dev_app/focus_friend_app/docs/design/page-turn-12-frames/page-turn-contact-sheet.png`

Transparent output: `assets/images/redpanda-page-turn-12.png`

Exact prompt:

```text
Use case: background-extraction. This is a PRECISE BACKGROUND REMOVAL edit of the supplied 12-frame red panda sprite sheet, NOT a redraw.
Remove ONLY the plain ivory background and the horizontal wooden tabletop strips from all twelve cells. Output the red panda character, tail, pencil, paws and entire green-bound notebook with all cream pages as clean cutouts on ACTUAL TRANSPARENT alpha. The internal cream fur, eye whites, cream paper and light highlights must stay fully opaque. Preserve fine outlines without white halos. Preserve the exact supplied facial identity, original small brown eyes, every pose, pencil position, page-turn shape, colours, textures, character size and position in EACH cell. Do not add, redraw, change expression, shift, recenter, rescale, or modify any foreground artwork. Remove the tabletop everywhere outside the notebook/character only; do not remove the notebook's brown/green outline or its pale pages. The twelve cutouts are intended to overlay the existing room table in the app.
Maintain the same source 1448x1086 canvas and its EXACT equal 4-column by 3-row square-cell grid. Each cell stays in the same place, with the same original margins; no automatic tight cropping. Exactly twelve original page-turn poses, same row-major order. No new title, grid, text, shadows, checkerboard pixels or background. Genuine transparent PNG, not an illustration of a checkerboard.
```

