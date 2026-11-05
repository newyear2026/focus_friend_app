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

// Review the actual room composition without touching the installed app's data.
void main() {
  const stage = String.fromEnvironment(
    'LAMP_CAPTURE_STAGE',
    defaultValue: 'after',
  );
  const outputPath = String.fromEnvironment(
    'PROP_CAPTURE_OUTPUT',
    defaultValue: 'docs/design/redpanda-lamp-placement-v1',
  );
  const completedMinutes = int.fromEnvironment(
    'PROP_CAPTURE_MINUTES',
    defaultValue: 75,
  );
  const unlockedItems = String.fromEnvironment(
    'PROP_CAPTURE_UNLOCKS',
    defaultValue: 'plant,mug',
  );
  testWidgets(
    'capture desk prop placement across screen sizes, light and rest',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (font, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(font)..addFont(rootBundle.load(path))).load();
      }
      var now = DateTime(2026, 11, 3, 18).millisecondsSinceEpoch;
      final engine = SessionEngine(
        MemoryStore()
          ..raw = FocusState(
            completedMs: completedMinutes * 60000,
            completedCount: completedMinutes ~/ 25,
            unlocks: {
              for (final item in unlockedItems.split(','))
                if (item.isNotEmpty) item: now - 1,
            },
          ).encode(),
        clock: () => now,
      );
      final appKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: appKey,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(DeskIllustration));
      await tester.runAsync(() async {
        for (final asset in [
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
          ReferenceCompanion.asset,
          RestAnimation.asset,
          RestAnimation.inbetweensAsset,
          'assets/images/rest/closed-book.png',
          for (final period in ['morning', 'day', 'evening', 'night'])
            'assets/images/immersive/room-$period.png',
          for (final prop in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$prop.png',
          for (final tab in ['desk', 'records', 'settings'])
            'assets/images/immersive/nav-$tab.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      final output = Directory(outputPath)..createSync(recursive: true);
      for (final (height, hour, name) in [
        (844.0, 18, 'evening-tall'),
        (700.0, 18, 'evening-compact'),
        (844.0, 7, 'morning'),
        (844.0, 12, 'day'),
        (844.0, 22, 'night'),
        (844.0, 22, 'rest-night'),
      ]) {
        tester.view.physicalSize = Size(390, height);
        now = DateTime(2026, 11, 3, hour).millisecondsSinceEpoch;
        if (name == 'rest-night') {
          await engine.start(
            const Duration(minutes: 5),
            mode: SessionMode.rest,
          );
        }
        await tester.pump(const Duration(minutes: 1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final (label, boundary) in [
          (
            'app',
            appKey.currentContext!.findRenderObject()! as RenderRepaintBoundary,
          ),
          (
            'scene',
            tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('study-scene')),
            ),
          ),
        ]) {
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${output.path}/$stage-$name-$label.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
