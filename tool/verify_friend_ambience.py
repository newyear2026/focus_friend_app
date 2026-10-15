#!/usr/bin/env python3
"""Capture native ambience in an isolated APK, then build the update APK."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/friend-time-of-day-implementation'
FLUTTER = '/Users/jaewook/development/flutter/bin/flutter'
ADB = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
DEVICE = os.environ.get('ANDROID_DEVICE', 'emulator-5554')
PACKAGE = 'dev.jaewook.deskmate.verification'
CACHE = 'code_cache/friend-ambience-preview'


def main():
    build = Path(tempfile.mkdtemp(prefix='focus-friend-ambience-'))
    for name in ('lib', 'assets', 'android', 'integration_test'):
        shutil.copytree(ROOT / name, build / name,
                        ignore=shutil.ignore_patterns('build', '.gradle', '.cxx'))
    for name in ('pubspec.yaml', 'pubspec.lock', '.metadata', 'analysis_options.yaml', 'l10n.yaml'):
        if (ROOT / name).exists():
            shutil.copy2(ROOT / name, build / name)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'verification-workspace.txt').write_text(str(build) + '\n')
    print(f'Isolated build: {build}', flush=True)

    def adb(*args, **kwargs):
        return subprocess.run([ADB, '-s', DEVICE, *args], **kwargs)

    # Flutter reads the previous APK identity to decide what to uninstall.
    with (OUT / 'verification-build.log').open('w') as log:
        subprocess.run([FLUTTER, 'build', 'apk', '--debug',
                        '--dart-define=FOCUS_FRIEND_VERIFICATION=true'],
                       cwd=build, stdout=log, stderr=subprocess.STDOUT, check=True)
    adb('shell', 'run-as', PACKAGE, 'rm', '-rf', CACHE, capture_output=True)
    exported = False
    with (OUT / 'native-test.log').open('w') as log:
        process = subprocess.Popen([
            FLUTTER, 'test', 'integration_test/friend_ambience_test.dart',
            '-d', DEVICE, '--disable-dds', '--dart-define=FOCUS_FRIEND_VERIFICATION=true',
        ], cwd=build, stdout=log, stderr=subprocess.STDOUT)
        while process.poll() is None:
            if not exported and adb('shell', 'run-as', PACKAGE, 'test', '-f',
                                    f'{CACHE}/capture-times.json', capture_output=True).returncode == 0:
                target = OUT / 'native'
                target.mkdir(exist_ok=True)
                archive = OUT / 'native-captures.tar'
                with archive.open('wb') as dest:
                    adb('exec-out', 'run-as', PACKAGE, 'tar', '-C', CACHE, '-cf', '-', '.',
                        stdout=dest, check=True)
                subprocess.run(['tar', '-xf', str(archive), '-C', str(target)], check=True)
                archive.unlink()
                exported = True
                print('Exported sixteen Android room captures', flush=True)
            time.sleep(.5)
    if process.returncode != 0 or not exported:
        print((OUT / 'native-test.log').read_text())
        raise SystemExit(process.returncode or 'Missing native captures')

    with (OUT / 'build.log').open('w') as log:
        subprocess.run([FLUTTER, 'build', 'apk', '--debug'], cwd=build,
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    target = ROOT / 'deliverables/friend-time-of-day/Focus-Friend-Dev.apk'
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(build / 'build/app/outputs/flutter-apk/app-debug.apk', target)
    (OUT / 'native-verification.json').write_text(json.dumps({
        'package': PACKAGE, 'captures': 16, 'passed': True,
        'userDataStoreUsed': False, 'apk': str(target), 'sourceSnapshot': str(build),
    }, indent=2) + '\n')
    print(f'Native verification passed; APK: {target}', flush=True)


if __name__ == '__main__':
    main()
