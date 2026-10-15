import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/goal_editor.dart';
import 'session_engine_test.dart' show MemoryStore;

class RecordingScreen extends ScreenAwake {
  final calls = <bool>[];
  @override
  Future<void> set(bool on) async => calls.add(on);
}

void main() {
  test(
    'daily ledger survives history pruning and restart without duplicate stamps',
    () async {
      var now = DateTime(2026, 10, 1, 12).millisecondsSinceEpoch;
      final store = MemoryStore();
      var engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      for (var i = 0; i < 105; i++) {
        await engine.start(const Duration(minutes: 25));
        final id = engine.state.active!.id;
        now += 25 * 60000;
        await engine.complete(id);
        await engine.complete(id);
        await engine.dismiss(id);
        if (i == 0) now = DateTime(2026, 10, 2, 0).millisecondsSinceEpoch;
      }
      engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      expect(engine.state.history.length, 100);
      expect(engine.state.dailyFocus['2026-10-01']!.count, 1);
      expect(
        engine.state.dailyFocus.values.fold<int>(
          0,
          (sum, day) => sum + day.count,
        ),
        105,
      );
      expect(
        engine.state.dailyFocus.values.fold<int>(
          0,
          (sum, day) => sum + day.milliseconds,
        ),
        105 * 25 * 60000,
      );
    },
  );

  test(
    'old save migrates retained completed sessions only and preserves settings on failure',
    () async {
      final now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
      final record = Session(
        id: 'old',
        mode: SessionMode.focus,
        status: SessionStatus.completed,
        startedAt: now - 1500000,
        durationMs: 1500000,
        remainingMs: 0,
        actualMs: 1500000,
        finishedAt: now,
      );
      final old =
          FocusState(
              history: [record],
              completedMs: 1500000,
              completedCount: 1,
            ).toJson()
            ..remove('dailyFocus')
            ..remove('goal')
            ..remove('sound');
      final store = MemoryStore()..raw = jsonEncode(old);
      var engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      expect(engine.state.dailyFocus['2026-10-08']!.count, 1);
      const goal = FocusGoal(name: '시험', date: '2026-11-07', message: '한 걸음씩');
      await engine.saveGoal(goal);
      await engine.saveSound(
        const SoundPreferences(
          sound: 'forest',
          volume: .7,
          enabled: true,
          stopAtEnd: false,
        ),
      );
      store.failBefore = true;
      await expectLater(engine.saveGoal(null), throwsStateError);
      engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      expect(engine.state.goal!.name, '시험');
      expect(engine.state.sound.sound, 'forest');
      expect(engine.state.sound.volume, .7);
      expect(engine.state.sound.stopAtEnd, false);
      expect(engine.state.dailyFocus['2026-10-08']!.count, 1);
    },
  );

  test(
    'calendar D-day uses calendar dates across year and daylight-saving boundaries',
    () {
      expect(
        const FocusGoal(
          name: '시험',
          date: '2027-01-01',
        ).countdown(DateTime(2026, 12, 31, 23, 59)),
        'D-1',
      );
      expect(
        const FocusGoal(
          name: '시험',
          date: '2026-10-08',
        ).countdown(DateTime(2026, 10, 8, 23)),
        'D-day',
      );
      expect(
        const FocusGoal(
          name: '시험',
          date: '2026-10-07',
        ).countdown(DateTime(2026, 10, 8)),
        'D+1',
      );
    },
  );

  testWidgets('keep screen on holds only while a focus or rest timer runs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    final screen = RecordingScreen();
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        screen: screen,
        locale: const Locale('ko'),
      ),
    );
    await settle();
    expect(screen.calls, [false]);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await settle();
    expect(find.text('평소처럼 꺼져요 · 타이머는 계속 가요'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('keep-screen-on')));
    await tester.tap(find.byKey(const ValueKey('keep-screen-on')));
    await settle();
    expect(engine.state.keepScreenOn, isTrue);
    expect(find.text('집중·휴식 중에는 화면을 켜 둬요'), findsOneWidget);
    // Turning the option on while idle must not hold the screen yet.
    expect(screen.calls, [false]);

    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    await settle();
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await settle();
    expect(screen.calls.last, isTrue);
    await tester.tap(find.text('잠시 멈추기'));
    await settle();
    expect(screen.calls.last, isFalse);
    await tester.tap(find.text('이어서 집중'));
    await settle();
    expect(screen.calls.last, isTrue);
    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await settle();
    expect(engine.state.active!.status, SessionStatus.completed);
    expect(screen.calls.last, isFalse);
    await tester.tap(find.text('5분 휴식 시작'));
    await settle();
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(screen.calls.last, isTrue);
    await tester.tap(find.text('이번 시간 종료'));
    await settle();
    await tester.tap(find.text('종료하기'));
    await settle();
    expect(engine.state.active, isNull);
    expect(screen.calls, [false, true, false, true, false, true, false]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'three tabs, calendar month, goal persistence and home shortcut',
    (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      final engine = SessionEngine(
        store,
        clock: () => DateTime(2026, 10, 8, 12).millisecondsSinceEpoch,
      );
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 10월'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('previous-month')));
      await tester.pumpAndSettle();
      expect(find.text('2026년 9월'), findsOneWidget);
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('목표와 다짐'));
      await tester.pumpAndSettle();
      expect(find.byType(GoalEditor), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('goal-name')), '자격증 시험');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-goal')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(engine.state.goal!.name, '자격증 시험');
      await tester.tap(find.text('책상'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-goal')));
      await tester.pumpAndSettle();
      expect(find.byType(GoalEditor), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('goal-name')))
            .controller!
            .text,
        '자격증 시험',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = SessionEngine(store);
      await restored.restore();
      expect(restored.state.goal!.name, '자격증 시험');
    },
  );

  testWidgets(
    'sound selection saves and dismissing draft does not change saved settings',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = SessionEngine(MemoryStore());
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-sound')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sound-forest')));
      await tester.ensureVisible(find.byKey(const ValueKey('save-sound')));
      await tester.tap(find.byKey(const ValueKey('save-sound')));
      await tester.pumpAndSettle();
      expect(engine.state.sound.sound, 'forest');
      expect(engine.state.sound.enabled, true);
      await tester.tap(find.byKey(const ValueKey('open-sound')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sound-fire')));
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(engine.state.sound.sound, 'forest');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'small screen and large text keep records, sound, and goal actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final engine = SessionEngine(
        MemoryStore(),
        clock: () => DateTime(2026, 8, 8, 12).millisecondsSinceEpoch,
      );
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      expect(find.text('2026년 8월'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('목표와 다짐'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('save-goal')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('goal-name')),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.enterText(
        find.byKey(const ValueKey('goal-name')),
        '자격증 시험을 위한 작은 공부',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      expect(engine.state.goal!.name, '자격증 시험을 위한 작은 공부');
      expect(tester.takeException(), isNull, reason: 'after saving goal');
      await tester.tap(find.text('책상'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home with long goal');
      await tester.tap(find.byKey(const ValueKey('open-sound')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'sound large text');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-sound')),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('save-sound')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
