import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

/// Separate in-memory fixture: this test never opens the user's SQLite store.
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
  testWidgets('home room, four local periods and red panda writing motion', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 8, 7).millisecondsSinceEpoch;
    final engine = SessionEngine(ScenePreviewStore(), clock: () => now);
    final captureKey = GlobalKey();
    final captureTimes = <String, int>{};
    final folder = Directory(
      '${Directory.systemTemp.path}/study-scene-preview',
    );
    await folder.create(recursive: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: FocusFriendApp(engine: engine),
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
    now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final scene = tester.element(find.byType(DeskIllustration));
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.element(find.byType(DeskIllustration)), same(scene));
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
    Future<void> capturePose(int frame, String name) async {
      final deadline = DateTime.now().add(const Duration(seconds: 32));
      while (true) {
        final pose = StudyMotion.sample(painter().seconds);
        if (pose.current == frame && pose.blend == 1) break;
        expect(
          DateTime.now().isBefore(deadline),
          isTrue,
          reason: 'Animation did not reach $name',
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await capture(name);
    }

    await capturePose(2, 'writing');
    await capturePose(4, 'reviewing');
    await capturePose(6, 'turning-page');
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.paused);
    await capture('paused');
    await tester.tap(find.text('이어서 집중'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(engine.state.active!.status, SessionStatus.running);
    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(engine.state.completedCount, 1);
    expect(engine.state.unlocks.keys, contains('plant'));
    await capture('completed');
    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pumpAndSettle();
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(
      tester.widget<DeskIllustration>(find.byType(DeskIllustration)).animate,
      isFalse,
    );
    await capture('rest');
    await tester.tap(find.text('이번 시간 종료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료하기'));
    await tester.pumpAndSettle();
    expect(engine.state.active, isNull);
    await capture('returned-home');
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print('Scene evidence: ${folder.path}');
    await File(
      '${folder.path}/capture-times.json',
    ).writeAsString(jsonEncode(captureTimes));
    // Optional export window for adb to copy screenshots before Flutter removes this test APK.
    const exportSeconds = int.fromEnvironment('SCENE_EXPORT_SECONDS');
    if (exportSeconds > 0) {
      await Future<void>.delayed(const Duration(seconds: exportSeconds));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
