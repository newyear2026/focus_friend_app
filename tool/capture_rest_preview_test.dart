import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

class PreviewStore implements StateStore {
  FocusState value = FocusState();
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (expectedRevision != value.revision) throw StateError('revision');
    value = next.copy();
  }
}

// Render the real widgets without touching the installed Android app or its DB.
void main() {
  testWidgets('capture current rest and rest-completed screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1572);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final text = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
    var now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(PreviewStore(), clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 25));
    now += 25 * 60000;
    await engine.complete(engine.state.active!.id);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FocusFriendApp(engine: engine),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DeskIllustration));
    await tester.runAsync(() async {
      for (final path in [
        'assets/images/storybook/room-day.png',
        'assets/images/redpanda-study-animation.png',
        'assets/images/storybook/reward-plant.png',
        'assets/images/rest/redpanda-tea-sheet.png',
        'assets/images/rest/closed-book.png',
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('docs/design/rest-preview');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.tap(find.text('5분 휴식 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    now += 28 * 1000;
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('04:32'), findsOneWidget);
    expect(engine.state.active!.mode, SessionMode.rest);
    final scene = tester.widget<DeskIllustration>(
      find.byType(DeskIllustration),
    );
    expect(scene.studying, false);
    expect(scene.resting, true);
    expect(scene.animate, true);
    await capture('rest-running');
    now += 272 * 1000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.completed);
    expect(find.text('휴식 완료 · '), findsOneWidget);
    expect(engine.state.completedCount, 1);
    await capture('rest-completed');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
