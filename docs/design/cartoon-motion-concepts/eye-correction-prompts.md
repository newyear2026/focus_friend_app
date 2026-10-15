# Original-eye identity corrections

Date: 2026-10-08
Mode: built-in image_gen; image edits, identity-preserve.
Status: static review concepts only; no app implementation or animation changes.

## Reason

The earlier three concept boards inherited enlarged round eyes from the puppet reference. The user identified that these differed from the original red panda. These sibling versions use the original character as the eye reference. Earlier boards and generated source files are retained.

## Canonical character references

- `assets/images/redpanda-study-sheet.png`
- `docs/design/character-concepts/redpanda-writing-study.png`

The original has compact brown oval eyes, narrow visible white, and curved upper eyelids. The rejected `current-character-reference.png` is not used as the identity reference for this correction.

## Outputs and inspection

- [01 · 잔잔한 손그림](01-quiet-handdrawn-original-eyes.png): source `/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-cf6dd249-5ab0-40e4-89cc-33ed3806cd7d.png`.
- [02 · 말랑한 만화](02-soft-cartoon-original-eyes.png): source `/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-f1c9ca44-96d9-4a2e-990d-754c9016811c.png`.
- [03 · 표정이 살아있는 만화](03-expressive-cartoon-original-eyes.png): source `/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-440227f5-9652-40c8-8390-584a2038f21d.png`.

All three rendered outputs were visually inspected. Open eyes are smaller with reduced white areas and curved upper lids closer to the original; four-panel poses and headers remain. Closed-eye panels retain their blink/smile expressions. These are generated redraws, not pixel-identical replicas of the original eyes.

## Exact prompts

### 01 · 잔잔한 손그림

Edit target: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cartoon-motion-concepts/01-quiet-handdrawn.png`

Reference order: edit target, original sprite sheet, original approved study-room concept.

```text
Use case: identity-preserve.
Asset type: static four-panel 2D red-panda motion concept board, eye-identity correction.
Input images: Image 1 is the EDIT TARGET board. Image 2 is the CANONICAL ORIGINAL CHARACTER sprite sheet. Image 3 is the original approved character and room concept, supporting the canonical identity. Use images 2 and 3 ONLY as the eye identity reference, do not copy their layout or scene.
Primary request: Correct ONLY the eyes, eyelids and immediate surrounding eye area of every red panda in image 1 to faithfully match the ORIGINAL red panda from images 2 and 3. The target currently has incorrect oversized round doll eyes with huge white sockets. Restore the original character's much smaller warm dark-brown oval eyes, narrow ivory white crescent at the upper/outer edge, dark curved upper eyelid, and tiny restrained white glints. Match the eye-to-face proportions, eye spacing and facial placement of the original, accounting for each head tilt. Each open eye should be approximately 14–16 percent of the cheek-to-cheek face width. The white must be a thin sliver, not a large round white eyeball around a circular iris. The compact eyes sit naturally within the cream facial markings and retain the friendly original expression.
Keep each panel's gaze and emotion appropriate to its pose: Panel 1 calm writing, panel 2 leaning forward writing, panel 3 gentle closed-eye blink, panel 4 turning page. Closed-eye panels must stay closed using small subtle eyelid arcs matching the restored original eye size and position.
Invariants: Preserve the exact four-panel layout, camera crop, Korean header "01 · 잔잔한 손그림", panel numbers, all head silhouettes, head tilts, poses, hands, pencil, notebook, desk, tail, ears, orange fur, cream facial markings outside the locally corrected eye area, cheek blush, forehead marks, dark green apron, paper texture, line style, and warm ivory background. Do not redesign the character or add/remove elements. Make only this targeted eye identity correction. This is a still illustration, not animation. Landscape 1536x1024.
```

### 02 · 말랑한 만화

Edit target: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cartoon-motion-concepts/02-soft-cartoon.png`

Reference order: edit target, original sprite sheet, original approved study-room concept.

```text
Use case: identity-preserve.
Asset type: static four-panel 2D red-panda motion concept board, eye-identity correction.
Input images: Image 1 is the EDIT TARGET board. Image 2 is the CANONICAL ORIGINAL CHARACTER sprite sheet. Image 3 is the original approved character and room concept, supporting the canonical identity. Use images 2 and 3 ONLY as the eye identity reference, do not copy their layout or scene.
Primary request: Correct ONLY the eyes, eyelids and immediate surrounding eye area of every red panda in image 1 to faithfully match the ORIGINAL red panda from images 2 and 3. The target currently has incorrect oversized round doll eyes with huge white sockets. Restore the original character's much smaller warm dark-brown oval eyes, narrow ivory white crescent at the upper/outer edge, dark curved upper eyelid, and tiny restrained white glints. Match the eye-to-face proportions, eye spacing and facial placement of the original, accounting for each head tilt. Each open eye should be approximately 14–16 percent of the cheek-to-cheek face width. The white must be a thin sliver, not a large round white eyeball around a circular iris. The compact eyes sit naturally within the cream facial markings and retain the friendly original expression.
Keep each panel's gaze and emotion appropriate to its pose: Panel 1 pencil poised with anticipation, panel 2 leaning forward writing, panel 3 happy closed-eye smile, panel 4 turning page. Closed-eye panels must stay closed using small subtle eyelid arcs matching the restored original eye size and position.
Invariants: Preserve the exact four-panel layout, camera crop, Korean header "02 · 말랑한 만화", panel numbers, all head silhouettes, head tilts, poses, hands, pencil, notebook, desk, tail, ears, orange fur, cream facial markings outside the locally corrected eye area, cheek blush, forehead marks, dark green apron, paper texture, line style, and warm ivory background. Do not redesign the character or add/remove elements. Make only this targeted eye identity correction. This is a still illustration, not animation. Landscape 1536x1024.
```

### 03 · 표정이 살아있는 만화

Edit target: `/Users/jaewook/dev_app/focus_friend_app/docs/design/cartoon-motion-concepts/03-expressive-cartoon.png`

Reference order: edit target, original sprite sheet, original approved study-room concept.

```text
Use case: identity-preserve.
Asset type: static four-panel 2D red-panda motion concept board, eye-identity correction.
Input images: Image 1 is the EDIT TARGET board. Image 2 is the CANONICAL ORIGINAL CHARACTER sprite sheet. Image 3 is the original approved character and room concept, supporting the canonical identity. Use images 2 and 3 ONLY as the eye identity reference, do not copy their layout or scene.
Primary request: Correct ONLY the eyes, eyelids and immediate surrounding eye area of every red panda in image 1 to faithfully match the ORIGINAL red panda from images 2 and 3. The target currently has incorrect oversized round doll eyes with huge white sockets. Restore the original character's much smaller warm dark-brown oval eyes, narrow ivory white crescent at the upper/outer edge, dark curved upper eyelid, and tiny restrained white glints. Match the eye-to-face proportions, eye spacing and facial placement of the original, accounting for each head tilt. Each open eye should be approximately 14–16 percent of the cheek-to-cheek face width. The white must be a thin sliver, not a large round white eyeball around a circular iris. The compact eyes sit naturally within the cream facial markings and retain the friendly original expression.
Keep each panel's gaze and emotion appropriate to its pose: Panel 1 thoughtful glance with cheek resting on paw, panel 2 idea smile, panel 3 downcast writing gaze, panel 4 happy closed-eye page turn. Closed-eye panels must stay closed using small subtle eyelid arcs matching the restored original eye size and position.
Invariants: Preserve the exact four-panel layout, camera crop, Korean header "03 · 표정이 살아있는 만화", panel numbers, all head silhouettes, head tilts, poses, hands, pencil, notebook, desk, tail, ears, orange fur, cream facial markings outside the locally corrected eye area, cheek blush, forehead marks, dark green apron, paper texture, line style, and warm ivory background. Do not redesign the character or add/remove elements. Make only this targeted eye identity correction. This is a still illustration, not animation. Landscape 1536x1024.
```

