# Tea break — continuous motion refinement

The user liked the existing tea break and asked for slightly more natural motion. The room, rest flow, face, feet and tail remain in place. The ten-second cycle is preserved.

## Final implementation

- Cup and both gripping paws are one rigid sprite. They lift and lower together on an eased path; the cup tilts about 11 degrees during the sip. Two-joint arm positioning keeps the sleeves attached to the hands.
- Original face/ears, feet and tail stay anchored. Original open/half-closed/closed eye artwork supplies brief blinks and sleepy eyes while drinking. The torso has a small breathing movement (less than one original sprite pixel).
- The animation now samples continuous transforms at up to 60 Hz. This does not mean 60 newly drawn images per second. The original twelve-cel sheet remains a source for stationary artwork and eye expressions; the cup/arms/body use the new separated parts.
- Pause, background, hidden ticker and reduced-motion behavior preserve the established timer rules. The rest timer and persisted focus records are independent of decorative motion.

## Assets and provenance

- [Separate torso, mug/paws and sleeve parts](../../../assets/images/rest/redpanda-tea-parts.png): original 1254×1254 RGBA output from the built-in image_gen tool, copied without pixel editing. Runtime cropping selects four measured parts.
- [Exact prompt](smooth-parts-prompt.md), generated from the existing twelve-pose tea atlas. The original face, feet and tail were not regenerated.
- The new parts have minor shading/outline differences at the small body and cup. This is P3 visual polish, not a change of character identity or layout.

## Visual findings and resolution

- An intermediate mesh/dissolve attempt showed ghosted cup emblems and face features. It was discarded. The final implementation draws rigid cutouts, with no texture dissolves or whole-character deformation.
- The first cutout render retained a small white edge from the old cup near the lap. The lower-body mask was corrected to retain only the feet and pants below the cup. The final `smooth-detail.png` confirms a clean green torso when the mug rises.
- `before-after-motion.mp4`: old cel playback on the left, final continuous movement on the right, rendered from actual Flutter widgets. `before-after-contact.jpg` samples that encoded comparison.
- `rest-tea-smooth-preview.mp4`: 300 real-widget frames at 30 fps over the full ten-second cycle. `smooth-detail.png` inspects cup, arm joins, torso and facial expressions.
- `native-tea-animation.mp4` and `smooth-native-contact-sheet.jpg`: final Android recording and sampled frames. `native-pose-5.png` confirms the complete native rest screen. Layout, timer and button remain consistent with the previous version.
- Native and host paused captures remain pixel-identical across two seconds. No unresolved P0/P1/P2 after final visual inspection.

## Verification

- `flutter analyze`: no issues.
- All 45 unit/widget tests passed. New checks cover an eased continuous cup path, loop continuity, fixed face outline/feet/tail pixels, opacity, intermediate visible positions, pause/resume, background/hidden tickers and reduced motion.
- Real-widget full rest-flow capture passed.
- Isolated Android `rest_tea_test.dart` passed: rest start → movement → pause → resume → completion → normal desk. No added focus records from resting. `native-integration.log` records the result.
- The original version's video and QA are archived in `before-smoothing/`.

Android update succeeded using an explicitly checked normal-package APK and `adb install --no-streaming -r`. `smooth-data-preservation.json` confirms identical persisted JSON / SHA-256 before and after: revision 53, eleven history entries, active state, preferences and unlocks preserved. `smooth-updated-app.png` is the post-update normal app capture.
