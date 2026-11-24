import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/ads.dart';
import 'package:focus_friend_app/app_exit_dialog.dart';
import 'package:focus_friend_app/exit_native_ads.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/purchases.dart';
import 'package:focus_friend_app/session_engine.dart';

class _Store implements StateStore {
  FocusState value = FocusState();
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    value = next.copy();
  }
}

class _Consent extends AdsConsent {
  @override
  Future<bool> get ready => Future.value(true);
}

class _Purchases extends Purchases {
  void removeAds() => update(
    entitlements: const Entitlements(owned: {Products.removeAds}),
    checked: true,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('real small/medium native ads and restored ad removal', (
    tester,
  ) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 60));
    debugPrint('Exit preview: native SDK initialized');
    const useConfiguredUnit = bool.fromEnvironment(
      'FOCUS_EXIT_USE_CONFIGURED_UNIT',
    );
    const configuredUnit = String.fromEnvironment('ADMOB_NATIVE_EXIT_ID');
    if (useConfiguredUnit) {
      expect(configuredUnit, isNotEmpty);
      expect(
        const bool.fromEnvironment('FOCUS_FRIEND_VERIFICATION'),
        isTrue,
        reason: 'Configured-unit checks must use the isolated verification APK',
      );
    }
    final purchases = _Purchases();
    final ads = ExitNativeAds(
      consent: _Consent(),
      purchases: purchases,
      adUnitId: useConfiguredUnit ? configuredUnit : null,
    )..prepare('광고');
    debugPrint('Exit preview: requested ad unit ${ads.adUnitId}');
    final engine = SessionEngine(
      _Store(),
      clock: () => DateTime(2026, 11, 7, 18).millisecondsSinceEpoch,
    );
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();
    debugPrint('Exit preview: home ready');
    final context = tester.element(find.byType(AppExitScope));
    final folder = Directory('${Directory.systemTemp.path}/app-exit-preview');
    await folder.create(recursive: true);
    Future<void> capture(String stage) async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 1));
        await File('${folder.path}/stage').writeAsString(stage);
        final ack = File('${folder.path}/$stage.captured');
        final until = DateTime.now().add(const Duration(seconds: 60));
        while (!await ack.exists() && DateTime.now().isBefore(until)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(await ack.exists(), isTrue, reason: 'Host capture: $stage');
      });
    }

    Future<void> waitForAds() async {
      for (var attempt = 0; attempt < 3; attempt++) {
        final until = DateTime.now().add(const Duration(seconds: 31));
        while (DateTime.now().isBefore(until) &&
            !ExitAdSize.values.every(ads.hasLoaded)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pump();
        }
        if (ExitAdSize.values.every(ads.hasLoaded)) return;
        ads.endDialog(preloadNext: true);
      }
      fail('Both Google native test ads must load');
    }

    await waitForAds();
    debugPrint('Exit preview: both native ads loaded');
    final available = ads.beginDialog();
    for (final size in ExitAdSize.values) {
      final ad = ads.presented(size)!;
      expect(ad.adUnitId, ads.adUnitId);
      expect(ad.responseInfo?.responseId, isNotEmpty);
      debugPrint('Exit preview: ${size.name} response ${ad.responseInfo}');
    }
    final route = DialogRoute<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AppExitDialog(ads: ads, available: available),
    );
    Navigator.of(context).push(route);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exit-ad-medium')), findsOneWidget);
    expect(find.byType(AdWidget), findsOneWidget);
    await capture('medium');
    // Host changes to the selected concept's pixel size before acknowledging.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('exit-ad-small')), findsOneWidget);
    expect(find.byType(AdWidget), findsOneWidget);
    await capture('small');
    final button = tester.getRect(find.byKey(const ValueKey('exit-confirm')));
    purchases.removeAds();
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('exit-confirm'))), button);
    await capture('removed-open');
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
    ads.endDialog(preloadNext: false);
    await binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AppExitDialog), findsOneWidget);
    expect(find.byType(AdWidget), findsNothing);
    await capture('no-ad');
    await tester.tap(find.byKey(const ValueKey('exit-cancel')));
    await tester.pumpAndSettle();
    ads.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
