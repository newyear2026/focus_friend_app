#!/usr/bin/env python3
"""Isolated UI/native feature verification; never touches the development app's data."""
from pathlib import Path
import subprocess, time
root = Path(__file__).resolve().parents[1]
flutter = '/Users/jaewook/development/flutter/bin/flutter'
adb = '/Users/jaewook/Library/Android/sdk/platform-tools/adb'
package = 'dev.jaewook.deskmate.verification'
out = root / 'docs/design/features'
out.mkdir(parents=True, exist_ok=True)
subprocess.run([flutter,'build','apk','--debug','--dart-define=FOCUS_FRIEND_VERIFICATION=true'],cwd=root,check=True)
subprocess.run([adb,'shell','run-as',package,'rm','-rf','code_cache/feature-preview'],capture_output=True)
with (out/'integration.log').open('w') as log:
 p = subprocess.Popen([flutter,'test','integration_test/features_test.dart','-d','emulator-5554','--dart-define=FOCUS_FRIEND_VERIFICATION=true'],cwd=root,stdout=log,stderr=subprocess.STDOUT)
 exported=False
 ui_exported=False
 background=False
 while p.poll() is None:
  if not background and subprocess.run([adb,'shell','run-as',package,'test','-f','code_cache/feature-preview/background-ready'],capture_output=True).returncode==0:
   subprocess.run([adb,'shell','input','keyevent','3'],capture_output=True)
   time.sleep(3)
   (out/'background-service.txt').write_text(subprocess.run([adb,'shell','dumpsys','activity','services',package],capture_output=True,text=True).stdout)
   background=True
  if not ui_exported and subprocess.run([adb,'shell','run-as',package,'test','-f','code_cache/feature-preview/ui-complete'],capture_output=True).returncode==0:
   for name in ['home','records','settings','goal','sound']:
    with (out/(name+'.png')).open('wb') as dest:
     subprocess.run([adb,'exec-out','run-as',package,'cat','code_cache/feature-preview/'+name+'.png'],stdout=dest,check=True)
   ui_exported=True
  if not exported and subprocess.run([adb,'shell','run-as',package,'test','-f','code_cache/feature-preview/complete'],capture_output=True).returncode==0:
   tar=out/'captures.tar'
   with tar.open('wb') as dest:
    subprocess.run([adb,'exec-out','run-as',package,'tar','-C','code_cache/feature-preview','-cf','-','.'],stdout=dest,check=True)
   subprocess.run(['tar','-xf',str(tar),'-C',str(out)],check=True)
   tar.unlink()
   exported=True
   print('Exported feature screenshots and test results',flush=True)
  time.sleep(1)
print((out/'integration.log').read_text())
if p.returncode or not exported or not background:
 raise SystemExit(p.returncode or 'Missing verification evidence')
