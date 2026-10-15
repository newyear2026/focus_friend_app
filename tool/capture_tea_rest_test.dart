import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

class TeaPreviewStore implements StateStore {
  FocusState value = FocusState();
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (expectedRevision != value.revision) throw StateError('revision');
    value = next.copy();
  }
}

// This renderer exercises the real app widgets with an isolated memory store.
void main() {
  testWidgets('render tea loop and verify the complete rest flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1572);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    var now = DateTime(2026, 10, 8, 12).millisecondsSinceEpoch;
    final engine = SessionEngine(TeaPreviewStore(), clock: () => now);
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
        'assets/images/storybook/reward-plant.png',
        'assets/images/rest/closed-book.png',
        RestAnimation.asset,
        RestAnimation.inbetweensAsset,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pumpAndSettle();
    final folder = Directory('docs/design/rest-tea-14-frames');
    final frames = Directory('/private/tmp/focus-tea-14-frames');
    await tester.runAsync(() async {
      await folder.create(recursive: true);
      await frames.create(recursive: true);
    });
    Future<void> capture(String path) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
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
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(find.byType(ReferenceCompanion), findsNothing);
    expect(painter().atlas, isNotNull);
    expect(painter().inbetweens, isNotNull);
    final captured = <int>{};
    for (var index = 0; index < 300; index++) {
      if (index > 0) {
        now += 33;
        await tester.pump(const Duration(microseconds: 33334));
      }
      await capture('${frames.path}/${index.toString().padLeft(3, '0')}.png');
      if (captured.add(painter().frame)) {
        await capture('${folder.path}/pose-${painter().frame}.png');
      }
    }
    expect(captured, containsAll(List.generate(14, (index) => index)));
    await tester.tap(find.text('잠시 멈추기'));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.paused);
    final held = painter().elapsed;
    final remaining = engine.state.active!.remaining(now);
    await capture('${folder.path}/paused-a.png');
    now += 2000;
    await tester.pump(const Duration(seconds: 2));
    await capture('${folder.path}/paused-b.png');
    expect(painter().elapsed, held);
    expect(engine.state.active!.remaining(now), remaining);
    await tester.tap(find.text('이어서 쉬기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(painter().elapsed, greaterThan(held));
    // Decorative motion and rest time never create extra focus records.
    now += 5 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.completed);
    expect(engine.state.completedCount, 1);
    expect(find.text('휴식 완료 · '), findsOneWidget);
    expect(
      tester.widget<RestCompanion>(find.byType(RestCompanion)).animate,
      isFalse,
    );
    await capture('${folder.path}/completed.png');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
