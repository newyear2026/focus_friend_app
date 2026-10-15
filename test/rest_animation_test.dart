import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';

void main() {
  test('14 cels retain the original sequence and ten-second duration', () {
    final sequence = <int>[];
    for (final frame in RestAnimation.timeline) {
      if (sequence.isEmpty || sequence.last != frame) sequence.add(frame);
    }
    expect(sequence, [0, 1, 0, 2, 3, 12, 4, 5, 6, 7, 8, 13, 9, 10, 11]);
    expect(sequence.toSet(), {for (var i = 0; i < 14; i++) i});
    expect(RestAnimation.timeline.length, RestAnimation.cycleTicks);
    expect(RestAnimation.cycleTicks / RestAnimation.framesPerSecond, 10);
    for (var ms = 0; ms < 10000; ms += 50) {
      expect(
        RestAnimation.frameAt(Duration(milliseconds: ms)),
        RestAnimation.frameAt(Duration(milliseconds: ms + 10000)),
      );
    }
    expect(RestAnimation.frameAt(const Duration(microseconds: -1)), 0);
  });

  testWidgets(
    'all twelve approved cels render pixel-identically to their source',
    (tester) async {
      await tester.runAsync(() async {
        Future<ui.Image> load(String path) async {
          final data = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          codec.dispose();
          return image;
        }

        final atlas = await load(RestAnimation.asset);
        final extras = await load(RestAnimation.inbetweensAsset);
        Future<Uint8List> render(void Function(Canvas) draw) async {
          final recorder = ui.PictureRecorder();
          draw(Canvas(recorder));
          final picture = recorder.endRecording();
          final image = await picture.toImage(362, 362);
          picture.dispose();
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          return bytes;
        }

        for (var frame = 0; frame < 14; frame++) {
          final tick = RestAnimation.timeline.indexOf(frame);
          final time = Duration(microseconds: (tick * 1000000 / 12).ceil());
          final painter = RestCompanionPainter(atlas, time, inbetweens: extras);
          expect(painter.frame, frame);
          final actual = await render(
            (c) => painter.paint(c, const Size(362, 362)),
          );
          if (frame < 12) {
            final expected = await render(
              (c) => c.drawImageRect(
                atlas,
                Rect.fromLTWH(frame % 4 * 362, frame ~/ 4 * 362, 362, 362),
                const Rect.fromLTWH(0, 0, 362, 362),
                Paint()..filterQuality = FilterQuality.medium,
              ),
            );
            expect(
              actual,
              orderedEquals(expected),
              reason: 'Original cel $frame changed',
            );
          } else {
            var count = 0, minY = 362, maxY = 0;
            for (var y = 0; y < 362; y++) {
              for (var x = 0; x < 362; x++) {
                if (actual[(y * 362 + x) * 4 + 3] > 128) {
                  count++;
                  if (y < minY) minY = y;
                  if (y > maxY) maxY = y;
                }
              }
            }
            expect(count, greaterThan(50000));
            expect(minY, inInclusiveRange(45, 49));
            expect(maxY, inInclusiveRange(346, 351));
          }
          final held = RestCompanionPainter(
            atlas,
            time + const Duration(milliseconds: 10),
            inbetweens: extras,
          );
          expect(held.shouldRepaint(painter), false);
        }
        atlas.dispose();
        extras.dispose();
      });
    },
  );

  test('both intermediate drawings get a brief hold during motion', () {
    for (final frame in [12, 13]) {
      expect(RestAnimation.timeline.where((value) => value == frame).length, 2);
    }
    expect(RestAnimation.frameAt(const Duration(seconds: 5)), 6);
    expect(RestAnimation.frameAt(const Duration(seconds: 10)), 0);
  });

  testWidgets('pause, background and hidden ticker preserve the tea pose', (
    tester,
  ) async {
    var animate = true;
    var paused = false;
    var visible = true;
    var reduced = false;
    Widget harness() => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: visible,
          child: SizedBox(
            width: 200,
            height: 200,
            child: RestCompanion(animate: animate, paused: paused),
          ),
        ),
      ),
    );
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
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 5000));
    expect(painter().frame, 6);
    final elapsed = painter().elapsed;
    paused = true;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 20));
    expect(painter().elapsed, elapsed);
    paused = false;
    animate = false;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 20));
    expect(painter().elapsed, elapsed);
    animate = true;
    visible = false;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 20));
    expect(painter().elapsed, elapsed);
    visible = true;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 200));
    expect(painter().elapsed, elapsed + const Duration(milliseconds: 200));
    reduced = true;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 20));
    expect(painter().frame, 0);
    expect(painter().elapsed, Duration.zero);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
