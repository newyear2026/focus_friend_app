import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/desk_home.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'companion_art.dart';
import 'session_engine_test.dart' show MemoryStore;

/// The default test font draws every glyph as a square, which makes Latin text
/// about twice as wide as on a phone, so layout checks use the real font. It
/// has no kanji; those fall back to a full-width glyph as on a device.
Future<void> loadAppFont() => (FontLoader(
  'Pretendard',
)..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();

void main() {
  test('local ambience boundaries include midnight and exact transitions', () {
    for (final (hour, minute, expected) in [
      (0, 0, RoomAmbience.night),
      (5, 29, RoomAmbience.night),
      (5, 30, RoomAmbience.morning),
      (7, 59, RoomAmbience.morning),
      (8, 0, RoomAmbience.day),
      (17, 29, RoomAmbience.day),
      (17, 30, RoomAmbience.evening),
      (19, 59, RoomAmbience.evening),
      (20, 0, RoomAmbience.night),
      (23, 59, RoomAmbience.night),
    ]) {
      expect(RoomAmbience.at(DateTime(2026, 10, 7, hour, minute)), expected);
    }
  });

  testWidgets('room and foreground books change ambience together', (
    tester,
  ) async {
    Widget scene(RoomAmbience ambience) => Localizations(
      locale: const Locale('ko'),
      delegates: AppLocalizations.localizationsDelegates,
      child: DeskIllustration(unlocked: const {}, ambience: ambience),
    );
    await tester.pumpWidget(scene(RoomAmbience.evening));
    await tester.pumpWidget(scene(RoomAmbience.night));
    await tester.pump(const Duration(seconds: 1));
    final fades = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: find.byKey(const ValueKey('study-scene')),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    // One incoming night room for the background and one for the books; the
    // outgoing evening copies stay opaque underneath.
    expect(fades, hasLength(2));
    for (final fade in fades) {
      expect(fade.opacity.value, closeTo(.5, .01));
      expect(fade.child!.key, const ValueKey(RoomAmbience.night));
    }
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('study-scene')),
        matching: find.byWidgetPredicate(
          (widget) => widget.key == const ValueKey(RoomAmbience.evening),
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('Settings language choice applies, persists and can go back', (
    tester,
  ) async {
    await loadAppFont();
    tester.platformDispatcher.localesTestValue = [const Locale('ko', 'KR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _MemoryLanguageStore(system: 'ko-KR');
    final engine = SessionEngine(
      MemoryStore(),
      clock: () => DateTime(2026, 10, 7, 12).millisecondsSinceEpoch,
    );
    Future<void> openLanguage() async {
      await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('open-language')));
      await tester.tap(find.byKey(const ValueKey('open-language')));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(FocusFriendApp(engine: engine, language: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    expect(find.text('시스템 설정 따르기 · 한국어'), findsOneWidget);
    await openLanguage();
    expect(find.text('지금 휴대폰 언어: 한국어'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pumpAndSettle();
    expect(store.app, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language changed to English'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A fresh start reads the saved choice back.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(FocusFriendApp(engine: engine, language: store));
    await tester.pumpAndSettle();
    expect(find.text('My desk'), findsOneWidget);

    await openLanguage();
    await tester.tap(find.byKey(const ValueKey('language-system')));
    await tester.pumpAndSettle();
    expect(store.app, isNull);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('언어를 바꿨어요 · 한국어'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('follows the device language and falls back to English', (
    tester,
  ) async {
    final engine = SessionEngine(
      MemoryStore(),
      clock: () => DateTime(2026, 10, 7, 12).millisecondsSinceEpoch,
    );
    await loadAppFont();
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final (device, title, start) in [
      (const Locale('ko', 'KR'), '나의 책상', '집중 시작'),
      (const Locale('en', 'US'), 'My desk', 'Start focus'),
      (const Locale('ja', 'JP'), 'わたしの机', '集中スタート'),
      (const Locale('es', 'MX'), 'Mi escritorio', 'Empezar'),
      // Not translated yet: English is the fallback, never Korean.
      (const Locale('de', 'DE'), 'My desk', 'Start focus'),
    ]) {
      tester.platformDispatcher.localesTestValue = [device];
      await tester.pumpWidget(FocusFriendApp(engine: engine));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(title), findsOneWidget, reason: '$device');
      expect(find.text(start), findsOneWidget, reason: '$device');
      await tester.pumpWidget(const SizedBox());
    }
  });

  for (final language in ['en', 'es', 'ja', 'ko']) {
    testWidgets('$language screens fit a small phone with larger text', (
      tester,
    ) async {
      await loadAppFont();
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final t = lookupAppLocalizations(Locale(language));
      final engine = SessionEngine(
        MemoryStore(),
        clock: () => DateTime(2026, 8, 8, 12).millisecondsSinceEpoch,
      );
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: Locale(language)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home');
      await tester.tap(find.byKey(const ValueKey('desk-navigation-2')));
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat.yMMMM(language).format(DateTime(2026, 8))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'records');
      await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text(t.quickFocusLabel(5)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'settings');
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.goalTitle));
      await tester.pumpAndSettle();
      expect(find.text(t.goalDefaultMessage), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'goal editor');
      await tester.tap(find.byTooltip(t.back));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-sound')));
      await tester.pumpAndSettle();
      expect(find.text(t.soundForestTitle), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'sound sheet');
      await tester.tap(find.byTooltip(t.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(t.captionFocusing(25)), findsOneWidget);
      expect(find.text(t.endThisSession), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'running timer');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'home character writes, holds on pause and settles on completion',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await precacheCompanionArt(tester);
      final scene = tester.element(find.byType(DeskIllustration));
      final position = tester.getRect(
        find.byKey(const ValueKey('study-scene')),
      );
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.element(find.byType(DeskIllustration)), same(scene));
      expect(
        tester.getRect(find.byKey(const ValueKey('study-scene'))),
        position,
      );
      expect(find.text('나의 책상'), findsOneWidget);
      expect(find.text('차근차근, 함께 써 내려가요'), findsOneWidget);
      final character = tester.element(find.byType(ReferenceCompanion));
      // The app must hand the running timer to the character as real motion.
      expect(
        await studyFramesDuring(tester, const Duration(seconds: 4)),
        hasLength(greaterThan(1)),
      );
      await tester.tap(find.text('잠시 멈추기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final held = studyFrame(tester);
      final remaining = engine.state.active!.remainingMs;
      now += 30000;
      expect(await studyFramesDuring(tester, const Duration(seconds: 3)), {
        held,
      });
      expect(engine.state.active!.remainingMs, remaining);
      await tester.tap(find.text('이어서 집중'));
      await tester.pump();
      expect(engine.state.active!.status, SessionStatus.running);
      expect(
        await studyFramesDuring(tester, const Duration(seconds: 2)),
        hasLength(greaterThan(1)),
      );
      expect(tester.element(find.byType(ReferenceCompanion)), same(character));
      now += engine.state.active!.remaining(now);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(engine.state.active!.status, SessionStatus.completed);
      expect(await studyFramesDuring(tester, const Duration(seconds: 2)), {0});
      expect(tester.element(find.byType(ReferenceCompanion)), same(character));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('leaving the app holds the writing pose until it returns', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 25));
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await precacheCompanionArt(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      await studyFramesDuring(tester, const Duration(seconds: 2)),
      hasLength(greaterThan(1)),
    );
    // Covered (notification shade, app switcher): frames still render.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final held = studyFrame(tester);
    expect(await studyFramesDuring(tester, const Duration(seconds: 5)), {held});
    // Fully backgrounded: no frames, so check where it picks up afterwards.
    final ink = studyPainter(tester).inkProgress;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    now += 20000;
    await tester.pump(const Duration(seconds: 20));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.status, SessionStatus.running);
    // Resumes from the held pose instead of skipping the 20 s spent away.
    expect(studyPainter(tester).inkProgress - ink, lessThan(.02));
    expect(
      await studyFramesDuring(tester, const Duration(seconds: 2)),
      hasLength(greaterThan(1)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a running timer redraws without copying the saved state', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 25));
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final snapshot = engine.state;
    expect(find.text('25:00'), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      now += 250;
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('24:55'), findsOneWidget);
    expect(engine.state, same(snapshot));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tea break plays from the app, holds on pause and resumes', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 25));
    now += 25 * 60000;
    await engine.complete(engine.state.active!.id);
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await precacheCompanionArt(tester);
    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(find.byType(ReferenceCompanion), findsNothing);
    final teaFrames = <int>{};
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      teaFrames.add(restPainter(tester).frame);
    }
    // The first 2.5 s hold the cup; the sip that follows must actually play.
    expect(teaFrames, hasLength(greaterThan(2)));
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final held = restPainter(tester).elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(restPainter(tester).elapsed, held);
    await tester.tap(find.text('이어서 쉬기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(restPainter(tester).elapsed, greaterThan(held));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'idle room changes at local boundary and refreshes after resume',
    (tester) async {
      var now = DateTime(2026, 10, 7, 19, 59).millisecondsSinceEpoch;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      DeskIllustration scene() =>
          tester.widget<DeskIllustration>(find.byType(DeskIllustration));
      expect(scene().ambience, RoomAmbience.evening);
      now += 60000;
      await tester.pump(const Duration(seconds: 1));
      expect(scene().ambience, RoomAmbience.night);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      now = DateTime(2026, 10, 8, 7).millisecondsSinceEpoch;
      await tester.pump(const Duration(seconds: 1));
      expect(scene().ambience, RoomAmbience.night);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scene().ambience, RoomAmbience.morning);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reduced motion keeps the character still while time counts down',
    (tester) async {
      var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await engine.restore();
      await engine.start(const Duration(minutes: 25));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await precacheCompanionArt(tester);
      await tester.pump();
      expect(find.byType(ReferenceCompanion), findsOneWidget);
      now += 10000;
      // With the art loaded, the cels are drawn but stay on the rest pose.
      expect(await studyFramesDuring(tester, const Duration(seconds: 10)), {0});
      // Nothing keeps animating in the background either.
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('24:50'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('today total excludes yesterday, stopped sessions, demo and rest', () {
    final today = DateTime(2026, 10, 7, 12);
    Session record(
      String id,
      DateTime finished,
      SessionMode mode,
      SessionStatus status,
      int minutes,
    ) => Session(
      id: id,
      mode: mode,
      status: status,
      startedAt: finished
          .subtract(Duration(minutes: minutes))
          .millisecondsSinceEpoch,
      durationMs: minutes * 60000,
      remainingMs: 0,
      actualMs: minutes * 60000,
      finishedAt: finished.millisecondsSinceEpoch,
    );
    final state = FocusState(
      history: [
        record('today', today, SessionMode.focus, SessionStatus.completed, 25),
        record(
          'midnight',
          DateTime(2026, 10, 7),
          SessionMode.focus,
          SessionStatus.completed,
          50,
        ),
        record(
          'yesterday',
          DateTime(2026, 10, 6, 23, 59),
          SessionMode.focus,
          SessionStatus.completed,
          50,
        ),
        record('stopped', today, SessionMode.focus, SessionStatus.stopped, 10),
        record('demo', today, SessionMode.demo, SessionStatus.completed, 1),
        record('rest', today, SessionMode.rest, SessionStatus.completed, 5),
      ],
    );
    expect(todayFocusMinutes(state, today), 75);
    expect(todayFocusMinutes(state, DateTime(2026, 10, 8)), 0);
  });

  testWidgets('duration choice starts the selected 50 minute session', (
    tester,
  ) async {
    final engine = SessionEngine(MemoryStore());
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('random-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active, isNull);
    expect(
      tester.widget<DeskHome>(find.byType(DeskHome)).minutes,
      anyOf(25, 50),
    );
    await tester.tap(find.text('50분'));
    await tester.pump();
    expect(find.text('50:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.durationMs, 50 * 60000);
    expect(find.text('50:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'first completion places plant once and waits for explicit action',
    (tester) async {
      var now = 1000;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('25:00'), findsOneWidget);
      expect(
        tester.widget<DeskIllustration>(find.byType(DeskIllustration)).animate,
        isTrue,
      );
      now += 1500000;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('첫 집중의 선물, 작은 화분을 놓았어요.'), findsOneWidget);
      expect(engine.state.completedCount, 1);
      expect(engine.state.unlocks.keys, contains('plant'));
      await tester.pump(const Duration(minutes: 5));
      expect(engine.state.active!.status, SessionStatus.completed);
      await tester.tap(find.text('확인'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<DeskIllustration>(find.byType(DeskIllustration)).unlocked,
        contains('plant'),
      );
      expect(find.text('나의 책상'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('today-focus'))).data,
        '25분',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('demo label and retryable storage error are visible', (
    tester,
  ) async {
    final store = MemoryStore();
    final engine = SessionEngine(store);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    store.failBefore = true;
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('다시 확인'), findsOneWidget);
    expect(engine.state.active, isNull);
    await tester.tap(find.text('다시 확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('설정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('1분 체험 · 기록과 보상 없이 둘러보기'));
    await tester.pump();
    await tester.tap(find.text('1분 체험 · 기록과 보상 없이 둘러보기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('01:00'), findsOneWidget);
    expect(engine.state.active!.mode, SessionMode.demo);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('small screen and large text keep controls reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final engine = SessionEngine(MemoryStore());
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const ValueKey('start-focus')));
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('잠시 멈추기'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'background ticker preserves pending alarm state until foreground recovery',
    (tester) async {
      var now = 1000;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await engine.restore();
      await engine.start(const Duration(seconds: 30));
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now += 60000;
      await tester.pump(const Duration(seconds: 1));
      expect(engine.state.active!.status, SessionStatus.running);
      expect(engine.state.completedCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(engine.state.active!.status, SessionStatus.completed);
      expect(engine.state.completedCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _MemoryLanguageStore implements AppLanguageStore {
  _MemoryLanguageStore({required this.system});
  final String system;
  String? app;
  @override
  Future<({String? app, String? system})> load() async =>
      (app: app, system: system);
  @override
  Future<void> save(String? tag) async => app = tag;
}
