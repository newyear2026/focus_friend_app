# Page turn and writing — twelve-frame motion study

Date: 2026-10-08
Mode: built-in Image Gen, identity-preserve edit of the existing writing sprite sheet.
Status: review animation assets; no app code changes.

## Outputs

- [Page-turn 12-frame board](page-turn-contact-sheet.png)
- [Page-turn GIF](page-turn-loop-12fps.gif)
- [Writing + page-turn GIF](writing-and-page-turn.gif)
- [Writing + page-turn MP4](writing-and-page-turn.mp4)
- [Interactive review](index.html)
- [Page-turn 12 PNGs](page-turn-12-frames.zip)
- [Both actions and playback files](writing-and-page-turn-assets.zip)
- [Frame manifest and timeline](manifest.json)

## Sequence

Twelve new page-turn cels. Frames 1–3 reach and grip; 4–8 lift the right page, pass the spine, and lower onto the left; 9–10 settle and release; 11–12 return toward the writing posture.

Combined preview at 12 fps: four one-second writing loops, four ticks holding the raised-pencil writing pose, twelve page-turn ticks, four ticks holding the settled page-turn pose, then return to writing. Total 68 playback ticks, approximately 5.67 seconds. The MP4 contains two cycles.

## Source and packaging

- New source: `/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-6bd494fd-8c00-4409-9827-29234a06b716.png`
- References, in order: existing writing contact sheet; writing frame 01; writing frame 12.
- The generator returned 1447×1087. The retained raw source is normalized by one pixel to a 1448×1086 grid and split into twelve 362×362 PNGs.
- Existing writing PNGs are copied unchanged. All character and page drawing comes from Image Gen. Packaging only crops/resizes the sheet, copies files and encodes GIF/MP4; no procedural redraw, mesh deformation, crossfades or generated in-betweens are added by code.
- This is a visual review draft. Small drawing differences remain between generated cels and at the join; the preview does not establish production-ready registration.

## Verification

- Twelve distinct page-turn PNGs, all 362×362; all twelve copied writing PNGs match their originals byte for byte.
- Page-turn GIF: twelve frames, 1000 ms. Connected GIF: 5670 ms including held cels.
- MP4: 362×362, 12 fps, 136 frames, 11.333 seconds (two connected cycles).
- Browser: inspected the raised-page pose, selected the final settling frame at timeline tick 68, stepped forward to the original writing frame 01, then resumed combined playback.
- Download bundle contains all twenty-four PNGs and the self-contained review page with relative assets.

## Exact prompt

```text
Use case: identity-preserve.
Asset type: ONE precisely registered 12-frame 2D animation sprite sheet, a page-turn sequence that joins an existing red panda writing loop.
Inputs: Image 1 is the EDIT TARGET, an existing 4-column by 3-row sheet of twelve writing frames. Image 2 is the exact required REST/END pose from writing frame 01. Image 3 is the raised-pencil START pose from writing frame 12.
Edit image 1 by replacing ONLY the hand/forearm/pencil and paper action in its twelve cells with the twelve consecutive page-turn drawings described below. Keep the same character model and precise cell alignment. The result will be sliced mechanically into twelve equal squares then played left-to-right, top-to-bottom. It must show one continuous physically coherent action, not a collection of alternative poses.

GEOMETRY: Preserve the input sheet's 1448 x 1086 pixel, 4:3 landscape composition, exactly FOUR columns and THREE rows, twelve identical square cells, no gutters. All twelve cells repeat the exact framing, scale and registered positions of the character, face, body, tail, book cover and desk from input 1. The character remains anchored at the same place. Ears around y=0.085, face centre about x=0.61/y=0.49, tabletop at y=0.75, notebook bottom at y=0.90. Central book spine x=0.58, its top hinge at y=0.75 and bottom hinge at y=0.89. Absolutely no camera zoom or character size change. No labels, numbers, captions, title, grid lines, motion ticks or speed lines.

CHARACTER LOCK: Exactly the same original small warm dark-brown oval eyes with narrow ivory whites and curved dark upper eyelids. Same gaze lowered toward notebook, same eyes open throughout, same head tilt, nose, mouth, orange/cream facial fur, blush, green apron, rings on the tail and textured hand-drawn 2D art. Do not alter head, face, eyes, ears, tail or torso at all. Do not introduce the giant round white eyes from earlier discarded artwork. No smile change or blinking. Keep fixed background, held character areas and book cover visually identical between all twelve cells.

ACTION: The viewer-LEFT paw CONTINUES TO HOLD the yellow pencil safely lifted off the LEFT page throughout the page turn, then gently lowers to resume writing at the very end. It never touches the moving paper and never changes hands. The viewer-RIGHT paw alone turns ONE thin cream paper sheet from the viewer-RIGHT page over to the viewer-LEFT page, hinged to the notebook's centre spine. The page bends smoothly, curls as it crosses the centre, and settles flat on the left. Correct paper continuity: it stays attached to the spine in every drawing; no loose floating rectangle, no tearing, no detached triangular flap, no second moving sheet. Gripping paw follows the same free corner throughout the arc, reaches toward the left to press it down, then returns to rest on the right. Natural compact paws, no extra arms or duplicate hands.

TWELVE CONSECUTIVE FRAMES:
1. Begin from input 3, pencil raised; viewer-right paw just starting to lift off its resting spot toward the right page corner, page flat.
2. Right paw moves outward over the top-right free corner, page still flat.
3. Paw pinches the right page corner; just its edge peels up slightly.
4. Pull the page upward, a shallow curved lift around 25 degrees; paw and paper free corner travel up and inward.
5. Paper continues upward/inward around 55 degrees, visibly curved and connected to the spine.
6. Paper near vertical over the central spine, the right page beneath is revealed. Gripping paw follows the upper free edge.
7. Sheet clearly crosses over the spine toward the viewer-left, bends with a soft natural curl, and begins falling left.
8. Sheet reaches the left side at a shallow angle, lower edge touching the left stack.
9. Turn complete: sheet lies flat on the LEFT page. Viewer-right paw presses the newly turned page on the left; pencil paw remains held clear.
10. Paw releases the page and starts returning to the right. Page stays flat.
11. Paw nearly back to its original right-page resting position, pencil lowers slightly toward writing.
12. Return to the EXACT registered drawing and hand positions of input 2: right paw resting, left paw holding pencil ready to write, open flat notebook. Match input2 as faithfully as possible so playback can continue directly into the existing writing loop.
Preserve input2's general page scribbles for the settled end pose without any readable writing. The end result is a clean hand-drawn twelve-frame sequence for review, warm uniform ivory backdrop, same slightly rough brown outlines and textured orange fur as inputs.
```
