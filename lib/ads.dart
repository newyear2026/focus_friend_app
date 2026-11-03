import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob ad unit IDs. Release builds read the real ones from admob.json
/// (`--dart-define-from-file`); everything else uses Google's test units so
/// nobody taps a real ad on their own phone.
abstract final class AdUnits {
  static String get rewarded => _pick(
    const String.fromEnvironment('ADMOB_REWARDED_ID'),
    'ca-app-pub-3940256099942544/5224354917',
  );
  static String get nativeRecords => _pick(
    const String.fromEnvironment('ADMOB_NATIVE_RECORDS_ID'),
    'ca-app-pub-3940256099942544/2247696110',
  );
  static String get nativeSettings => _pick(
    const String.fromEnvironment('ADMOB_NATIVE_SETTINGS_ID'),
    'ca-app-pub-3940256099942544/2247696110',
  );

  static String _pick(String live, String test) =>
      kReleaseMode && live.isNotEmpty ? live : test;
}

/// Google UMP consent (the GDPR message set up in AdMob) and SDK start.
/// Outside the EEA/UK the consent check passes without showing anything.
class AdsConsent {
  /// `--dart-define=ADMOB_DEBUG_EEA=true` shows the EEA flow on an emulator
  /// or registered test device. Release builds ignore it.
  static const _debugEea =
      !kReleaseMode && bool.fromEnvironment('ADMOB_DEBUG_EEA');

  final _ready = Completer<bool>();

  /// Completes with whether ads may be requested this run.
  Future<bool> get ready => _ready.future;

  /// Ask once per launch, after the first frame so the form has an activity.
  Future<void> start() async {
    var allowed = false;
    try {
      final info = ConsentInformation.instance;
      final updated = Completer<void>();
      info.requestConsentInfoUpdate(
        ConsentRequestParameters(
          consentDebugSettings: _debugEea
              ? ConsentDebugSettings(
                  debugGeography: DebugGeography.debugGeographyEea,
                )
              : null,
        ),
        updated.complete,
        // Offline or misconfigured: last launch's answer still applies below.
        (_) => updated.complete(),
      );
      await updated.future;
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      allowed = await info.canRequestAds();
      if (allowed) await MobileAds.instance.initialize();
    } catch (_) {
      // The app works the same without ads.
      allowed = false;
    }
    _ready.complete(allowed);
  }

  /// Settings must offer a way back to the form where the law requires it.
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((_) {});
}
