#!/usr/bin/env python3
"""Capture native test ads; optionally use the configured unit on an emulator."""
from pathlib import Path
import os
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
DEVICE = os.environ.get('FOCUS_EXIT_DEVICE', 'emulator-5580')
PACKAGE = 'dev.jaewook.deskmate.verification'
CACHE = 'code_cache/app-exit-preview'
OUT = Path(os.environ.get('FOCUS_EXIT_OUTPUT_DIR', str(ROOT / 'docs/design/app-exit-implementation-v1')))
OUT.mkdir(parents=True, exist_ok=True)
configured_unit = os.environ.get('FOCUS_EXIT_USE_CONFIGURED_UNIT') == '1'
dart_args = ['--dart-define=FOCUS_FRIEND_VERIFICATION=true']
if configured_unit:
    if not DEVICE.startswith('emulator-'):
        raise SystemExit('Configured ad units may only be checked on an Android emulator (automatic test device).')
    dart_args += ['--dart-define-from-file=admob.json',
                  '--dart-define=FOCUS_EXIT_USE_CONFIGURED_UNIT=true']

def adb(*args, **kwargs):
    return subprocess.run([ADB, '-s', DEVICE, *args], **kwargs)

# This APK is separately named; never install/uninstall or clear the user's app.
# Regenerate plugin registration: a previous release build omits test plugins.
subprocess.run(['flutter', 'build', 'apk', '--debug',
                *dart_args], cwd=ROOT, check=True)
adb('shell', 'run-as', PACKAGE, 'rm', '-rf', CACHE, capture_output=True)
size = adb('shell', 'wm', 'size', capture_output=True, text=True).stdout
density = adb('shell', 'wm', 'density', capture_output=True, text=True).stdout
old_size = size.split('Override size: ')[-1].strip() if 'Override size:' in size else 'reset'
old_density = density.split('Override density: ')[-1].strip() if 'Override density:' in density else 'reset'
old_immersive = adb('shell', 'settings', 'get', 'secure', 'immersive_mode_confirmations', capture_output=True, text=True).stdout.strip()
captured = set()
try:
    adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP', check=True)
    adb('shell', 'wm', 'dismiss-keyguard', check=True)
    # The OS first-run immersive tutorial steals focus and prevents preloading.
    adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', 'confirmed', check=True)
    adb('shell', 'wm', 'size', '1080x2400', check=True)
    adb('shell', 'wm', 'density', '400', check=True)
    with (OUT / 'integration.log').open('w') as log:
        process = subprocess.Popen(['flutter', 'test', 'integration_test/app_exit_test.dart',
            '-d', DEVICE, '--no-pub', '--disable-dds',
            *dart_args], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 480
        while process.poll() is None and time.monotonic() < deadline:
            stage = adb('shell', 'run-as', PACKAGE, 'cat', f'{CACHE}/stage', capture_output=True, text=True).stdout.strip()
            if stage in {'medium', 'small', 'removed-open', 'no-ad'} and stage not in captured:
                time.sleep(.6)
                with (OUT / f'{stage}.png').open('wb') as image:
                    adb('exec-out', 'screencap', '-p', stdout=image, check=True)
                if stage == 'medium':
                    adb('shell', 'wm', 'size', '977x1610', check=True)
                adb('shell', 'run-as', PACKAGE, 'touch', f'{CACHE}/{stage}.captured', check=True)
                captured.add(stage)
                print(f'Captured {stage}', flush=True)
            time.sleep(.4)
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=20)
finally:
    adb('shell', 'wm', 'size', old_size)
    adb('shell', 'wm', 'density', old_density)
    if old_immersive in {'', 'null'}:
        adb('shell', 'settings', 'delete', 'secure', 'immersive_mode_confirmations')
    else:
        adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', old_immersive)
print((OUT / 'integration.log').read_text())
if process.returncode != 0 or captured != {'medium', 'small', 'removed-open', 'no-ad'}:
    raise SystemExit(process.returncode or 'Missing native captures')
