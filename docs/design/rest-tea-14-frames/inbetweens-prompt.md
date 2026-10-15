# Two extra tea cels

Generated using the built-in image generation tool. The original 12-cel atlas is the edit reference. Output is preserved unmodified at `assets/images/rest/redpanda-tea-inbetweens.png` (1774×887, RGBA).

The generated left pose is higher than requested, so it is registered between original cel 3 and 4. The right pose is inserted between original cel 8 and 9.

```text
Use case: precise-object-edit / animation inbetween drawing.
Input image is an existing 4-column x 3-row twelve-cel sprite sheet. Treat its first and third cels in row 1 and its first two cels in row 3 as the exact art to match. Produce ONLY TWO NEW FULL-CHARACTER INBETWEEN CELS, side by side in a 2-column x 1-row sheet of equal square cells, requested total 1448x724. Genuine transparent background.
The user prefers this ORIGINAL full cel animation and wants just two extra drawings; do NOT redesign, simplify, make a puppet, or separate limbs. Retain the same hand-painted cel shading, orange-red panda identity, small round eyes, muzzle, cream eyebrows, dark outlines, green overalls, brown footpads, front-facing seated pose and striped tail extending viewer-right.
Cell LEFT is halfway between input row1 column1 and row1 column3: the cream leaf mug and BOTH gripping paws have lifted only HALF of that gap. Mug rim approximately y=220/362 and bottom y=275/362 in normalized original cell coordinates. Eyes open, exactly the relaxed head/face from input row1 column1, elbows attached. The cup is upright.
Cell RIGHT is halfway between input row3 column1 and row3 column2: the cup and BOTH paws lower halfway toward lap, rim approximately y=220/362, bottom y=276/362. Eyes open with the original gentle relaxed smile, shoulders and face exactly match row3 column1. Cup upright.
Composition CRITICAL: copy the original character scale and coordinates. In each square cell, left silhouette at x=58/362, right tail extent x=348/362, highest ear y=46/362, bottoms of feet y=349/362. Body seated contact center is x=155/362, y=349/362. Exact same body/feet/tail size and position as the original cels. Do not center the entire silhouette because the tail extends right. Keep the face, feet, tail and body proportions completely still. ONLY the cup/paws/forearms change.
Same one mug with same SMALL green leaf emblem, same highlights, same outline thickness. Exactly one entire seated panda per cell. Transparent space between and around them, no cushion, no shadow, no room, no labels, no frame numbers, no dividers, no grids. Preserve original soft illustrated style, not a new flat vector style.
```
