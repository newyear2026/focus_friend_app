import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:focus_friend_app/reference_study_animation.dart';

void main() {
  test(
    'writing continues across repeated strokes and both page-turn joins',
    () {
      expect(
        ReferenceStudyAnimation.writingCycleTicks / ReferenceStudyAnimation.fps,
        4,
      );
      expect(
        ReferenceStudyAnimation.pageTurnTicks / ReferenceStudyAnimation.fps,
        5.5,
      );
      for (var seconds = 4; seconds < 36; seconds += 4) {
        final before = ReferenceStudyAnimation.poseAt(
          Duration(microseconds: seconds * 1000000 - 1),
        );
        final after = ReferenceStudyAnimation.poseAt(
          Duration(seconds: seconds),
        );
        expect((after.frame - before.frame).abs(), lessThanOrEqualTo(1));
        expect(after.ink, greaterThanOrEqualTo(before.ink));
      }
      final entering = ReferenceStudyAnimation.poseAt(
        const Duration(seconds: 36),
      );
      expect(entering.frame, 0);
      expect(entering.turningPage, isTrue);
      expect(entering.ink, 1);
      final end = Duration(
        microseconds:
            ReferenceStudyAnimation.cycleTicks *
            1000000 ~/
            ReferenceStudyAnimation.fps,
      );
      final beforeReset = ReferenceStudyAnimation.poseAt(
        end - const Duration(microseconds: 1),
      );
      final afterReset = ReferenceStudyAnimation.poseAt(end);
      expect(beforeReset.frame, afterReset.frame);
      expect(beforeReset.ink, afterReset.ink);
      expect(afterReset.turningPage, isFalse);
      expect(
        ReferenceStudyAnimation.poseAt(const Duration(microseconds: -1)).frame,
        0,
      );
    },
  );

  testWidgets('writing keeps the body still while the wrist and pencil move', (
    tester,
  ) async {
    await tester.runAsync(() async {
      Future<ui.Image> decode(String asset) async {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        return image;
      }

      final atlas = await decode(ReferenceStudyAnimation.bodyAsset);
      final notebook = await decode(ReferenceStudyAnimation.notebookAsset);
      final strokeBounds = ReferenceCompanionPainter.writingStrokeRegion
          .getBounds()
          .inflate(2);
      List<int>? reference;
      var changingStrokePixels = 0;
      for (final cel in ReferenceStudyAnimation.writingTimeline.toSet()) {
        final recorder = ui.PictureRecorder();
        ReferenceCompanionPainter(
          atlas,
          cel,
          notebook: notebook,
        ).paint(Canvas(recorder), const Size(580, 580));
        final picture = recorder.endRecording();
        final image = await picture.toImage(580, 580);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        reference ??= List.of(data);
        for (var y = 0; y < 580; y++) {
          for (var x = 0; x < 580; x++) {
            final i = (y * 580 + x) * 4;
            final changed = List.generate(
              4,
              (channel) => reference![i + channel] != data[i + channel],
            ).any((value) => value);
            if (!changed) continue;
            final point = Offset((x - 64) * 512 / 500, (y - 35) * 512 / 500);
            expect(
              strokeBounds.contains(point),
              isTrue,
              reason: 'Writing cel $cel moved the body at $x,$y',
            );
            changingStrokePixels++;
          }
        }
        image.dispose();
        picture.dispose();
      }
      expect(changingStrokePixels, greaterThan(0));
      atlas.dispose();
      notebook.dispose();
    });
  });

  testWidgets(
    'the rendered book cover stays registered across every motion pose',
    (tester) async {
      await tester.runAsync(() async {
        Future<ui.Image> decode(String asset) async {
          final bytes = await rootBundle.load(asset);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          codec.dispose();
          return image;
        }

        final atlas = await decode(ReferenceStudyAnimation.bodyAsset);
        final notebook = await decode(ReferenceStudyAnimation.notebookAsset);
        List<int>? reference;
        List<int>? opaqueCoverPixels;
        final cels = {
          ...ReferenceStudyAnimation.writingTimeline,
          ...ReferenceStudyAnimation.pageTurnTimeline,
        };
        for (final cel in cels) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          ReferenceCompanionPainter(
            atlas,
            cel,
            notebook: notebook,
            turningPage: true,
            inkProgress: 1,
          ).paint(canvas, const Size(580, 580));
          final picture = recorder.endRecording();
          final image = await picture.toImage(580, 580);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final cover = <int>[
            for (var y = 494; y < 503; y++)
              ...bytes.buffer.asUint8List((y * 580 + 240) * 4, 300 * 4),
          ];
          reference ??= cover;
          opaqueCoverPixels ??= [
            for (var i = 0; i < cover.length; i += 4)
              if (cover[i + 3] >= 253 && cover[i] < 100) i,
          ];
          expect(opaqueCoverPixels, isNotEmpty);
          // Image Gen's near-opaque texture has alpha 253, so the moving
          // sheet shadow may change a channel by at most 2 levels underneath.
          // A translated/scaled notebook changes the sampled cover much more.
          for (final i in opaqueCoverPixels) {
            for (var channel = 0; channel < 4; channel++) {
              expect(
                (reference[i + channel] - cover[i + channel]).abs(),
                lessThanOrEqualTo(2),
                reason: 'Book cover moved in cel $cel',
              );
            }
          }
          image.dispose();
          picture.dispose();
        }
        Future<List<int>> exposedInk(double progress) async {
          final recorder = ui.PictureRecorder();
          ReferenceCompanionPainter(
            atlas,
            14,
            notebook: notebook,
            turningPage: true,
            inkProgress: progress,
          ).paint(Canvas(recorder), const Size(580, 580));
          final picture = recorder.endRecording();
          final image = await picture.toImage(580, 580);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final paper = <int>[
            for (var y = 455; y < 482; y++)
              ...bytes.buffer.asUint8List((y * 580 + 260) * 4, 110 * 4),
          ];
          image.dispose();
          picture.dispose();
          return paper;
        }

        // The completed sheet must already hide all old words before reset.
        expect(
          await exposedInk(1),
          orderedEquals(await exposedInk(0)),
          reason: 'Old ink is still exposed just before the page resets',
        );
        atlas.dispose();
        notebook.dispose();
      });
    },
  );

  testWidgets(
    'idle, pause, background and reduced motion preserve a connected pose',
    (tester) async {
      var studying = false, animate = true, paused = false;
      var visible = true, reduced = false;
      Widget harness() => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: visible,
            child: SizedBox(
              width: 200,
              height: 200,
              child: ReferenceCompanion(
                studying: studying,
                animate: animate,
                paused: paused,
              ),
            ),
          ),
        ),
      );
      ReferenceCompanionPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('reference-companion-cels')),
                  )
                  .painter!
              as ReferenceCompanionPainter;
      await tester.pumpWidget(harness());
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
      await tester.pump(const Duration(seconds: 10));
      expect(painter().frame, 0);
      studying = true;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 1667));
      expect(painter().frame, 4);
      final held = painter().frame;
      paused = true;
      animate = false;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 20));
      expect(painter().frame, held);
      paused = false; // App remains in the background.
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 20));
      expect(painter().frame, held);
      animate = true;
      visible = false;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 20));
      expect(painter().frame, held);
      visible = true;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 250));
      expect(painter().frame, 5);
      reduced = true;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 20));
      expect(painter().frame, 0);
      reduced = false;
      await tester.pumpWidget(harness());
      expect(painter().frame, 5);
      studying = false;
      await tester.pumpWidget(harness());
      expect(painter().frame, 0);
      studying = true;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 1667));
      expect(painter().frame, 4);
      expect(find.byKey(const ValueKey('writing-paw-motion')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a paused page turn holds ink and resumes into a fresh page', (
    tester,
  ) async {
    var paused = false, studying = true;
    Widget harness() => MaterialApp(
      home: SizedBox(
        width: 200,
        height: 200,
        child: ReferenceCompanion(
          animate: !paused,
          studying: studying,
          paused: paused,
        ),
      ),
    );
    ReferenceCompanionPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('reference-companion-cels')),
                )
                .painter!
            as ReferenceCompanionPainter;
    await tester.pumpWidget(harness());
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
    await tester.pump(const Duration(seconds: 33));
    expect(painter().turningPage, isFalse);
    expect(painter().inkProgress, greaterThan(.8));
    await tester.pump(const Duration(milliseconds: 4500));
    expect(painter().turningPage, isTrue);
    expect(painter().inkProgress, 1);
    final held = painter().frame;
    paused = true;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 30));
    expect(painter().frame, held);
    expect(painter().inkProgress, 1);
    paused = false;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 3000));
    expect(painter().turningPage, isTrue);
    expect(painter().inkProgress, 0);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(painter().turningPage, isFalse);
    expect(painter().frame, 0);
    expect(painter().inkProgress, 0);
    studying = false;
    await tester.pumpWidget(harness());
    expect(painter().frame, 0);
    expect(painter().inkProgress, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
