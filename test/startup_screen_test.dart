import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'package:focus_friend_app/desk_home.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/startup_screen.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

class _ControlledStore extends MemoryStore {
  Future<FocusState>? nextLoad;

  @override
  Future<FocusState> load() {
    final pending = nextLoad;
    nextLoad = null;
    return pending ?? super.load();
  }
}

class _DelayedLanguage implements AppLanguageStore {
  final completed = Completer<({String? app, String? system})>();

  @override
  Future<({String? app, String? system})> load() => completed.future;

  @override
  Future<void> save(String? tag) async {}
}

Future<void> _configure(WidgetTester tester) async {
  await loadAppFont();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('loading dots pulse and pause while the app is in background', (
    tester,
  ) async {
    await _configure(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StartupLoadingDots())),
    );
    double middleOpacity() => tester
        .widget<Opacity>(find.byKey(const ValueKey('startup-dot-1')))
        .opacity;
    final initial = middleOpacity();
    await tester.pump(const Duration(milliseconds: 600));
    expect(middleOpacity(), isNot(initial));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = middleOpacity();
    await tester.pump(const Duration(seconds: 2));
    expect(middleOpacity(), paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(middleOpacity(), isNot(paused));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup hides room and navigation until saved state is ready', (
    tester,
  ) async {
    await _configure(tester);
    final pending = Completer<FocusState>();
    final store = _ControlledStore()..nextLoad = pending.future;
    final engine = SessionEngine(store);
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.byType(StartupLoadingDots), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('startup-status')))
          .semanticsLabel,
      '집중할 공간을 준비하고 있어요.',
    );
    expect(find.byType(DeskIllustration), findsNothing);
    expect(find.byType(DeskNavigation), findsNothing);

    pending.complete(FocusState(friend: FocusFriend.otter));
    await tester.pumpAndSettle();
    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(DeskHome), findsOneWidget);
    expect(engine.state.friend, FocusFriend.otter);
    expect(store.commits, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final failLanguage in [false, true]) {
    testWidgets('startup waits for language; failure=$failLanguage', (
      tester,
    ) async {
      await _configure(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final language = _DelayedLanguage();
      await tester.pumpWidget(
        FocusFriendApp(
          engine: SessionEngine(MemoryStore()),
          language: language,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(DeskHome), findsNothing);
      if (failLanguage) {
        language.completed.completeError(StateError('language unavailable'));
      } else {
        language.completed.complete((app: 'ko', system: 'en'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(StartupScreen), findsNothing);
      final context = tester.element(find.byType(DeskHome));
      expect(
        Localizations.localeOf(context).languageCode,
        failLanguage ? 'en' : 'ko',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('failed restore can retry without exposing an empty room', (
    tester,
  ) async {
    await _configure(tester);
    final failed = Completer<FocusState>();
    final store = _ControlledStore()..nextLoad = failed.future;
    await tester.pumpWidget(
      FocusFriendApp(engine: SessionEngine(store), locale: const Locale('ko')),
    );
    failed.completeError(StateError('storage unavailable'));
    await tester.pumpAndSettle();
    expect(find.byType(StartupScreen), findsOneWidget);
    expect(find.byType(StartupLoadingDots), findsNothing);
    expect(find.byType(DeskNavigation), findsNothing);
    expect(find.text('다시 확인'), findsOneWidget);

    final retry = Completer<FocusState>();
    store.nextLoad = retry.future;
    await tester.tap(find.text('다시 확인'));
    await tester.pump();
    expect(find.byType(StartupLoadingDots), findsOneWidget);
    expect(find.text('다시 확인'), findsNothing);
    retry.complete(FocusState());
    await tester.pumpAndSettle();
    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(DeskHome), findsOneWidget);
    expect(store.commits, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resume keeps the room visible during a refresh', (tester) async {
    await _configure(tester);
    final store = _ControlledStore();
    await tester.pumpWidget(
      FocusFriendApp(engine: SessionEngine(store), locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final refresh = Completer<FocusState>();
    store.nextLoad = refresh.future;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(DeskHome), findsOneWidget);
    refresh.complete(FocusState());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup stays readable with large text and reduced motion', (
    tester,
  ) async {
    await _configure(tester);
    tester.view.physicalSize = const Size(568, 320);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StartupLoadingDots), findsOneWidget);
      final opacity = tester
          .widget<Opacity>(find.byKey(const ValueKey('startup-dot-1')))
          .opacity;
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('startup-dot-1')))
            .opacity,
        opacity,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
