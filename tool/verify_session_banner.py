#!/usr/bin/env python3
"""Capture native Google test banners in an isolated emulator APK."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = '/Users/jaewook/development/flutter/bin/flutter'
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
DEVICE = os.environ.get('FOCUS_BANNER_DEVICE', 'emulator-5554')
PACKAGE = 'dev.jaewook.deskmate.verification'
CACHE = 'code_cache/session-banner-preview'
OUT = ROOT / 'docs/design/session-banner-implementation-v1'
OUT.mkdir(parents=True, exist_ok=True)
BUILD_ROOT = Path(tempfile.mkdtemp(prefix='focus-banner-verification-'))
for name in ('lib', 'assets', 'android', 'integration_test'):
    shutil.copytree(ROOT / name, BUILD_ROOT / name,
                    ignore=shutil.ignore_patterns('build', '.gradle', '.cxx'))
for name in ('pubspec.yaml', 'pubspec.lock', '.metadata', 'analysis_options.yaml', 'l10n.yaml'):
    if (ROOT / name).exists():
        shutil.copy2(ROOT / name, BUILD_ROOT / name)

def adb(*args, **kwargs):
    return subprocess.run([ADB, '-s', DEVICE, *args], **kwargs)

print(f'Isolated build workspace: {BUILD_ROOT}', flush=True)
# Prebuild only the verification package so Flutter teardown cannot remove the
# user's normal installed app. No admob.json: all ads are Google test ads.
subprocess.run([FLUTTER, 'build', 'apk', '--debug',
                '--dart-define=FOCUS_FRIEND_VERIFICATION=true'], cwd=BUILD_ROOT, check=True)
adb('shell', 'run-as', PACKAGE, 'rm', '-rf', CACHE, capture_output=True)
captured = set()
with (OUT / 'integration.log').open('w') as log:
    process = subprocess.Popen([
        FLUTTER, 'test', 'integration_test/session_banner_test.dart',
        '-d', DEVICE, '--disable-dds',
        '--dart-define=FOCUS_FRIEND_VERIFICATION=true',
    ], cwd=BUILD_ROOT, stdout=log, stderr=subprocess.STDOUT)
    while process.poll() is None:
        stage = adb('shell', 'run-as', PACKAGE, 'cat', f'{CACHE}/stage',
                    capture_output=True, text=True).stdout.strip()
        if stage in {'focus', 'rest', 'removed'} and stage not in captured:
            time.sleep(.6)
            with (OUT / f'{stage}.png').open('wb') as image:
                adb('exec-out', 'screencap', '-p', stdout=image, check=True)
            adb('shell', 'run-as', PACKAGE, 'touch', f'{CACHE}/{stage}.captured', check=True)
            captured.add(stage)
            print(f'Captured native {stage} screen', flush=True)
        time.sleep(.3)
print((OUT / 'integration.log').read_text())
if process.returncode != 0 or captured != {'focus', 'rest', 'removed'}:
    raise SystemExit(process.returncode or 'Missing banner captures')
