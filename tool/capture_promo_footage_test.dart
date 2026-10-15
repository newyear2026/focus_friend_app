// Render promotional footage using the real app and an isolated memory store.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  for (final mode in [SessionMode.focus, SessionMode.rest]) {
    testWidgets('render isolated Korean promo footage: ${mode.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (name, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(name)..addFont(rootBundle.load(path))).load();
      }
      var now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
      final store = MemoryStore()
        ..raw = FocusState(
          dailyFocus: {
            '2026-10-14': const DailyFocus(milliseconds: 50 * 60000, count: 2),
          },
          unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
        ).encode();
      final engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      await engine.start(
        Duration(minutes: mode == SessionMode.focus ? 25 : 5),
        mode: mode,
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DeskIllustration));
        for (final asset in [
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
          RestAnimation.asset,
          RestAnimation.inbetweensAsset,
          'assets/images/rest/closed-book.png',
          'assets/images/immersive/room-evening.png',
          for (final prop in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$prop.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      await tester.pump();
      await tester.pump();
      final folder = Directory(
        '/private/tmp/focus-promo-2026-10-14/${mode.name}',
      )..createSync(recursive: true);
      final count = mode == SessionMode.focus ? 192 : 120;
      for (var frame = 0; frame < count; frame++) {
        if (frame > 0) {
          now += 83;
          await tester.pump(const Duration(microseconds: 83334));
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${folder.path}/frame-${frame.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(engine.state.active!.mode, mode);
      expect(engine.state.history, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
