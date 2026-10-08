#!/usr/bin/env python3
"""Run isolated Android scene verification and export images before test teardown."""
from pathlib import Path
import os, subprocess, time, sys

root = Path(__file__).resolve().parents[1]
flutter = os.environ.get('FLUTTER_BIN', '/Users/jaewook/development/flutter/bin/flutter')
adb = os.environ.get('ADB_BIN', '/Users/jaewook/Library/Android/sdk/platform-tools/adb')
device = os.environ.get('ANDROID_DEVICE', 'emulator-5554')
package = 'dev.jaewook.prototype.focus_friend_app.verification'
# Flutter resolves the teardown package from the PREVIOUSLY built APK.
# Build the isolated identity first, before starting flutter test.
subprocess.run([flutter, 'build', 'apk', '--debug',
    '--dart-define=FOCUS_FRIEND_VERIFICATION=true'], cwd=root, check=True)
if '--persistence' in sys.argv:
    raise SystemExit(subprocess.call([flutter, 'test', 'integration_test/persistence_test.dart',
        '-d', device, '--dart-define=FOCUS_FRIEND_VERIFICATION=true'], cwd=root))

output = root / os.environ.get('SCENE_OUTPUT_DIR', 'docs/design/redpanda-study')
output.mkdir(parents=True, exist_ok=True)
# Remove only stale screenshots from this dedicated verification package.
subprocess.run([adb, '-s', device, 'shell', 'run-as', package, 'rm', '-rf',
    'code_cache/study-scene-preview'], capture_output=True)
log_path = output / 'integration.log'
with log_path.open('w') as log:
    process = subprocess.Popen([flutter, 'test', 'integration_test/study_scene_test.dart',
        '-d', device, '--dart-define=FOCUS_FRIEND_VERIFICATION=true',
        '--dart-define=SCENE_EXPORT_SECONDS=20'], cwd=root, stdout=log, stderr=subprocess.STDOUT)
    exported = False
    while process.poll() is None:
        if not exported:
            ready = subprocess.run([adb, '-s', device, 'shell', 'run-as', package,
                'test', '-f', 'code_cache/study-scene-preview/capture-times.json'], capture_output=True)
            if ready.returncode == 0:
                archive = output / 'captures.tar'
                with archive.open('wb') as dest:
                    subprocess.run([adb, '-s', device, 'exec-out', 'run-as', package,
                        'tar', '-C', 'code_cache/study-scene-preview', '-cf', '-', '.'],
                        stdout=dest, check=True)
                subprocess.run(['tar','-xf',str(archive),'-C',str(output)],check=True)
                archive.unlink()
                exported = True
                print(f'Exported screenshots: {output}', flush=True)
        time.sleep(2)
    result = process.returncode
print(log_path.read_text())
if result != 0 or not exported:
    raise SystemExit(result or 'No screenshots exported')
