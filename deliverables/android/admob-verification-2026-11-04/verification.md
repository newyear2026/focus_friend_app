# Deskmate AdMob 검증 — 2026-11-04

- AdMob 게시 목록: Deskmate: Cozy Study Timer 메시지가 게시됨. 관리용 이름은 “Deskmate_GDPR”로 수정 및 게시됨을 최신 목록에서 재확인.
- 검증 앱 매니페스트의 실제 앱 ID: `ca-app-pub-2706404530136726~9410863766`.
- 별도 검증 앱에서 UMP 동의 기록 초기화 후 유럽 지역 테스트 조건으로 실행: 게시된 동의창 표시 성공.
- 동의 버튼 완료 후 앱 복귀 및 테스트 광고 표시 성공.
- 설정의 Ad privacy choices에서 동의창 다시 열기 성공.
- 동의하지 않음 버튼 완료 후 설정 화면 복귀 성공.
- 배포용 앱 0.1.0+4에서 실제 광고 단위로 기록 및 설정의 네이티브 광고 표시 성공. 두 화면 모두 동영상과 광고 표기, 버튼 확인.
- 배포용 앱의 일반 지역 요청은 IABTCF_gdprApplies=0으로 응답. 기존 “no form(s) configured” 오류가 재현되지 않음.
- 광고는 Android 에뮬레이터의 테스트 광고이며 수익 발생 여부를 검증한 것은 아님. 동의 검증용 debug 앱에서는 Google 샘플 광고 단위를 사용했고, 배포용 앱에서는 실제 광고 단위를 사용함.

## 문구 수정 재확인 완료

사용자 재게시 후 별도의 빈 에뮬레이터에 검증 앱을 설치하고 실제 앱 ID로 UMP 메시지를 새로 요청함. 영어 동의창 첫 문장이 “Deskmate asks for your consent to use your personal data for the following purposes:”로 수정되어 내려오는 것을 확인. 동의·동의하지 않음·옵션 관리 버튼도 정상 표시됨. 관리용 메시지 이름은 “Deskmate_GDPR”, 대상 앱은 “Deskmate: Cozy Study Timer”, 상태는 “게시됨”.

이번 재확인은 문구와 게시 반영에 한정하며, 광고·동의 변경 동작은 위의 앞선 앱 테스트 결과를 유지함. 앱 코드와 AAB는 변경하지 않음.

최신 확인 화면: consent-corrected.png. 아래 consent.png 및 privacy-options.png는 문구 수정 전 기능 검증 당시의 화면.

## 증거

- consent.png: 실제 앱 ID의 첫 동의창
- privacy-options.png: 설정에서 다시 열린 동의창
- release-records.png: 배포용 앱 기록 화면의 테스트 광고
- release-settings.png: 배포용 앱 설정 화면의 테스트 광고

## 빌드

이번 검증에서는 소스와 기존 AAB를 변경하지 않음. 동의 메시지는 AdMob에서 배포되므로 이번 설정 반영을 위해 AAB를 다시 빌드할 필요 없음.

AAB: `deskmate-0.1.0+4.aab`
SHA-256: `155e045f9473eadd5fb3941480961ce208ae5d7d33e907a85733051ecf5b4bb5`

## 실제 광고 게재 준비 상태 확인

후속 AdMob 계정 확인에서 Deskmate의 상태는 “검토 필요”, “광고 게재가 제한됨”, “스토어를 추가하여 한도 해제”이며 스토어 및 패키지 연결이 비어 있음. 앱 내 연동 테스트는 성공했으며, 일반 사용자 대상 광고의 전체 게재를 위해 공개된 스토어 페이지 연결과 준비 상태 승인 절차가 남아 있음.

기존 개발자 사이트 https://mexicojacobo.blogspot.com 의 /app-ads.txt는 /ads.txt로 연결되고, `google.com, pub-2706404530136726, DIRECT, f08c47fec0942fa0`를 제공함. AdMob은 이 파일을 다른 세 앱에 대해 “준비됨 / 파일을 찾아서 확인했습니다”로 표시. Deskmate는 아직 이 인증 목록에 없음. 같은 개발자 사이트를 Deskmate의 Play 스토어 연락처 웹사이트로 연결하여 재사용 가능하며, 스토어 연결 후 Deskmate의 인증 상태 확인 필요.

Play Console의 광고 포함, 광고 ID, 데이터 보안, 개인정보처리방침 신고 상태는 이번 계정 확인에서 직접 열어보지 않았으므로 출시 전 확인 항목으로 남김.

## 현재 표시 재확인 — 후속 요청

기존 에뮬레이터에서 사용자가 열어 둔 앱은 dev.jaewook.deskmate 0.1.0+3 디버그 버전이며, 24:56에 일시정지된 집중 화면이었다. 이 화면에는 광고가 배치되어 있지 않다. 해당 앱을 교체하거나 집중 세션을 종료하지 않았고, 확인 후 원래 일시정지 화면으로 복귀했다.

별도 검증 패키지(dev.jaewook.deskmate.verification)만 0.1.0+4 디버그 APK로 업데이트하여 확인했다. 실제 AdMob 앱 ID의 유럽 동의 테스트를 완료한 뒤 기록·설정 두 화면에서 ‘테스트 광고: Flood-It!’의 이미지, 광고 표기, 버튼이 표시되었다. 두 화면 모두 AdMob native ad validator가 ‘No implementation issues found’로 통과했다. 이 디버그 검증에는 Google 샘플 네이티브 광고 단위를 사용했다.

현재 증거: current-debug-records.png, current-debug-settings.png, current-debug-records-validator.png, current-debug-settings-validator.png.

이번 요청에서는 컴퓨터의 여유 공간 부족으로 새 에뮬레이터를 시작하지 못했으므로, 실제 광고 단위를 사용하는 배포용 APK를 새로 실행한 결과로 보아서는 안 된다. 위의 기존 배포용 APK 검증 결과는 앞선 확인 결과이며, 이번에 새로 확인한 것은 분리된 최신 디버그 앱의 테스트 광고 표시다. 앱 코드와 AAB는 변경하지 않았다.
