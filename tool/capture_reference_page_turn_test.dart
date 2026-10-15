import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';

void main() {
  testWidgets('render the complete writing and page-turn cycle', (
    tester,
  ) async {
    final captureKey = GlobalKey();
    final folder = Directory('/private/tmp/focus-calm-motion-preview')
      ..createSync(recursive: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: captureKey,
            child: const SizedBox(
              width: 580,
              height: 580,
              child: ColoredBox(
                color: Color(0xFFFFF7E6),
                child: ReferenceCompanion(animate: true, studying: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final asset in [
        ReferenceStudyAnimation.bodyAsset,
        ReferenceStudyAnimation.notebookAsset,
      ]) {
        await precacheImage(
          AssetImage(asset),
          tester.element(find.byType(ReferenceCompanion)),
        );
      }
    });
    await tester.pump();
    final metadata = <Map<String, Object>>[];
    final turnFrames = <int>{};
    for (var tick = 0; tick <= ReferenceStudyAnimation.cycleTicks; tick++) {
      if (tick > 0) {
        // Round up to reach the fresh-page boundary without ticker drift.
        await tester.pump(const Duration(microseconds: 83334));
      }
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('reference-companion-cels')),
                  )
                  .painter!
              as ReferenceCompanionPainter;
      if (painter.turningPage) turnFrames.add(painter.frame);
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${folder.path}/frame-${tick.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      metadata.add({
        'tick': tick,
        'frame': painter.frame,
        'turningPage': painter.turningPage,
        'ink': painter.inkProgress,
      });
    }
    expect(turnFrames, ReferenceStudyAnimation.pageTurnTimeline.toSet());
    expect(metadata.last['turningPage'], false);
    expect(metadata.last['ink'], 0);
    File('${folder.path}/frames.json').writeAsStringSync(jsonEncode(metadata));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
