import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/startup_companion.dart';
import 'package:focus_friend_app/startup_screen.dart';

import '../test/session_engine_test.dart' show MemoryStore;
import '../test/startup_companion_test.dart' show loadStartupArt;
import '../test/widget_test.dart' show loadAppFont;

class _LoadingStore extends MemoryStore {
  final loaded = Completer<FocusState>();
  @override
  Future<FocusState> load() => loaded.future;
}

void main() {
  testWidgets('capture two complete startup hugs', (tester) async {
    await loadAppFont();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FocusFriendApp(
          engine: SessionEngine(_LoadingStore()),
          locale: const Locale('ko'),
        ),
      ),
    );
    await loadStartupArt(tester);
    final context = tester.element(find.byType(StartupScreen));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(StartupScreen.backgroundAsset),
        context,
      ),
    );
    await tester.pump();
    final output = Directory('docs/design/startup-book-hug-v2')
      ..createSync(recursive: true);
    final frames = Directory('/private/tmp/deskmate-startup-book-hug-v2-frames')
      ..createSync(recursive: true);
    // Two 5.4s hugs also complete six 1.8s loading-dot cycles. Capture 50fps
    // (GIF supports exact 20ms frames) so the smooth movement is visible.
    final frameCount = StartupCompanion.cycleDuration.inMilliseconds * 2 ~/ 20;
    for (var frame = 0; frame < frameCount; frame++) {
      if (frame > 0) await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data!.buffer.asUint8List();
        await File(
          '${frames.path}/frame-${frame.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes);
        if ([0, 20, 52, 70, 110, 150, 175, 205, 269].contains(frame)) {
          await File(
            '${output.path}/frame-${frame.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(bytes);
        }
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
