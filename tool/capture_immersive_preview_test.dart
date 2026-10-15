import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets('capture immersive home, connected flow and secondary screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final (name, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
    var now = DateTime(2026, 10, 8, 18).millisecondsSinceEpoch;
    final store = MemoryStore()
      ..raw = FocusState(
        completedMs: 120 * 60000,
        completedCount: 4,
        unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
        dailyFocus: {
          '2026-10-08': const DailyFocus(milliseconds: 50 * 60000, count: 2),
        },
      ).encode();
    final engine = SessionEngine(store, clock: () => now);
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
      for (final asset in [
        for (final period in ['morning', 'day', 'evening', 'night'])
          'assets/images/immersive/room-$period.png',
        for (final prop in ['plant', 'mug', 'lamp'])
          'assets/images/immersive/reward-$prop.png',
        for (final tab in ['desk', 'records', 'settings'])
          'assets/images/immersive/nav-$tab.png',
        ReferenceCompanion.asset,
        ReferenceStudyAnimation.bodyAsset,
        ReferenceStudyAnimation.notebookAsset,
        RestAnimation.asset,
        RestAnimation.inbetweensAsset,
        'assets/images/rest/closed-book.png',
        'assets/images/companion-portrait.png',
        for (final sound in ['rain', 'forest', 'fire'])
          'assets/images/sound-$sound.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('docs/design/immersive-room')
          ..createSync(recursive: true);
        await File(
          '${folder.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final (hour, period) in [
      (7, 'morning'),
      (12, 'day'),
      (18, 'evening'),
      (22, 'night'),
    ]) {
      now = DateTime(2026, 10, 8, hour).millisecondsSinceEpoch;
      await tester.pump(const Duration(seconds: 1));
      await capture('home-$period');
    }
    now = DateTime(2026, 10, 8, 18).millisecondsSinceEpoch;
    await tester.pump(const Duration(seconds: 1));
    for (final (index, name) in [(2, 'records'), (3, 'settings')]) {
      await tester.tap(find.byKey(ValueKey('desk-navigation-$index')));
      await capture(name);
    }
    await tester.tap(find.text('목표와 다짐'));
    await capture('goal');
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-sound')));
    await capture('sound');
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(const ValueKey('study-scene')));
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await capture('focusing');
    expect(engine.state.active!.durationMs, 25 * 60000);
    expect(tester.getRect(find.byKey(const ValueKey('study-scene'))), before);
    now += 30000;
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('잠시 멈추기'));
    await capture('paused');
    await tester.tap(find.text('이어서 집중'));
    await tester.pumpAndSettle();
    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await capture('completed');
    expect(engine.state.completedCount, 5);
    await tester.tap(find.text('5분 휴식 시작'));
    await capture('rest');
    final restPaint =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(RestCompanion),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as RestCompanionPainter;
    expect(
      restPaint.atlas,
      isNotNull,
      reason: 'The tea character must be loaded in the captured scene',
    );
    expect(tester.getSize(find.byType(RestCompanion)).width, greaterThan(0));
    expect(engine.state.active!.mode, SessionMode.rest);
    await tester.tap(find.text('이번 시간 종료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료하기'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(640, 1280);
    await capture('compact');
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('start-focus')));
    await capture('compact-large-text');
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await tester.pumpAndSettle();
    expect(engine.state.active, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
