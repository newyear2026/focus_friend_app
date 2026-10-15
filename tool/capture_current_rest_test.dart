import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import '../test/session_engine_test.dart' show MemoryStore;

// Capture the current app widgets without accessing the installed app's data.
void main() {
  testWidgets('capture the current rest scene and its ten-second tea loop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final (name, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
    final now = DateTime(2026, 10, 10, 18).millisecondsSinceEpoch;
    final store = MemoryStore()
      ..raw = FocusState(
        unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
      ).encode();
    final engine = SessionEngine(store, clock: () => now);
    await engine.restore();
    await engine.start(const Duration(minutes: 5), mode: SessionMode.rest);
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
        'assets/images/immersive/room-evening.png',
        for (final prop in ['plant', 'mug', 'lamp'])
          'assets/images/immersive/reward-$prop.png',
        RestAnimation.asset,
        RestAnimation.inbetweensAsset,
        'assets/images/rest/closed-book.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    final frames = Directory('/private/tmp/focus-current-rest-preview')
      ..createSync(recursive: true);
    final output = Directory('docs/design/current-rest-motion')
      ..createSync(recursive: true);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    await tester.pump();
    // Establish the ticker's zero before capturing the first pose.
    await tester.pump();
    final metadata = <Map<String, Object>>[];
    for (var tick = 0; tick <= RestAnimation.cycleTicks; tick++) {
      if (tick > 0) {
        await tester.pump(const Duration(microseconds: 83334));
      }
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(RestCompanion),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as RestCompanionPainter;
      expect(painter.atlas, isNotNull);
      expect(painter.inbetweens, isNotNull);
      expect(painter.frame, RestAnimation.timeline[tick % 120]);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${frames.path}/frame-${tick.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        if (tick == 0) {
          await File(
            '${output.path}/rest.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
        }
        image.dispose();
      });
      metadata.add({'tick': tick, 'frame': painter.frame});
    }
    File(
      '${output.path}/rendered-frames.json',
    ).writeAsStringSync(jsonEncode(metadata));
    expect(metadata.map((entry) => entry['frame']).toSet().length, 14);
    expect(metadata.last['frame'], 0);
    expect(engine.state.active!.mode, SessionMode.rest);
    expect(engine.state.history, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
