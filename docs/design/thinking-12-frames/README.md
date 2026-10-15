# Red panda thinking — twelve-frame study

Date: 2026-10-08
Mode: built-in Image Gen, identity-preserve edit of the existing writing sheet.
Scope: review assets and previews; no app implementation changes.

## Deliverables

- [Twelve thinking frames](thinking-contact-sheet.png)
- [Thinking GIF](thinking-loop.gif)
- [Writing + thinking GIF](writing-and-thinking.gif)
- [Writing + thinking + page turn GIF](study-routine.gif)
- [Full routine video](study-routine.mp4)
- [Interactive review](index.html)
- [Thinking PNGs](thinking-12-frames.zip)
- [All thirty-six PNGs and preview files](study-motion-assets.zip)
- [Timeline and frame manifest](manifest.json)

## Motion and timing

The free paw rises to support the cheek, the eyes glance upward, the character pauses to think, then the paw lowers and the gaze returns to writing. The pencil stays in the other paw.

Twelve distinct drawings, with cels 6 and 7 each held for seven playback ticks. At 12 fps the thinking action lasts two seconds (24 playback ticks); these holds do not create extra drawings.

The writing + thinking preview repeats three one-second writing loops and then the two-second thought. The full routine adds three more writing loops, the existing twelve-frame page turn and a four-tick settle: 112 ticks, about 9.33 seconds. MP4 includes two cycles.

## References and packaging

- Edit target: `../writing-12-frames/writing-contact-sheet.png`.
- Acting reference: top-left thinking pose in `../cartoon-motion-concepts/03-expressive-cartoon-original-eyes.png`.
- Start/end registration reference: `../writing-12-frames/frames/frame-01.png`.
- Generated original: `/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-7971abc7-2c0c-456e-9aaf-93bf4f630eed.png`.
- Actual source size: 1448×1086; twelve equal 362×362 crops, no source resizing necessary.
- Existing writing and page-turn PNGs copied unchanged. All character artwork was created using built-in Image Gen; packaging only splits the sprite sheet, holds existing cels, and encodes media.
- Small drawing variations between generated cels remain. This is an animation review draft, not a final cleaned sprite set.

## Verification

- Twelve distinct 362×362 thinking PNGs. Twenty-four existing writing/page-turn PNGs copied byte-for-byte.
- Thinking GIF has twelve encoded cels and 2000 ms duration; writing/thinking GIF is 5000 ms; full routine GIF is 9330 ms.
- Full routine MP4: 362×362, 12 fps, 224 frames, 18.667 seconds (two cycles).
- Browser displayed all twelve thinking thumbnails at their correct aspect ratio. Stepping from held cel 6 advances directly to cel 7. The writing/thinking timeline ends at thinking cel 12 and steps into original writing cel 1.
- Browser left playing the two-second thinking loop, with other actions available in the selector.

## Exact prompt

```text
Use case: identity-preserve.
Asset type: ONE twelve-frame hand-drawn 2D sprite sheet, a red panda pausing its writing to think, then returning to writing.
Input roles: Image 1 is the EDIT TARGET, an existing precisely registered twelve-frame writing sheet. Image 2 is a concept reference: ONLY its top-left thinking pose shows the desired acting (free paw gently supporting cheek, quiet thoughtful glance). Image 3 is the exact neutral writing START/END pose. Do NOT copy the concept board layout, titles or numbers.
Primary request: Replace the writing action in image 1 with twelve successive animation cels of the SAME character pausing, resting its cheek on its free paw, thinking briefly, then returning to writing. This must be one coherent action, with careful in-betweens and stable character identity, not twelve alternative designs.

LAYOUT: Preserve image 1's 4:3 landscape, exactly FOUR columns and THREE rows, twelve equal SQUARE cells, 1448 x 1086 total. No borders, gutters, captions, title, numbers, thought bubbles, question marks, lightbulbs or motion marks. Reading order row-major, frames 1–4 top, 5–8 middle, 9–12 bottom. Each frame contains the complete seated red panda, its orange ringed tail at viewer-left, dark green apron, yellow pencil, open notebook with dark green cover, and the same narrow wooden desktop against the same plain warm ivory background. Keep everything safely inside its square. Same scale and camera throughout. Desk y=0.75, book bottom y=0.90, notebook spine x=0.58. Notebook, paper, markings, desk, tail, torso and clothing stay registered and unchanged.
IDENTITY: Preserve the original small warm brown oval eyes, narrow ivory whites, curved dark upper lids, little white glints, cream facial patches, orange fur, forehead spots, blush, nose and mouth proportions. The eyes are NOT large round doll eyes. Glance shifts move the pupils a little within the ORIGINAL small eye contours; never enlarge eye outlines or whites. No sudden change of face shape. Same textured 2D storybook rendering as image 1. The head may make a tiny smooth tilt, never scale or warp.
ACTING: The viewer-left paw always holds the pencil. It gently lifts its tip clear of the page and rests near the notebook while the character thinks. The viewer-right paw is the free hand: it leaves the right page, travels naturally upward, touches and supports the viewer-right cheek/chin with elbow resting on the desk, then travels back to its original resting place. Never switch pencil hands, never add hands. The head leans only very slightly into the supporting paw. Thoughtful sweet expression, tiny relaxed pursed mouth, a soft upward glance. No excited reaction, no large smile, no shouting. Eyes stay open throughout for model consistency. No page turning in this action.

TWELVE SUCCESSIVE CEL DRAWINGS:
01. Near image 3 writing pose. Pencil just stops and starts lifting from paper; free paw remains on the right page.
02. Pencil tip lifts a few millimetres clear, free paw starts rising toward chin.
03. Free paw halfway up, forearm bent naturally. Gaze starts leaving the notebook; head barely tilts.
04. Free paw reaches and lightly touches viewer-right cheek, elbow planted on desk; head eases into contact.
05. Cheek comfortably supported, slight upward-left thoughtful glance, small contemplative mouth.
06. Main thinking pose: cheek resting on paw, little upward gaze, head tilt only 3 degrees from original. This cel will be held in playback.
07. Tiny secondary eye glance while holding the SAME supported pose, subtle expression, no new gesture. This cel will also be held.
08. Gaze gently returns toward notebook; head begins straightening, cheek still lightly touches paw.
09. Cheek leaves supporting paw; free hand starts descending, head near original position.
10. Free hand halfway back down to right page, pencil starts lowering to writing position.
11. Free hand almost resting on right page, pencil near the paper; original focused downcast gaze restored.
12. Return to image 3's exact original writing-ready pose: original eyes, head tilt, hand placement, pencil, scale and book registration. This must join the existing writing loop.

Preserve unrelated artwork from image 1. Use small naturally spaced movements with slower changes around cheek contact and return. These are actual drawn frames, no motion blur, no ghosting, no multiple exposure, no volumetric 3D, no extra props. Exactly twelve distinct successive cels.
```
