import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/ads.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/sound_sheet.dart';
import 'package:focus_friend_app/update_news.dart';
import 'package:focus_friend_app/update_news_sheet.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'update_news_test.dart' show MemoryUpdateNewsStore;

class _DelayedAds extends AdsConsent {
  final completed = Completer<bool>();

  @override
  Future<bool> get ready => completed.future;

  @override
  Future<void> start() async {}

  @override
  Future<bool> privacyOptionsRequired() async => false;
}

class _DelayedLanguage implements AppLanguageStore {
  final completed = Completer<({String? app, String? system})>();

  @override
  Future<({String? app, String? system})> load() => completed.future;

  @override
  Future<void> save(String? tag) async {}
}

class _DelayedSound extends FocusSoundPlayer {
  final checked = Completer<Map<Object?, Object?>>();
  int statusCalls = 0;
  final previews = <SoundPreferences>[];

  @override
  Future<Map<Object?, Object?>> status() {
    statusCalls++;
    return checked.future;
  }

  @override
  Future<void> sync(FocusState state, {bool activate = false}) async {}

  @override
  Future<void> preview(SoundPreferences sound, {Session? session}) async {
    previews.add(sound);
  }

  @override
  Future<void> stop() async {}
}

Future<void> _configure(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  for (final (family, asset) in [
    ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

Future<void> _tick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('update-news-close')));
  await _tick(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('news is automatic once per build and can reopen from Settings', (
    tester,
  ) async {
    await _configure(tester);
    final focusStore = MemoryStore();
    final newsStore = MemoryUpdateNewsStore(previous: 5, updated: true);
    Future<void> launch() async {
      await tester.pumpWidget(
        FocusFriendApp(
          engine: SessionEngine(focusStore),
          updateNews: UpdateNews(newsStore),
          locale: const Locale('ko'),
        ),
      );
      await _tick(tester);
    }

    await launch();
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    await _close(tester);
    expect(newsStore.previous, 6);
    expect(newsStore.acknowledgements, [6]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsNothing);

    await _dispose(tester);
    await launch();
    expect(find.byType(UpdateNewsSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-update-news')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-update-news')));
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('update-news-done')));
    await _tick(tester);
    expect(find.byKey(const ValueKey('start-focus')), findsOneWidget);
    expect(newsStore.acknowledgements, [6]);
    expect(focusStore.commits, 0);

    await _dispose(tester);
    newsStore.build = 7;
    await launch();
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    // Android back is a dismissal too, not a reason to repeat the same news.
    await tester.binding.handlePopRoute();
    await _tick(tester);
    expect(newsStore.previous, 7);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    await _dispose(tester);
  });

  for (final consentFirst in [true, false]) {
    testWidgets(
      'waits for both startup gates when ${consentFirst ? 'consent' : 'language'} completes first',
      (tester) async {
        await _configure(tester);
        final ads = _DelayedAds();
        final language = _DelayedLanguage();
        await tester.pumpWidget(
          FocusFriendApp(
            engine: SessionEngine(MemoryStore()),
            updateNews: UpdateNews(
              MemoryUpdateNewsStore(previous: 5, updated: true),
            ),
            ads: ads,
            language: language,
          ),
        );
        await _tick(tester);
        expect(find.byType(UpdateNewsSheet), findsNothing);
        void finishConsent() => ads.completed.complete(false);
        void finishLanguage() =>
            language.completed.complete((app: 'ko', system: 'en-US'));
        (consentFirst ? finishConsent : finishLanguage)();
        await _tick(tester);
        await _tick(tester);
        expect(find.byType(UpdateNewsSheet), findsNothing);
        (consentFirst ? finishLanguage : finishConsent)();
        await _tick(tester);
        // A locale change rebuilds MaterialApp's localized route subtree before
        // the next idle ticker may present the news in that language.
        await _tick(tester);
        expect(find.byType(UpdateNewsSheet), findsOneWidget);
        expect(find.text('작은 방이\n새로워졌어요'), findsOneWidget);
        await _close(tester);
        await _dispose(tester);
      },
    );
  }

  for (final status in [
    SessionStatus.running,
    SessionStatus.paused,
    SessionStatus.completed,
  ]) {
    testWidgets(
      'defers news while a restored ${status.name} session is present',
      (tester) async {
        await _configure(tester);
        var now = DateTime(2026, 11, 5, 18).millisecondsSinceEpoch;
        final engine = SessionEngine(MemoryStore(), clock: () => now);
        await engine.start(const Duration(minutes: 25));
        if (status == SessionStatus.paused) {
          await engine.pause(engine.state.active!.id);
        } else if (status == SessionStatus.completed) {
          now += 25 * 60000;
          await engine.complete(engine.state.active!.id);
        }
        final newsStore = MemoryUpdateNewsStore(previous: 5, updated: true);
        await tester.pumpWidget(
          FocusFriendApp(
            engine: engine,
            updateNews: UpdateNews(newsStore),
            locale: const Locale('ko'),
          ),
        );
        await _tick(tester);
        expect(find.byType(UpdateNewsSheet), findsNothing);
        expect(engine.state.active!.status, status);
        expect(newsStore.acknowledgements, isEmpty);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(RoomScreen)),
        );
        if (status == SessionStatus.completed) {
          await tester.tap(find.text(l10n.confirm));
        } else {
          await tester.tap(find.text('이번 시간 종료'));
          await tester.pumpAndSettle();
          expect(find.byType(UpdateNewsSheet), findsNothing);
          await tester.tap(find.text('종료하기'));
        }
        await _tick(tester);
        expect(engine.state.active, isNull);
        expect(find.byType(UpdateNewsSheet), findsOneWidget);
        await _close(tester);
        await _dispose(tester);
      },
    );
  }

  testWidgets('waits behind another route and until the desk tab is selected', (
    tester,
  ) async {
    await _configure(tester);
    final loaded = Completer<void>();
    final newsStore = MemoryUpdateNewsStore(previous: 5, updated: true)
      ..loadGate = loaded;
    await tester.pumpWidget(
      FocusFriendApp(
        engine: SessionEngine(MemoryStore()),
        updateNews: UpdateNews(newsStore),
        locale: const Locale('ko'),
      ),
    );
    await _tick(tester);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-2')));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(RoomScreen));
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Existing dialog')),
      ),
    );
    await tester.pumpAndSettle();
    loaded.complete();
    await _tick(tester);
    expect(find.text('Existing dialog'), findsOneWidget);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    navigator.pop();
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    // Test the route gate independently of the non-home tab gate.
    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Home dialog')),
      ),
    );
    await _tick(tester);
    expect(find.text('Home dialog'), findsOneWidget);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    navigator.pop();
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    expect(newsStore.loads, 1);
    await _close(tester);
    await _dispose(tester);
  });

  testWidgets('news waits for a sound flow that has not pushed its route yet', (
    tester,
  ) async {
    await _configure(tester);
    final ads = _DelayedAds();
    final sounds = _DelayedSound();
    final engine = SessionEngine(MemoryStore());
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        updateNews: UpdateNews(
          MemoryUpdateNewsStore(previous: 5, updated: true),
        ),
        ads: ads,
        sounds: sounds,
        locale: const Locale('ko'),
      ),
    );
    await _tick(tester);
    await tester.tap(find.byKey(const ValueKey('open-sound')));
    await tester.pump();
    expect(sounds.statusCalls, 1);
    expect(find.byType(SoundSheet), findsNothing);
    ads.completed.complete(false);
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsNothing);

    sounds.checked.complete({'playing': false});
    await _tick(tester);
    expect(find.byType(SoundSheet), findsOneWidget);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sound-forest')));
    await _tick(tester);
    expect(sounds.previews.single.sound, 'forest');
    await tester.ensureVisible(find.byKey(const ValueKey('save-sound')));
    await tester.tap(find.byKey(const ValueKey('save-sound')));
    await _tick(tester);
    expect(engine.state.sound.sound, 'forest');
    expect(engine.state.sound.enabled, isTrue);
    expect(find.byType(SoundSheet), findsNothing);
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    await _close(tester);
    await _dispose(tester);
  });

  testWidgets('news waits in the background and shows after resumed restore', (
    tester,
  ) async {
    await _configure(tester);
    final loaded = Completer<void>();
    final newsStore = MemoryUpdateNewsStore(previous: 5, updated: true)
      ..loadGate = loaded;
    await tester.pumpWidget(
      FocusFriendApp(
        engine: SessionEngine(MemoryStore()),
        updateNews: UpdateNews(newsStore),
        locale: const Locale('ko'),
      ),
    );
    await _tick(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    loaded.complete();
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsNothing);
    expect(newsStore.acknowledgements, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _tick(tester);
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    await _close(tester);
    await _dispose(tester);
  });

  for (final failure in ['read', 'acknowledge']) {
    testWidgets('$failure failure never prevents starting focus', (
      tester,
    ) async {
      await _configure(tester);
      final newsStore = MemoryUpdateNewsStore(previous: 5, updated: true)
        ..failLoad = failure == 'read'
        ..failSave = failure == 'acknowledge';
      final engine = SessionEngine(MemoryStore());
      await tester.pumpWidget(
        FocusFriendApp(
          engine: engine,
          updateNews: UpdateNews(newsStore),
          locale: const Locale('ko'),
        ),
      );
      await _tick(tester);
      if (failure == 'acknowledge') {
        expect(find.byType(UpdateNewsSheet), findsOneWidget);
        await _close(tester);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _tick(tester);
      }
      expect(find.byType(UpdateNewsSheet), findsNothing);
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await _tick(tester);
      expect(engine.state.active?.status, SessionStatus.running);
      expect(find.byType(UpdateNewsSheet), findsNothing);
      expect(newsStore.previous, 5);
      await _dispose(tester);
    });
  }
}
