# Deskmate store screenshots · English

2026-10-16 · 6 images · 1080×1920px · RGB PNG/JPEG

Upload 01 through 06 in order. PNG and JPEG versions have the same design; choose one format. The ZIP contains the six uploadable PNGs, overview and supporting notes.

- overview.png: 3×2 preview
- strip.png: six-image horizontal preview
- sources/: new captures of the actual English app widgets
- alt-text.tsv: English alt text for each image
- manifest.json: sources, dimensions and hashes

## Sequence

- 01_together: Focus feels better with a friend.
- 02_friends: Find your favorite friend.
- 03_day_and_night: A cozy space, day and night.
- 04_focus_sounds: Settle in with soothing sounds.
- 05_small_habits: Small moments. Steady progress.
- 06_little_rewards: A little focus. A little reward.

## Production

Marketing copy and app controls are in English. Original illustration artwork is preserved. The current morning app icon is used. Records and unlocked items use isolated in-memory demonstration data, through October 16, 2026. No installed app database is read or changed.

Capture: flutter test --no-pub tool/capture_store_screenshots_test.dart --dart-define=STORE_SCREENSHOT_LOCALE=en --dart-define=STORE_SCREENSHOT_DATE=2026-10-16 --reporter expanded

Compose: node tool/create_store_screenshots.cjs en (set NODE_PATH to the bundled @napi-rs/canvas and sharp packages).

Font: assets/fonts/PretendardVariable.ttf; OFL license: assets/fonts/OFL.txt.
