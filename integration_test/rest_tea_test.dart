import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

class TeaStore implements StateStore {
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
  testWidgets('Android tea break animates, pauses, resumes and completes', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(TeaStore(), clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 25));
    now += 25 * 60000;
    await engine.complete(engine.state.active!.id);
    final key = GlobalKey();
    final folder = Directory('${Directory.systemTemp.path}/rest-tea-preview');
    await folder.create(recursive: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${folder.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    RestCompanionPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(RestCompanion),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as RestCompanionPainter;
    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(find.byType(ReferenceCompanion), findsNothing);
    expect(painter().atlas, isNotNull);
    expect(painter().inbetweens, isNotNull);
    await File('${folder.path}/motion-ready').writeAsString('ready');
    final seen = <int>{};
    final start = DateTime.now();
    while (DateTime.now().difference(start).inSeconds < 20) {
      now += 100;
      await tester.pump(const Duration(milliseconds: 100));
      final pose = painter().frame;
      if ([0, 5, 12, 13].contains(pose) && seen.add(pose)) {
        await capture('native-pose-$pose');
      }
    }
    expect(seen, containsAll([0, 5, 12, 13]));
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pumpAndSettle();
    final held = painter().elapsed;
    final remaining = engine.state.active!.remaining(now);
    await capture('native-paused-a');
    now += 2000;
    await tester.pump(const Duration(seconds: 2));
    await capture('native-paused-b');
    expect(painter().elapsed, held);
    expect(engine.state.active!.remaining(now), remaining);
    await tester.tap(find.text('이어서 쉬기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(painter().elapsed, greaterThan(held));
    now += 5 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('휴식 완료'), findsOneWidget);
    expect(engine.state.completedCount, 1);
    expect(
      tester.widget<RestCompanion>(find.byType(RestCompanion)).animate,
      false,
    );
    await capture('native-completed');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(engine.state.active, isNull);
    expect(find.byType(RestCompanion), findsNothing);
    expect(find.byType(ReferenceCompanion), findsOneWidget);
    expect(find.text('오늘의 집중 '), findsOneWidget);
    await capture('native-returned-home');
    expect(tester.takeException(), isNull);
    await File('${folder.path}/verified').writeAsString('passed');
    const exportSeconds = int.fromEnvironment(
      'TEA_EXPORT_SECONDS',
      defaultValue: 15,
    );
    await Future<void>.delayed(const Duration(seconds: exportSeconds));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
