import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'capture calm motion in the full app, including pause and resume',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final (name, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(name)..addFont(rootBundle.load(path))).load();
      }
      final now = DateTime(2026, 10, 9, 18).millisecondsSinceEpoch;
      final store = MemoryStore()
        ..raw = FocusState(
          dailyFocus: {
            '2026-10-09': const DailyFocus(milliseconds: 50 * 60000, count: 2),
          },
          unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
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
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DeskIllustration));
        for (final asset in [
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
          'assets/images/immersive/room-evening.png',
          for (final prop in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$prop.png',
          for (final tab in ['desk', 'records', 'settings'])
            'assets/images/immersive/nav-$tab.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.pump();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/design/calm-connected-motion/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      await capture('home-evening');
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await capture('focusing');
      await tester.pump(const Duration(seconds: 37));
      await capture('turning-page');
      await tester.tap(find.text('잠시 멈추기'));
      await tester.pumpAndSettle();
      await capture('paused');
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('이어서 집중'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await capture('fresh-page');
      expect(engine.state.history, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
