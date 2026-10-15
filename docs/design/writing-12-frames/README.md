# 랫서팬더 필기 동작 — 12프레임 시안

- Created: 2026-10-08
- Artwork: built-in Image Gen, identity-preserve, one 4×3 sprite sheet.
- References: selected `../cartoon-motion-concepts/03-expressive-cartoon-original-eyes.png` and original `../../../assets/images/redpanda-study-sheet.png`.
- Output: actual generated sheet 1448×1086; twelve distinct 362×362 PNG frames extracted in row-major order.
- Playback: 12 fps, 1 second per loop; the review page also offers 6 fps and frame stepping. GIF timing uses 80/90/80 ms repeated four times for an exact 1000 ms loop.
- Scope: visual review sample; not installed in the app. No interpolation or procedural character deformation. Python only copies the source, crops equal cells, and packages GIF/ZIP; all drawn artwork comes from Image Gen.

## Files

- [Interactive review](index.html)
- [12-frame sheet](writing-contact-sheet.png)
- [Animated GIF](writing-loop-12fps.gif)
- [Eight-loop MP4 preview](writing-preview.mp4)
- [12 individual PNG frames](writing-12-frames.zip)
- [Frame manifest](manifest.json)

## Verification

- Extracted twelve equal 362×362 PNGs; all twelve pixel hashes differ.
- Decoded GIF has twelve frames and exactly 1000 ms total duration.
- Browser preview loaded all twelve thumbnails; verified frame 12 steps back to frame 1, switching to 6 fps displays a 2-second loop, and returning to 12 fps resumes playback.
- Thumbnail aspect ratio corrected and visually rechecked. Generated artwork is a review draft; it has small drawing variations between frames and is not a final cleaned animation asset.

## Prompt

```text
Use case: identity-preserve.
Asset type: ONE production-style 12-frame sprite sheet for a hand-drawn 2D red-panda writing animation, used to extract twelve separate images and play them in sequence.
Input image 1 is the selected character/style reference; use ONLY its lower-left panel 3, the bowed-head writing pose. Input image 2 is the canonical original character reference for the compact brown eyes, narrow white crescent and curved upper eyelids.
Primary request: Draw twelve DISTINCT consecutive in-between animation frames of this EXACT red panda WRITING IN ITS NOTEBOOK. Every cell shows the same fixed camera, full seated character, orange ringed tail on viewer-left, dark-green apron, yellow pencil in the viewer-left paw, other paw planted on the right page, open dark-green notebook and narrow warm wooden desk strip. Keep the charming orange/cream textured 2D storybook artwork, focused downcast compact eyes and slight head tilt from panel 3. No change of character identity.
Sheet geometry: 3072 x 2304 pixel landscape canvas, precisely FOUR columns by THREE rows, twelve equally-sized SQUARE 768 x 768 cells, NO gutters, NO border, NO grid lines, NO title, NO numbers, NO captions. Read in row-major order: row1 frames 1-4, row2 frames 5-8, row3 frames 9-12. Plain uniform warm-ivory background throughout.
Registration is essential: In EACH cell repeat exactly the same character scale and placement, ears entirely visible within top 12 percent margin, tail entirely visible within left 6 percent margin; notebook spine fixed at x=0.59, notebook bottom fixed at y=0.88, desk bottom at y=0.92. Identical head size, face, eye positions, body, tail, resting paw, book outline, book spine, page markings and desk in every cell. The full drawing fits safely within its cell. No zoom, no perspective changes, no alternating views. Keep inactive areas visually identical as if on held animation cels.
Animated area: Animate the writing forearm, wrist, fingers and pencil only; a very slight coordinated shoulder response is allowed. Use modest but clearly readable successive hand-drawn changes, not twelve copies of one drawing. The pencil tip makes two short connected curved writing strokes on the LEFT notebook page, moving gradually about 0.04 cell width overall. Paw securely grips pencil with proper anatomy, pencil tip truly contacts the paper in frames 1-8.
Motion breakdown (consecutive frames, not unrelated poses):
1: Pencil contacts the start of a small stroke, wrist relaxed.
2: Pencil tip moves slightly down-right, wrist flexes slightly.
3: Small upward hook, pencil pivots a few degrees.
4: Finish first curve farther right, paw follows.
5: Begin second small downstroke.
6: Tip slightly farther right and lower.
7: Small upward finishing hook.
8: Stroke settles, pencil at its rightmost position.
9: Pencil tip lifts just above paper, wrist relaxes.
10: Raised pencil and paw travel halfway back left to the starting point.
11: Pencil reaches the starting point, still very slightly above paper.
12: Pencil lowers almost into the frame-1 contact pose, with only a tiny gap remaining. Frame12-to-frame1 loops smoothly.
Keep head, face and gaze steady and original in all twelve; no blinking for this writing-only loop. Tiny hand motion, not whole-character wobbling. Keep the same existing notebook scribbles; do not add readable text.
Constraints: Exactly twelve drawings in a 4x3 array. No thought pose, no excited smile, no page turn, no closed eyes, no giant white round eyes, no giant pupils, no photorealism, no 3D, no motion blur, no duplicated arms, no extra fingers, no changing fur marks, no varying notebook size, no props added. Preserve the canonical character and natural 2D cartoon draftsmanship.
```
