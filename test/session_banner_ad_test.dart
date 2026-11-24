// The SDK's channel codec is internal; use it only at the native test boundary.
// ignore_for_file: implementation_imports

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:focus_friend_app/ads.dart';
import 'package:focus_friend_app/desk_home.dart';
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
  void change(bool? value) {
    allowed = value;
    notifyListeners();
  }

  @override
  Future<bool> get ready => result;
  @override
  Future<void> start() async {}
  @override
  Future<bool> privacyOptionsRequired() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  Iterable<MethodCall> loads() =>
      calls.where((call) => call.method == 'loadBannerAd');
  Iterable<MethodCall> disposals() => calls.where(
    (call) =>
        call.method == 'disposeAd' &&
        loads().any((load) => load.arguments['adId'] == call.arguments['adId']),
  );
  BannerAd latestAd() =>
      instanceManager.adFor(loads().last.arguments['adId'] as int)! as BannerAd;

  setUp(() {
    calls.clear();
    SessionBannerAd.resetRequestGap();
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'resize') {
            return {
              'width': call.arguments['width'],
              'height': call.arguments['height'],
            };
          }
          return call.method == 'create' ? 1 : null;
        });
  });

  Future<SessionEngine> open(
    WidgetTester tester, {
    SessionMode? mode = SessionMode.focus,
    Future<bool>? consent,
    _Consent? ads,
    FakePurchases? purchases,
    Size size = const Size(390, 844),
    String language = 'ko',
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    await loadAppFont();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.view.padding = FakeViewPadding(bottom: bottomInset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final engine = SessionEngine(
      MemoryStore(),
      clock: () => DateTime(2026, 11, 6, 18).millisecondsSinceEpoch,
    );
    await engine.restore();
    if (mode != null) {
      await engine.start(const Duration(minutes: 25), mode: mode);
    }
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        ads: ads ?? _Consent(consent ?? Future.value(true)),
        purchases: purchases,
        locale: Locale(language),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return engine;
  }

  testWidgets('waits for consent and loads once across timer ticks and pause', (
    tester,
  ) async {
    final consent = Completer<bool>();
    final engine = await open(tester, consent: consent.future);
    expect(loads(), isEmpty);
    final room = tester.getRect(find.byKey(const ValueKey('study-scene')));
    final pause = tester.getRect(find.text('잠시 멈추기'));
    consent.complete(true);
    await tester.pump();
    expect(loads(), hasLength(1));
    final ad = latestAd();
    expect(ad.adUnitId, 'ca-app-pub-3940256099942544/6300978111');
    ad.listener.onAdLoaded!(ad);
    await tester.pump();
    expect(find.byType(AdWidget), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('study-scene'))), room);
    expect(tester.getRect(find.text('잠시 멈추기')), pause);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.status, SessionStatus.paused);
    expect(loads(), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(disposals(), hasLength(1));
  });

  for (final allowed in [false, true]) {
    testWidgets('late consent $allowed after leaving never requests an ad', (
      tester,
    ) async {
      final consent = Completer<bool>();
      await open(tester, consent: consent.future);
      await tester.pumpWidget(const SizedBox.shrink());
      consent.complete(allowed);
      await tester.pump();
      expect(loads(), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('consent completed in background waits until resume to request', (
    tester,
  ) async {
    final consent = Completer<bool>();
    await open(tester, consent: consent.future);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    consent.complete(true);
    await tester.pump();
    expect(loads(), isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(loads(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('withdrawn consent removes the banner slot and its ad', (
    tester,
  ) async {
    final ads = _Consent(Future.value(true));
    await open(tester, ads: ads);
    final ad = latestAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pump();
    expect(find.byType(AdWidget), findsOneWidget);
    ads.change(false);
    await tester.pump();
    expect(find.byKey(const ValueKey('session-banner-slot')), findsNothing);
    expect(find.byType(AdWidget), findsNothing);
    expect(disposals(), hasLength(1));
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('이어서 집중'), findsOneWidget);
    expect(loads(), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());

    calls.clear();
    await open(tester, ads: _Consent(Future.value(false))..allowed = false);
    expect(find.byKey(const ValueKey('session-banner-slot')), findsNothing);
    expect(loads(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('consent given after a startup refusal loads the banner', (
    tester,
  ) async {
    final ads = _Consent(Future.value(false))..allowed = false;
    await open(tester, ads: ads);
    expect(find.byKey(const ValueKey('session-banner-slot')), findsNothing);
    expect(loads(), isEmpty);
    ads.change(true);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('session-banner-slot')), findsOneWidget);
    expect(loads(), hasLength(1));
    final ad = latestAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pump();
    expect(find.byType(AdWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a shown banner turns the navigation buttons dark', (
    tester,
  ) async {
    await open(tester, bottomInset: 48);
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.light,
    );
    final ad = latestAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pump();
    expect(
      SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
    expect(
      SystemChrome.latestStyle?.systemNavigationBarColor,
      const Color(0xFFF1ECE4),
    );
    // A non-clickable line and buffer separate the ad from system buttons.
    final creative = tester.getRect(
      find.byKey(const ValueKey('session-banner-creative')),
    );
    final separator = tester.getRect(
      find.byKey(const ValueKey('session-banner-bottom-separator')),
    );
    expect(separator.top, creative.bottom);
    expect(844 - 48 - separator.bottom, 4);
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('denied consent and no-fill leave the timer usable', (
    tester,
  ) async {
    await open(tester, consent: Future.value(false));
    expect(loads(), isEmpty);
    expect(find.byType(AdWidget), findsNothing);
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('이어서 집중'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    await open(tester);
    final ad = latestAd();
    ad.listener.onAdFailedToLoad!(ad, LoadAdError(3, 'test', 'No fill', null));
    await tester.pump();
    expect(disposals(), hasLength(1));
    expect(find.byType(AdWidget), findsNothing);
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('이어서 집중'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'background and sheets dispose the ad; a fresh one waits 60 seconds',
    (tester) async {
      await open(tester);
      expect(loads(), hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(disposals(), hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Returning within a minute keeps the slot empty instead of re-requesting.
      expect(loads(), hasLength(1));
      expect(find.byKey(const ValueKey('session-banner-slot')), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      expect(loads(), hasLength(2));
      await tester.tap(find.text('이번 시간 종료'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionBannerAd), findsNothing);
      expect(disposals(), hasLength(2));
      Navigator.of(tester.element(find.text('종료하기'))).pop();
      await tester.pumpAndSettle();
      // The gap counts from the previous request, not from the sheet closing.
      expect(loads(), hasLength(2));
      await tester.pump(const Duration(seconds: 61));
      expect(loads(), hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('only live focus/rest sessions have a banner', (tester) async {
    for (final mode in [
      null,
      SessionMode.demo,
      SessionMode.focus,
      SessionMode.rest,
    ]) {
      // Each mode is a separate launch, not a quick return to the same ad.
      SessionBannerAd.resetRequestGap();
      final engine = await open(tester, mode: mode);
      final eligible = mode == SessionMode.focus || mode == SessionMode.rest;
      expect(
        find.byType(SessionBannerAd),
        eligible ? findsOneWidget : findsNothing,
      );
      if (eligible) {
        final ad = latestAd();
        ad.listener.onAdLoaded!(ad);
        await tester.pump();
        await tester.tap(find.text('이번 시간 종료'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('종료하기'));
        await tester.pumpAndSettle();
        expect(engine.state.active, isNull);
        expect(find.byType(SessionBannerAd), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final product in [Products.removeAds, Products.allFriends]) {
    testWidgets('$product restoration removes the active banner immediately', (
      tester,
    ) async {
      final purchases = FakePurchases();
      await open(tester, purchases: purchases);
      final ad = latestAd();
      ad.listener.onAdLoaded!(ad);
      await tester.pump();
      expect(find.byType(AdWidget), findsOneWidget);
      await purchases.buy(product);
      await tester.pump();
      expect(find.byType(SessionBannerAd), findsNothing);
      expect(find.byKey(const ValueKey('session-banner-slot')), findsNothing);
      expect(disposals(), hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      calls.clear();
      await open(tester, purchases: purchases, mode: SessionMode.rest);
      expect(loads(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final language in ['ko', 'en', 'es', 'ja']) {
    testWidgets('$language controls scroll above the banner on small screens', (
      tester,
    ) async {
      await open(
        tester,
        size: const Size(320, 640),
        language: language,
        textScale: 1.5,
        bottomInset: 24,
      );
      final ad = latestAd();
      ad.listener.onAdLoaded!(ad);
      await tester.pump();
      final text = lookupAppLocalizations(Locale(language));
      final end = find.widgetWithText(TextButton, text.endThisSession);
      await tester.ensureVisible(end);
      await tester.pump();
      final footer = tester.getRect(
        find.byKey(const ValueKey('session-banner-slot')),
      );
      final creative = tester.getRect(
        find.byKey(const ValueKey('session-banner-creative')),
      );
      final controls = tester.getRect(end);
      final scroll = tester.getRect(
        find.descendant(
          of: find.byType(DeskHome),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(creative.size, const Size(320, 50));
      expect(creative.bottom, lessThanOrEqualTo(616));
      expect(controls.bottom, lessThanOrEqualTo(footer.top));
      expect(scroll.bottom, lessThanOrEqualTo(footer.top));
      expect(tester.takeException(), isNull);
      await tester.tap(end);
      await tester.pumpAndSettle();
      expect(find.text(text.endThisSession), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('narrow windows do not request or clip a 320 dp banner', (
    tester,
  ) async {
    await open(tester, size: const Size(300, 640));
    expect(loads(), isEmpty);
    expect(find.byKey(const ValueKey('session-banner-slot')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
