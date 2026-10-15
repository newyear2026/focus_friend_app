# Cushion tea-break implementation QA

Latest implementation: [continuous motion refinement](smooth-design-qa.md). The twelve-cel playback notes below describe the initial version; final motion uses rigid cutouts with eased continuous transforms.

## Selected source and scope

`reference.png` is the user's selected 887×1774 rest screen. The implemented scene uses the repository's current storybook room artwork and existing responsive Flutter layout. This change adds a separate seated red panda, a closed notebook on the empty desk, and the tea-drinking loop. Existing focus animation, navigation, records and rest duration remain intact.

## Visual verification

- `reference-comparison.jpg` combines the selected reference with `pose-5.png`, captured from real Flutter widgets at 393×786 logical pixels / 2× density. `seating-comparison.jpg` compares the cushion, feet, hands and cup at detail scale.
- The room remains the main element; the empty chair and closed green notebook establish the break state. The panda's feet meet the front-right cushion. Its striped tail, two hands, green overalls and leaf mug are fully visible.
- Existing Pretendard, cream background, navy button/timer and blue supporting copy are retained. Native text and controls remain accessible rather than being baked into an image.
- The full rest copy matches the selected design. `04:56` in the implementation is the actual test timer value, rather than the mock's `04:32`.
- `rest-tea-preview.mp4` is a ten-second real-widget render, encoded from 120 frames. `motion-contact-sheet.png` samples that encoded video every half second. Eyes close, the cup rises to the mouth, tilts for a sip, then lowers. No room movement or crossfade transparency is applied.
- `paused-a.png` and `paused-b.png` are pixel-identical across two seconds. The timer and cel position both freeze.
- Deliberate integration difference: room surfaces use the recently added flatter storybook style. Its cushion is slightly smaller and farther right than the older reference, so the new character is anchored to the current seat. Existing safe areas and active-session layout remain unchanged.
- P3 polish: cel artwork has minor contour changes between poses; this is a hand-drawn frame animation, not a skeletal rig. No walking-to-cushion transition is included in this scope.

No unresolved P0/P1/P2 found in the source-to-implementation full-view and detail comparisons.

## Behavior and accessibility

- Existing flow: complete focus → choose `5분 휴식 시작` → five-minute tea break → `휴식 완료` → `확인` returns to the desk.
- Motion uses a ten-second timeline independent from persisted session time. Pause/resume preserves animation position. Background/hidden tickers stop rendering; accessibility reduced motion shows the still resting pose.
- Rest completion stops animation and does not add a focus completion or award extra study time.
- The cushion stays in the room layer; the reusable tea sprite contains only character and mug. Other cushion heights/shapes will need a new seat anchor and, where the pose differs, a compatible animation.
- Rest scene has a spoken description; decorative layers are excluded from duplicate accessibility announcements.

## Checks

- `flutter analyze`: no issues.
- `flutter test test --reporter expanded`: all 43 tests passed, including existing focus/time/records/navigation tests and the new tea timing / pause / background / hidden ticker / reduced-motion checks.
- Real-widget capture and complete rest-flow checks: `tool/capture_tea_rest_test.dart` and `tool/capture_rest_preview_test.dart` passed.
- Asset prompts and originals: `asset-prompts.md`, `closed-book-prompt.md`. Original transparent PNGs are preserved; slicing and positioning happen in Flutter.
- Native Android: `integration_test/rest_tea_test.dart` passed in a separate `.verification` package backed by an in-memory fixture. `native-integration.log` records the successful test. The normal app's database was never used for this flow.
- `native-tea-animation.mp4` is the 12-second Android screen recording. `native-motion-contact-sheet.jpg` samples the actual video. `native-pose-{0,2,5,8}.png`, `native-completed.png` and `native-returned-home.png` confirm the state transitions and layer placement on device. `native-paused-a.png` and `native-paused-b.png` are pixel-identical.
- Built the normal application explicitly from `lib/main.dart` in a private source snapshot; asserted its APK package identifier before `adb install --no-streaming -r`. `updated-app-native.png` captures the updated normal app.
- `data-preservation.json`: complete persisted JSON snapshot and SHA-256 match before/after installation. Revision 45, ten history entries, active state and all settings/unlocks were preserved. No user data reset, uninstall or new test focus record in the normal app.

Final result: passed. No unresolved P0/P1/P2 in this rest-animation scope.
