# 일반 앱 적용 확인

2026-11-06. 사용자의 ‘수정된 모션으로 적용’ 요청에 따라 에뮬레이터의 일반 앱을 업데이트했습니다.

- 대상: `emulator-5554`, `dev.jaewook.deskmate`.
- `flutter build apk --debug --no-pub` 성공. APK 패키지 이름을 `aapt dump badging`으로 확인했습니다. 버전 0.1.0 / 코드 6.
- `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk`: `Success`.
- 설치된 패키지의 `lastUpdateTime`: 2026-11-06 18:12:54 (기기 시각).
- 일반 앱 실행 결과: `Status: ok`, `LaunchState: COLD`. 앱 프로세스의 치명적 예외·미처리 Flutter 예외 로그가 발견되지 않았습니다.
- [실제 실행 화면](emulator-installed.png)은 기존에 저장되어 있던 집중 완료 상태입니다. 집중 완료 버튼 등 저장 상태를 바꾸는 조작은 하지 않았습니다.

`focus.db`는 설치 전·설치 직후·앱 실행 후 모두 다음 SHA-256으로 동일했습니다.

```text
f38c819ac97c4f48ef42cfc2b95908be4e41bc658d996c63cb86751dcd0ca70f
```

연결된 실제 휴대폰은 ADB `unauthorized` 상태여서 설치하지 않았습니다. 휴대폰에 적용하려면 기기에서 USB 디버깅을 허용해야 합니다.
