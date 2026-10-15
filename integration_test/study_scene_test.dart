import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';

/// An isolated store: visual verification cannot change the user's records.
class ScenePreviewStore implements StateStore {
  FocusState value = FocusState();
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (value.revision != expectedRevision) throw StateError('revision');
    value = next.copy();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('connected writing survives pause, resume and completion', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 8, 7).millisecondsSinceEpoch;
    final engine = SessionEngine(ScenePreviewStore(), clock: () => now);
    final captureKey = GlobalKey();
    final captureTimes = <String, int>{};
    final folder = Directory('${Directory.systemTemp.path}/study-cel-preview');
    ReferenceCompanionPainter characterPainter() =>
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('reference-companion-cels')),
                )
                .painter!
            as ReferenceCompanionPainter;
    await folder.create(recursive: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pump();
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${folder.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      captureTimes[name] = DateTime.now().millisecondsSinceEpoch;
    }

    for (final (hour, name) in [
      (7, 'morning'),
      (12, 'day'),
      (18, 'evening'),
      (22, 'night'),
    ]) {
      now = DateTime(2026, 10, 8, hour).millisecondsSinceEpoch;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await capture('home-$name');
    }
    now = DateTime(2026, 10, 8, 18).millisecondsSinceEpoch;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final scene = tester.element(find.byType(DeskIllustration));
    final character = tester.element(find.byType(ReferenceCompanion));
    final sceneRect = tester.getRect(find.byKey(const ValueKey('study-scene')));
    await capture('focus-before-start');
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await capture('focus-start-transition');
    for (
      var i = 0;
      i < 30 &&
          !tester
              .widget<ReferenceCompanion>(find.byType(ReferenceCompanion))
              .animate;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.element(find.byType(DeskIllustration)), same(scene));
    expect(tester.element(find.byType(ReferenceCompanion)), same(character));
    expect(
      tester.getRect(find.byKey(const ValueKey('study-scene'))),
      sceneRect,
    );
    expect(
      tester
          .widget<ReferenceCompanion>(find.byType(ReferenceCompanion))
          .animate,
      isTrue,
    );
    await File('${folder.path}/motion-ready').writeAsString('ready');
    await capture('writing');

    final connectedCharacter = find.byKey(
      const ValueKey('reference-companion-cels'),
    );
    expect(connectedCharacter, findsOneWidget);
    expect(find.byKey(const ValueKey('writing-paw-motion')), findsNothing);
    final observedFrames = <int>{};
    for (
      var tick = 0;
      tick < ReferenceStudyAnimation.writingCycleTicks * 6;
      tick++
    ) {
      await tester.pump(const Duration(milliseconds: 42));
      observedFrames.add(characterPainter().frame);
      if ([7, 17, 23, 35].contains(tick)) await capture('motion-$tick');
    }
    expect(observedFrames, {for (var i = 0; i < 6; i++) i});
    await capture('writing-resume');

    // Advance only the test clock to inspect the full-size app scene around
    // the authored page turn. No forced state is added to product code.
    var beforeTurnCaptured = false;
    var duringTurnCaptured = false;
    var afterTurnCaptured = false;
    for (var tick = 0; tick < ReferenceStudyAnimation.cycleTicks * 2; tick++) {
      await tester.pump(const Duration(microseconds: 83334));
      final pose = characterPainter();
      if (!pose.turningPage && !beforeTurnCaptured && tick > 10) {
        await capture('page-turn-before');
        beforeTurnCaptured = true;
      }
      if (pose.turningPage && pose.frame == 25 && !duringTurnCaptured) {
        await capture('page-turn-during');
        duringTurnCaptured = true;
      }
      if (duringTurnCaptured && !pose.turningPage && !afterTurnCaptured) {
        await capture('page-turn-after');
        afterTurnCaptured = true;
        break;
      }
    }
    expect(
      beforeTurnCaptured && duringTurnCaptured && afterTurnCaptured,
      isTrue,
    );

    await tester.tap(find.text('잠시 멈추기'));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.paused);
    expect(
      tester.widget<ReferenceCompanion>(find.byType(ReferenceCompanion)).paused,
      isTrue,
    );
    final remaining = engine.state.active!.remainingMs;
    final heldFrame = characterPainter().frame;
    await capture('paused-a');
    now += 2000;
    await tester.pump(const Duration(seconds: 2));
    await capture('paused-b');
    expect(engine.state.active!.remainingMs, remaining);
    expect(characterPainter().frame, heldFrame);
    await tester.tap(find.text('이어서 집중'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));
    expect(engine.state.active!.status, SessionStatus.running);
    expect(tester.element(find.byType(ReferenceCompanion)), same(character));
    expect(connectedCharacter, findsOneWidget);
    expect(characterPainter().frame, isNot(heldFrame));
    await capture('writing-next-cycle');

    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(engine.state.completedCount, 1);
    expect(characterPainter().frame, 0);
    expect(engine.state.unlocks.keys, contains('plant'));
    await capture('completed');
    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(find.byType(ReferenceCompanion), findsNothing);
    await capture('rest');
    await tester.tap(find.text('이번 시간 종료'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('종료하기'));
    await tester.pumpAndSettle();
    expect(engine.state.active, isNull);
    expect(find.byType(ReferenceCompanion), findsOneWidget);
    await capture('returned-home');
    expect(tester.takeException(), isNull);
    await File(
      '${folder.path}/capture-times.json',
    ).writeAsString(jsonEncode(captureTimes));
    const exportSeconds = int.fromEnvironment(
      'SCENE_EXPORT_SECONDS',
      defaultValue: 15,
    );
    await Future<void>.delayed(const Duration(seconds: exportSeconds));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
