#!/usr/bin/env python3
"""Capture an isolated Android tea-break preview without touching user records."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = '/Users/jaewook/development/flutter/bin/flutter'
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
AAPT = '/Users/jaewook/Library/Android/sdk/build-tools/36.1.0/aapt'
PACKAGE = 'dev.jaewook.deskmate.verification'
OUT = ROOT / 'docs/design/rest-tea-14-frames'
OUT.mkdir(parents=True, exist_ok=True)
CACHE = 'code_cache/rest-tea-preview'
BUILD = Path(tempfile.mkdtemp(prefix='focus-tea-verification-'))
for name in ('lib', 'assets', 'android', 'integration_test'):
    shutil.copytree(ROOT / name, BUILD / name,
                    ignore=shutil.ignore_patterns('build', '.gradle', '.cxx'))
for name in ('pubspec.yaml', 'pubspec.lock', '.metadata', 'analysis_options.yaml'):
    shutil.copy2(ROOT / name, BUILD / name)
(OUT / 'verification-workspace.txt').write_text(str(BUILD))
print(f'Private build: {BUILD}', flush=True)

def adb(*args, **kwargs):
    return subprocess.run([ADB, '-s', 'emulator-5554', *args], **kwargs)

# Flutter can uninstall the preceding APK when running integration tests.
# Verify that APK belongs to the disposable verification package first.
subprocess.run([FLUTTER, 'build', 'apk', '--debug',
                '--dart-define=FOCUS_FRIEND_VERIFICATION=true'], cwd=BUILD, check=True)
apk = BUILD / 'build/app/outputs/flutter-apk/app-debug.apk'
metadata = subprocess.check_output([AAPT, 'dump', 'badging', str(apk)], text=True)
assert f"package: name='{PACKAGE}'" in metadata, 'Wrong APK package'
adb('shell', 'run-as', PACKAGE, 'rm', '-rf', CACHE, capture_output=True)
record_path = f'/sdcard/rest-tea-{int(time.time())}.mp4'
recorder = None
exported = False
with (OUT / 'native-integration.log').open('w') as log:
    process = subprocess.Popen([FLUTTER, 'test', 'integration_test/rest_tea_test.dart',
        '-d', 'emulator-5554', '--disable-dds',
        '--dart-define=FOCUS_FRIEND_VERIFICATION=true',
        '--dart-define=TEA_EXPORT_SECONDS=15'], cwd=BUILD, stdout=log, stderr=subprocess.STDOUT)
    while process.poll() is None:
        if recorder is None and adb('shell', 'run-as', PACKAGE, 'test', '-f',
                                    f'{CACHE}/motion-ready', capture_output=True).returncode == 0:
            recorder = subprocess.Popen([ADB, '-s', 'emulator-5554', 'shell',
                'screenrecord', '--size', '540x960', '--bit-rate', '2000000',
                '--time-limit', '12', record_path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            print('Recording native tea animation', flush=True)
        if not exported and adb('shell', 'run-as', PACKAGE, 'test', '-f',
                                 f'{CACHE}/verified', capture_output=True).returncode == 0:
            archive = OUT / 'native-captures.tar'
            with archive.open('wb') as target:
                adb('exec-out', 'run-as', PACKAGE, 'tar', '-C', CACHE, '-cf', '-', '.',
                    stdout=target, check=True)
            subprocess.run(['tar', '-xf', str(archive), '-C', str(OUT)], check=True)
            archive.unlink()
            exported = True
            print('Exported native screenshots', flush=True)
        time.sleep(.5)
if recorder is not None:
    _, error = recorder.communicate(timeout=20)
    if recorder.returncode != 0:
        raise RuntimeError(error.decode())
    adb('pull', record_path, str(OUT / 'native-tea-animation.mp4'), check=True)
    adb('shell', 'rm', record_path, check=True)
print((OUT / 'native-integration.log').read_text())
if process.returncode != 0 or not exported or recorder is None:
    raise SystemExit(process.returncode or 'Missing native motion evidence')
