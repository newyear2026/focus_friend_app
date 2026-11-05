# Google Play 구매 검증

2026-11-05 기준. Play Console을 직접 확인한 결과, 상품은 6개 중 4개가 등록되어 있고 기존 비공개 테스트 alpha가 운영 중입니다. **구매 검증에 내부 테스트 트랙은 필수가 아닙니다.** 비공개 테스트와 라이선스 테스터 계정으로도 테스트 결제를 할 수 있습니다. 아래 자동 테스트는 SDK 응답을 가짜로 주입하므로 실제 Play 결제 성공을 뜻하지 않습니다.

## Play Console 직접 확인 결과

| 항목 | 확인 결과 |
| --- | --- |
| 등록 상품 | `friend_otter`, `friend_squirrel`, `friend_fennec`, `remove_ads` 4개 |
| 미등록 상품 | `friend_penguin`, `all_friends` |
| 구매 옵션 | 등록된 4개 모두 활성, 구입 유형, 이전 버전 호환, 174개 국가/지역 |
| 구매 옵션 ID | 해달 `characterbuy`, 다람쥐·사막여우 `caracterbuy`, 광고 제거 `removeads`. 앱은 상품 ID로 조회하므로 옵션 ID가 문서 예시 `buy`와 달라도 문제가 아님 |
| 해달 지역 가격 | 멕시코 MXN 10.00, 한국 KRW 1,200, 사용 가능 |
| 라이선스 테스트 | 기존 이메일 목록 2개 선택됨, `RESPOND_NORMALLY` |
| 내부 테스트 | 비활성, 출시 버전 없음, 선택된 테스터 목록 없음 |
| 비공개 테스트 alpha | 버전 5 (0.1.0) 제공 중 |
| 로컬 테스트 기기 | 에뮬레이터와 USB 연결 Galaxy S23. 휴대폰에는 Play 설치본 v3이 있음 |
| 수정 빌드 | v7 AAB 준비 및 서명 검증 완료, Play 업로드 전 |

확인 화면: [등록 상품 목록](verification-2026-11-05/products.jpg). 상품과 테스터 설정을 변경하거나 AAB를 업로드하지 않았습니다. 내부 테스트에는 파일을 올리지 않은 임시 출시 화면만 준비했습니다. 사용자가 ADB 화면 확인·조작을 허용한 뒤 에뮬레이터 로그인 화면과 연결된 휴대폰을 확인했으며, 실제 Play 결제창/테스트 주문은 아직 확인하지 못했습니다.

## 실제 Android SDK 진단 결과

동일한 `dev.jaewook.deskmate` 앱 ID로 `tool/check_play_billing.dart`를 에뮬레이터에서 실행했습니다. 테스트 대역 없이 설치된 Google Play SDK에 직접 연결했고, 구매·승인·소비·환불은 요청하지 않았습니다.

- 결과: `PLAY_BILLING_DIAGNOSTIC {"isAvailable":false}`
- BillingClient 로그: `In-app billing API version 3 is not supported on this device.`
- Google Play Store는 설치·활성 상태이지만, 에뮬레이터의 Google 계정 수는 **0개**였습니다.
- 진단 실행 전후 `focus.db` SHA-256이 동일하여 기존 집중 기록 데이터가 보존된 것을 확인했습니다.
- 현재 환경에서는 상품 가격 조회와 결제창 테스트로 진행할 수 없습니다. 라이선스 테스터 계정으로 Play Store 로그인 후 다시 연결을 확인해야 합니다. 로그인만으로 해결되는지는 재확인이 필요합니다.

진단 실행 명령(실제 앱과 같은 패키지를 사용하며, 종료 후 정상 앱을 다시 실행):

```sh
flutter run -d emulator-5554 -t tool/check_play_billing.dart --no-resident
flutter run -d emulator-5554 -t lib/main.dart --no-resident
```

진단 화면은 앱 데이터를 읽거나 변경하지 않고 상품 가격과 구매 상태만 조회합니다. 기본 앱 진입점 `lib/main.dart`와 테스트 배포용 AAB는 바꾸지 않습니다.

## 연결된 휴대폰 준비 상태

Galaxy S23(SM-S911B, Android 16)을 USB로 연결해 확인했습니다. 라이선스 테스트 계정이 등록되어 있고, Deskmate는 Play Store에서 설치한 버전 코드 3입니다. 현재 콘솔의 비공개 테스트 배포본은 버전 5이며, 수정한 버전 7은 아직 업로드 전입니다.

설치된 Play 앱 서명이 로컬 디버그/업로드 서명과 달라 로컬 APK로 직접 덮어쓸 수 없습니다. 기존 기록을 유지하며 수정본을 검증하려면 버전 7을 **기존 비공개 테스트 alpha**에 배포하고 Play Store로 업데이트할 수 있습니다. 내부 테스트도 선택 가능한 별도 경로일 뿐 필수는 아닙니다. 먼저 준비했던 내부 테스트 임시 출시 화면에는 파일을 업로드하지 않았으며, 어떤 트랙에도 버전 7을 배포하지 않았습니다. [준비했던 화면](verification-2026-11-05/internal-test-v7-draft.jpg)

콘솔에서 alpha의 실제 App Bundle 버전 코드가 5인 것과 구매 기능이 포함된 출시 노트를 확인했습니다. 현재 배포본의 구매 흐름은 버전 5로, 이번 코드 수정의 회귀 검증은 버전 7로 구분해야 합니다.

## 로컬 검증

검증 결과: 전체 Flutter 테스트 **171개 통과**(구매 서비스 22개, 구매 화면/보유 판단 15개 포함), `flutter analyze` 오류 없음. 릴리스 AAB 빌드와 서명 검증(`jarsigner -verify`)도 통과했습니다. 실제 Play 결제·주문·자동 환불 여부는 아직 미검증입니다.

```sh
flutter test test/play_purchases_test.dart test/purchases_test.dart
flutter analyze
```

- `test/play_purchases_test.dart`: 실제 `PlayPurchases` 서비스에 SDK 경계만 대체합니다. 구매 성공·취소·실패·대기, 복원·환불, 승인 재시도, 중복 구매 방지, 응답 경합, 가격 재조회, 종료 처리를 검증합니다.
- `test/purchases_test.dart`: 친구·묶음 구매와 취소/실패 후 재시도, 잠금 표시, 광고 제거가 설정·기록에 반영되는지 검증합니다.
- 수정 전 테스트로 빈 상품 ID 취소/오류의 대기 고착, 승인 대기 중 다른 구매 누락, 오래된 보유 조회가 새 구매를 지우는 현상, 스트림 오류 후 대기 고착을 재현했습니다.

## 기존 비공개 테스트에서 구매 검증 준비

1. 등록된 4개 상품의 구매 옵션 활성 상태를 확인합니다. 전체 6개를 검증하려면 `friend_penguin`, `all_friends`도 등록해야 합니다. 구매 옵션 ID는 `buy`일 필요가 없습니다. 가격·국가·이전 버전 호환 설정은 [제품 등록표](products/README.md)를 따릅니다.
2. **설정 → 라이선스 테스트**에 테스트 휴대폰의 Google 계정을 등록합니다. 테스트 트랙 참여자와 라이선스 테스터는 별도 설정입니다. 테스트 트랙 참여만 하면 실제 금액이 청구될 수 있습니다.
3. 현재 배포본을 검증할 때는 기존 alpha 버전을 Play Store에서 설치/업데이트합니다. 이번 수정본을 검증할 때는 승인 후 아래 버전 7 AAB를 **테스트 → 비공개 테스트 → alpha**의 새 릴리스로 올리고, 배포 완료 후 같은 테스트 계정의 Play Store에서 업데이트합니다. 기존 alpha의 테스터가 새 버전을 받게 됩니다. 게시 후 반영에는 시간이 걸릴 수 있습니다.
4. 구매창에서 테스트 구매 안내와 `Test card, always approves` 같은 테스트 결제 수단이 표시되는지 먼저 확인합니다. 실제 카드만 표시된다면 구매를 확정하기 전에 계정/라이선스 설정을 확인합니다.

위 계정·테스트 결제 수단·테스트 트랙 설정의 근거: [Google Play Billing 공식 테스트 안내](https://developer.android.com/google/play/billing/test), [Play Console 라이선스 테스트](https://support.google.com/googleplay/android-developer/answer/6062777).

```sh
# 테스트 광고를 사용하는 서명된 테스트 배포용 빌드
flutter build appbundle --release --build-number=7
```

- 산출물: `build/app/outputs/bundle/release/app-release.aab`
- 앱 ID: `dev.jaewook.deskmate`, 버전: `0.1.0 (7)`
- AAB는 Play Console 업로드용이며 휴대폰에 직접 설치하는 APK가 아닙니다.
- `--dart-define=FOCUS_FRIEND_VERIFICATION=true`는 사용하지 않습니다. 이 옵션은 `.verification` 앱 ID를 만들어 등록된 Play 상품과 일치하지 않습니다.
- `admob.json`을 전달하지 않아 테스트 광고를 사용합니다.
- 기존 AAB의 버전 코드가 이미 7 이상으로 올라가 있다면 더 큰 번호로 다시 빌드해야 합니다.
- 이번 산출물 SHA-256: `517a7eba14d66c2186c63cae85facaa5c7aa48a15e9c35bf3463563fc8cea6a9`

## 휴대폰 확인표

각 항목은 아직 실제 Play에서 검증하지 않았습니다. 성공/실패와 테스트 계정, 기기, 설치 버전을 기록하세요.

| 항목 | 조작 | 기대 결과 |
| --- | --- | --- |
| 가격 | 친구/설정/묶음 화면 열기 | 등록된 4개는 현지 가격 표시. 미등록 2개는 등록·활성화 후 확인 |
| 취소 | 구매창에서 뒤로 가기 | 잠금 유지, 버튼 활성화, 다시 구매 가능 |
| 실패 | 항상 거절 테스트 카드 | 잠금 유지, 실패 안내, 재시도 가능 |
| 개별 친구 | 항상 승인 카드로 친구 1개 구매 | 해당 친구만 해제, 바로 적용, 광고 유지 |
| 광고 제거 | 설정에서 `remove_ads` 구매 | 기록과 설정의 광고 제거, 다른 친구 잠금 유지 |
| 묶음 | `all_friends` 구매 | 현재 유료 친구 4명과 광고 제거 해제 |
| 보유 상품 | 이미 산 상품 다시 열기 | 추가 결제 대신 보유/적용 표시 |
| 재실행·복원 | 앱 종료 후 온라인 재실행, 구매 복원 | 이전 보유 내역 복구 |
| 대기 후 승인 | 늦게 승인하는 테스트 카드, 앱 복귀 | 대기 중 잠금, 완료 후 해제 |
| 대기 후 거절 | 늦게 거절하는 테스트 카드, 앱 복귀 | 잠금 유지, 대기 해제 후 재시도 가능 |
| 승인 확인 | 구매 3분 이후 주문/보유 상태 확인 | 승인 누락에 의한 자동 환불 없음 |
| 환불·회수 | 테스트 주문을 환불하고 권한 회수 후 앱 복귀 | 상품 다시 잠금, 해당 친구는 진행 중 세션이 없을 때 랫서팬더로 복귀, 광고 제거만 보유했다면 광고 복귀 |
| 일시적 통신 실패 | 앱 실행 중 네트워크 끊기/재연결 후 복귀 | 기존 메모리 보유 유지, 연결 복구 후 가격/보유 재조회 |

비소모성 상품을 반복 테스트할 때는 Play Console에서 테스트 구매의 환불과 권한 회수가 필요합니다. 라이선스 테스터의 미승인 구매는 3분 후 환불될 수 있습니다. [공식 비소모성·대기 구매 테스트](https://developer.android.com/google/play/billing/test#test-non-consumable-products)

## 남아 있는 제한

보유 정보는 메모리에만 있습니다. 구매 후 앱을 완전히 종료하고 Play 조회가 실패하는 상황에서는 저장된 현재 친구는 유지하지만, 다른 유료 친구 선택과 광고 제거는 복구되지 않습니다. 온라인 복원 검증과 별도로 이 상황을 확인해야 하며, 오프라인 재실행까지 보장하려면 보유 정보의 로컬 캐시가 추가로 필요합니다.
