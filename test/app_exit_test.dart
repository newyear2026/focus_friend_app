// ignore_for_file: implementation_imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:focus_friend_app/ads.dart';
import 'package:focus_friend_app/app_exit_dialog.dart';
import 'package:focus_friend_app/exit_native_ads.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/purchases.dart';
import 'package:focus_friend_app/session_banner_ad.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'purchases_test.dart' show FakePurchases;
import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

class _Consent extends AdsConsent {
  _Consent(this.result);
  final Future<bool> result;
  bool? allowed;
  @override
  bool? get canRequestAds => allowed;
  @override
  Future<bool> get ready => result;
  @override
  Future<void> start() async {}
  @override
  Future<bool> privacyOptionsRequired() async => false;
  void revoke() {
    allowed = false;
    notifyListeners();
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final platform = <MethodCall>[];
  Iterable<MethodCall> loads() =>
      calls.where((c) => c.method == 'loadNativeAd');
  NativeAd adFor(ExitAdSize size) {
    final call = loads().lastWhere(
      (c) =>
          c.arguments['customOptions']['compact'] == (size == ExitAdSize.small),
    );
    return instanceManager.adFor(call.arguments['adId'] as int)! as NativeAd;
  }

  void loaded(ExitAdSize size) {
    final ad = adFor(size);
    ad.listener.onAdLoaded!(ad);
  }

  setUp(() {
    calls.clear();
    SessionBannerAd.resetRequestGap();
    platform.clear();
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      instanceManager.channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platform.add(call);
        return null;
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method == 'resize') {
          return {
            'width': call.arguments['width'],
            'height': call.arguments['height'],
          };
        }
        return call.method == 'create' ? 1 : null;
      },
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  Future<SessionEngine> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    _Consent? consent,
    FakePurchases? purchases,
    bool running = false,
  }) async {
    await loadAppFont();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final engine = SessionEngine(
      MemoryStore(),
      clock: () => DateTime(2026, 11, 7, 18).millisecondsSinceEpoch,
    );
    await engine.restore();
    if (running) await engine.start(const Duration(minutes: 25));
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        ads: consent,
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.pumpAndSettle();
    return engine;
  }

  Future<void> back(WidgetTester tester) async {
    await binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> clean(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets(
    'back opens one popup; cancel/back dismiss; exit invokes Android once',
    (tester) async {
      await open(tester);
      final scope = tester.widget<PopScope<void>>(find.byType(PopScope<void>));
      scope.onPopInvokedWithResult!(false, null);
      scope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();
      expect(find.byType(AppExitDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      expect(platform.where((c) => c.method == 'SystemNavigator.pop'), isEmpty);
      await back(tester);
      await back(tester);
      expect(find.byType(AppExitDialog), findsNothing);
      await back(tester);
      await tester.tap(find.byKey(const ValueKey('exit-confirm')));
      await tester.pumpAndSettle();
      expect(
        platform.where((c) => c.method == 'SystemNavigator.pop'),
        hasLength(1),
      );
      await clean(tester);
    },
  );

  testWidgets(
    'nested route consumes back and running timer survives app exit',
    (tester) async {
      final engine = await open(tester, running: true);
      final session = engine.state.active!;
      Navigator.of(tester.element(find.byType(AppExitScope))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('nested')),
        ),
      );
      await tester.pumpAndSettle();
      await back(tester);
      expect(find.byType(AppExitDialog), findsNothing);
      await back(tester);
      expect(find.text('진행 중인 타이머는 계속 이어집니다.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('exit-confirm')));
      await tester.pumpAndSettle();
      expect(engine.state.active!.id, session.id);
      expect(engine.state.active!.status, SessionStatus.running);
      expect(engine.state.active!.endAt, session.endAt);
      await clean(tester);
    },
  );

  testWidgets(
    'preloads both; late ads never enter an open popup; medium then small on resize',
    (tester) async {
      await open(tester, consent: _Consent(Future.value(true)));
      expect(loads(), hasLength(2));
      await back(tester);
      loaded(ExitAdSize.small);
      loaded(ExitAdSize.medium);
      await tester.pump();
      expect(find.byType(AdWidget), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      // The next pair is requested once the 60-second gap has passed.
      expect(loads(), hasLength(2));
      await tester.pump(const Duration(seconds: 60));
      expect(loads(), hasLength(4));
      loaded(ExitAdSize.small);
      loaded(ExitAdSize.medium);
      await back(tester);
      expect(find.byKey(const ValueKey('exit-ad-medium')), findsOneWidget);
      expect(find.byType(AdWidget), findsOneWidget);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('exit-ad-small')), findsOneWidget);
      expect(find.byType(AdWidget), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('exit-confirm'))).bottom,
        lessThan(640),
      );
      expect(tester.takeException(), isNull);
      await clean(tester);
    },
  );

  testWidgets(
    'medium failure falls back to small, both failures still allow exit',
    (tester) async {
      await open(tester, consent: _Consent(Future.value(true)));
      final medium = adFor(ExitAdSize.medium);
      medium.listener.onAdFailedToLoad!(
        medium,
        LoadAdError(3, 'test', 'No fill', null),
      );
      loaded(ExitAdSize.small);
      await back(tester);
      expect(find.byKey(const ValueKey('exit-ad-small')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('exit-cancel')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 60));
      for (final size in ExitAdSize.values) {
        final ad = adFor(size);
        ad.listener.onAdFailedToLoad!(
          ad,
          LoadAdError(3, 'test', 'No fill', null),
        );
      }
      await back(tester);
      expect(find.byType(AdWidget), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exit-confirm')));
      await tester.pumpAndSettle();
      expect(
        platform.where((c) => c.method == 'SystemNavigator.pop'),
        hasLength(1),
      );
      await clean(tester);
    },
  );

  for (final revokeConsent in [false, true]) {
    testWidgets(
      'eligibility change (consent=$revokeConsent) removes ads without moving exit',
      (tester) async {
        final consent = _Consent(Future.value(true));
        final purchases = FakePurchases();
        await open(tester, consent: consent, purchases: purchases);
        loaded(ExitAdSize.small);
        loaded(ExitAdSize.medium);
        await back(tester);
        final before = tester.getRect(
          find.byKey(const ValueKey('exit-confirm')),
        );
        if (revokeConsent) {
          consent.revoke();
        } else {
          await purchases.buy(Products.removeAds);
        }
        await tester.pumpAndSettle();
        expect(find.byType(AdWidget), findsNothing);
        expect(
          tester.getRect(find.byKey(const ValueKey('exit-confirm'))),
          before,
        );
        await clean(tester);
      },
    );
  }

  testWidgets('consent denied or ad-removal owned never requests exit ads', (
    tester,
  ) async {
    for (final owned in [false, true]) {
      await open(
        tester,
        consent: _Consent(Future.value(owned)),
        purchases: FakePurchases(
          entitlements: Entitlements(owned: owned ? {Products.allFriends} : {}),
        ),
      );
      expect(loads(), isEmpty);
      await back(tester);
      expect(find.byType(AdWidget), findsNothing);
      await clean(tester);
    }
  });

  testWidgets('a failed exit ad is requested again when the app reopens', (
    tester,
  ) async {
    final ads = ExitNativeAds(consent: _Consent(Future.value(true)))
      ..prepare('광고');
    await tester.pump();
    expect(loads(), hasLength(2));
    loaded(ExitAdSize.medium);
    final small = adFor(ExitAdSize.small);
    small.listener.onAdFailedToLoad!(
      small,
      LoadAdError(2, 'test', 'Network error', null),
    );
    await tester.pump(const Duration(seconds: 61));
    // No retry loop while the app stays open.
    expect(loads(), hasLength(2));

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(loads(), hasLength(3));
    expect(loads().last.arguments['customOptions']['compact'], isTrue);
    loaded(ExitAdSize.small);
    expect(ads.beginDialog(), {ExitAdSize.small, ExitAdSize.medium});
    ads.endDialog(preloadNext: false);
    ads.dispose();
    await tester.pump();
  });

  testWidgets(
    'expired and timed-out caches are omitted; late consent after dispose is safe',
    (tester) async {
      var now = DateTime(2026, 11, 7);
      final ads = ExitNativeAds(
        consent: _Consent(Future.value(true)),
        now: () => now,
      )..prepare('광고');
      await tester.pump();
      loaded(ExitAdSize.small);
      loaded(ExitAdSize.medium);
      now = now.add(const Duration(hours: 1));
      expect(ads.beginDialog(), isEmpty);
      ads.endDialog(preloadNext: true);
      await tester.pump(const Duration(seconds: 31));
      expect(ads.beginDialog(), isEmpty);
      ads.dispose();
      await tester.pump();
      calls.clear();
      final result = Completer<bool>();
      final late = ExitNativeAds(consent: _Consent(result.future))
        ..prepare('광고');
      late.dispose();
      result.complete(true);
      await tester.pump();
      expect(loads(), isEmpty);
    },
  );

  testWidgets(
    'every displayed native layout fits fully above the fixed exit controls',
    (tester) async {
      await loadAppFont();
      for (final (size, scale, running, language) in [
        (const Size(390, 844), 1.0, false, 'ko'),
        (const Size(390, 644), 1.0, false, 'ko'),
        (const Size(320, 640), 1.0, false, 'es'),
        (const Size(390, 800), 1.0, true, 'en'),
        (const Size(390, 640), 1.4, false, 'es'),
        (const Size(320, 568), 1.0, false, 'ko'),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(language),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: AppExitDialog(
                available: const {ExitAdSize.small, ExitAdSize.medium},
                timerRunning: running,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final slot = find.byWidgetPredicate(
          (w) =>
              w.key == const ValueKey('exit-ad-small') ||
              w.key == const ValueKey('exit-ad-medium'),
        );
        if (slot.evaluate().isNotEmpty) {
          final ad = tester.getRect(slot);
          final scroll = tester.getRect(find.byType(SingleChildScrollView));
          final exit = tester.getRect(
            find.byKey(const ValueKey('exit-confirm')),
          );
          expect(ad.top, greaterThanOrEqualTo(scroll.top));
          expect(ad.bottom, lessThanOrEqualTo(scroll.bottom));
          expect(exit.top - ad.bottom, greaterThanOrEqualTo(24));
        }
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await clean(tester);
    },
  );

  for (final lang in ['ko', 'en', 'es', 'ja']) {
    testWidgets('$lang large text and landscape keep exit controls visible', (
      tester,
    ) async {
      await loadAppFont();
      for (final size in [const Size(320, 568), const Size(700, 360)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(lang),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: AppExitDialog(
                available: {ExitAdSize.small, ExitAdSize.medium},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AdWidget), findsNothing);
        final exit = tester.getRect(find.byKey(const ValueKey('exit-confirm')));
        expect(exit.bottom, lessThanOrEqualTo(size.height));
        expect(exit.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await clean(tester);
    });
  }
}
