import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/ads.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/purchases.dart';
import 'package:focus_friend_app/session_banner_ad.dart';
import 'package:focus_friend_app/session_engine.dart';

class _Store implements StateStore {
  FocusState value = FocusState();
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (value.revision != expectedRevision) throw StateError('revision');
    value = next.copy();
  }
}

/// This isolated debug harness only uses Google's test ad units. Consent gating
/// is covered by the widget tests; this test exercises the actual native SDK.
class _TestConsent extends AdsConsent {
  @override
  Future<bool> get ready => Future.value(true);
  @override
  Future<void> start() async {}
  @override
  Future<bool> privacyOptionsRequired() async => false;
}

class _Purchases extends Purchases {
  void restoreAdRemoval() => update(
    checked: true,
    entitlements: const Entitlements(owned: {Products.removeAds}),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Native ad platform views need real frames while the host captures them.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('native test banner during focus/rest and restored removal', (
    tester,
  ) async {
    await MobileAds.instance.initialize();
    var now = DateTime(2026, 11, 6, 18).millisecondsSinceEpoch;
    final engine = SessionEngine(_Store(), clock: () => now);
    final purchases = _Purchases();
    final folder = Directory(
      '${Directory.systemTemp.path}/session-banner-preview',
    );
    await folder.create(recursive: true);
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        ads: _TestConsent(),
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> waitForBanner() async {
      // The rest banner waits out the 60-second gap after the focus banner.
      final deadline = DateTime.now().add(const Duration(seconds: 105));
      while (find
              .byKey(const ValueKey('session-banner-creative'))
              .evaluate()
              .isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      expect(
        find.byType(AdWidget),
        findsOneWidget,
        reason: 'Google test banner should load on the emulator',
      );
      final end = tester.getRect(find.widgetWithText(TextButton, '이번 시간 종료'));
      final banner = tester.getRect(
        find.byKey(const ValueKey('session-banner-slot')),
      );
      expect(end.bottom, lessThan(banner.top));
      expect(tester.takeException(), isNull);
    }

    Future<void> capture(String name) async {
      for (var frame = 0; frame < 15; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        await File('${folder.path}/stage').writeAsString(name);
        final ack = File('${folder.path}/$name.captured');
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (!await ack.exists() && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(await ack.exists(), isTrue, reason: 'Host must capture $name');
      });
    }

    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await waitForBanner();
    await capture('focus');
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.status, SessionStatus.paused);
    expect(find.byType(AdWidget), findsOneWidget);
    await tester.tap(find.text('이어서 집중'));
    await tester.pump();
    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SessionBannerAd), findsNothing);
    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pump();
    await waitForBanner();
    await capture('rest');
    purchases.restoreAdRemoval();
    await tester.pump();
    expect(find.byType(SessionBannerAd), findsNothing);
    expect(find.byType(AdWidget), findsNothing);
    await capture('removed');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
