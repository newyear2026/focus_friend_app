#!/usr/bin/env python3
"""Verify/capture the cel animation in an isolated APK, preserving the dev app."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = '/Users/jaewook/development/flutter/bin/flutter'
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
PACKAGE = 'dev.jaewook.deskmate.verification'
DEVICE = os.environ.get('FOCUS_MOTION_DEVICE', 'emulator-5554')
OUT = ROOT / os.environ.get('FOCUS_MOTION_EVIDENCE_DIR', 'docs/design/app-cel-motion')
CACHE = 'code_cache/study-cel-preview'
OUT.mkdir(parents=True, exist_ok=True)

# Other chats may build the same checkout. A private source snapshot prevents an
# APK from another build replacing the integration-test entry point mid-install.
BUILD_ROOT = Path(tempfile.mkdtemp(prefix='focus-cel-verification-'))
for name in ('lib', 'assets', 'android', 'integration_test'):
    shutil.copytree(ROOT / name, BUILD_ROOT / name,
                    ignore=shutil.ignore_patterns('build', '.gradle', '.cxx'))
for name in ('pubspec.yaml', 'pubspec.lock', '.metadata', 'analysis_options.yaml'):
    if (ROOT / name).exists():
        shutil.copy2(ROOT / name, BUILD_ROOT / name)
(OUT / 'verification-workspace.txt').write_text(str(BUILD_ROOT))
print(f'Isolated build workspace: {BUILD_ROOT}', flush=True)

def adb(*args, **kwargs):
    return subprocess.run([ADB, '-s', DEVICE, *args], **kwargs)

# Flutter reads the previous APK's package before starting integration tests.
# Build the isolated package first so teardown cannot uninstall the dev app.
subprocess.run([FLUTTER, 'build', 'apk', '--debug',
                '--dart-define=FOCUS_FRIEND_VERIFICATION=true'], cwd=BUILD_ROOT, check=True)
adb('shell', 'run-as', PACKAGE, 'rm', '-rf', CACHE, capture_output=True)
record_path = f'/sdcard/focus-cel-verification-{int(time.time())}.mp4'
recorder = None
exported = False
with (OUT / 'integration.log').open('w') as log:
    process = subprocess.Popen([
        FLUTTER, 'test', 'integration_test/study_scene_test.dart', '-d', DEVICE,
        '--disable-dds',
        '--dart-define=FOCUS_FRIEND_VERIFICATION=true', '--dart-define=SCENE_EXPORT_SECONDS=20',
    ], cwd=BUILD_ROOT, stdout=log, stderr=subprocess.STDOUT)
    while process.poll() is None:
        if recorder is None and adb('shell', 'run-as', PACKAGE, 'test', '-f',
                                    f'{CACHE}/motion-ready', capture_output=True).returncode == 0:
            recorder = subprocess.Popen([ADB, '-s', DEVICE, 'shell',
                'screenrecord', '--size', '540x960', '--bit-rate', '1500000',
                '--time-limit', '28', record_path],
                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            print('Recording the running Android animation', flush=True)
        if not exported and adb('shell', 'run-as', PACKAGE, 'test', '-f',
                                 f'{CACHE}/capture-times.json', capture_output=True).returncode == 0:
            archive = OUT / 'captures.tar'
            with archive.open('wb') as destination:
                adb('exec-out', 'run-as', PACKAGE, 'tar', '-C', CACHE, '-cf', '-', '.',
                    stdout=destination, check=True)
            subprocess.run(['tar', '-xf', str(archive), '-C', str(OUT)], check=True)
            archive.unlink()
            exported = True
            print('Exported all native screenshots', flush=True)
        time.sleep(.5)

if recorder is not None:
    _, error = recorder.communicate(timeout=20)
    if recorder.returncode != 0:
        raise RuntimeError(error.decode())
    adb('pull', record_path, str(OUT / 'native-animation.mp4'), check=True)
    adb('shell', 'rm', record_path, check=True)
print((OUT / 'integration.log').read_text())
if process.returncode != 0 or not exported or recorder is None:
    raise SystemExit(process.returncode or 'Missing native motion evidence')
