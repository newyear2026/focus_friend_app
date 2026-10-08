import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/desk_home.dart';
import 'session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets('pose interpolation preserves opaque character pixels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final source = ui.PictureRecorder();
      Canvas(source).drawRect(
        const Rect.fromLTWH(0, 0, 8, 4),
        Paint()..color = Colors.orange,
      );
      final sourcePicture = source.endRecording();
      final sheet = await sourcePicture.toImage(8, 4);
      sourcePicture.dispose();
      final output = ui.PictureRecorder();
      StudyCompanionPainter(
        sheet,
        .88,
      ).paint(Canvas(output), const Size(32, 32));
      final picture = output.endRecording();
      final result = await picture.toImage(32, 32);
      picture.dispose();
      final pixels = await result.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels!.getUint8((16 * 32 + 16) * 4 + 3), 255);
      result.dispose();
      sheet.dispose();
    });
  });

  test('writing cycle reviews the notes before turning a page', () {
    expect(StudyMotion.sample(1).current, 2);
    expect(StudyMotion.sample(2).current, 3);
    expect(StudyMotion.sample(17).current, 4);
    expect(StudyMotion.sample(19.4).current, 5);
    expect(StudyMotion.sample(20.5).current, 6);
    expect(StudyMotion.sample(21.5).current, 7);
    expect(StudyMotion.sample(22.5).current, 1);
    expect(StudyMotion.sample(25).current, 2);
  });

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

  testWidgets('same home scene animates, pauses and resumes with the timer', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(FocusFriendApp(engine: engine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final scene = tester.element(find.byType(DeskIllustration));
    final position = tester.getRect(find.byKey(const ValueKey('study-scene')));
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.element(find.byType(DeskIllustration)), same(scene));
    expect(tester.getRect(find.byKey(const ValueKey('study-scene'))), position);
    expect(find.text('나의 책상'), findsOneWidget);
    expect(find.text('차근차근, 함께 써 내려가요'), findsOneWidget);
    StudyCompanionPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(StudyCompanion),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as StudyCompanionPainter;
    await tester.pump(const Duration(seconds: 4));
    expect(painter().seconds, greaterThan(0));
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final stoppedPose = painter().seconds;
    expect(painter().resting, isTrue);
    final remaining = engine.state.active!.remainingMs;
    now += 30000;
    await tester.pump(const Duration(seconds: 3));
    expect(painter().seconds, stoppedPose);
    expect(engine.state.active!.remainingMs, remaining);
    await tester.tap(find.text('이어서 집중'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(painter().seconds, isNot(stoppedPose));
    expect(engine.state.active!.status, SessionStatus.running);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'idle room changes at local boundary and refreshes after resume',
    (tester) async {
      var now = DateTime(2026, 10, 7, 19, 59).millisecondsSinceEpoch;
      final engine = SessionEngine(MemoryStore(), clock: () => now);
      await tester.pumpWidget(FocusFriendApp(engine: engine));
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
      await tester.pumpWidget(FocusFriendApp(engine: engine));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      StudyCompanionPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(StudyCompanion),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as StudyCompanionPainter;
      final pose = painter().seconds;
      now += 10000;
      await tester.pump(const Duration(seconds: 10));
      expect(painter().seconds, pose);
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
    await tester.pumpWidget(FocusFriendApp(engine: engine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('랫서팬더가 골라주기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active, isNull);
    expect(
      tester.widget<DeskHome>(find.byType(DeskHome)).minutes,
      anyOf(25, 50),
    );
    await tester.tap(find.text('50분'));
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
      await tester.pumpWidget(FocusFriendApp(engine: engine));
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
    await tester.pumpWidget(FocusFriendApp(engine: engine));
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
    await tester.pumpWidget(FocusFriendApp(engine: engine));
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
      await tester.pumpWidget(FocusFriendApp(engine: engine));
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
