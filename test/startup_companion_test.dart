import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/startup_companion.dart';

Future<void> loadStartupArt(WidgetTester tester) => tester.runAsync(() async {
  final context = tester.element(find.byType(StartupCompanion));
  await Future.wait([
    for (final asset in [
      StartupCompanion.asset,
      ...StartupCompanion.motionAssets,
    ])
      precacheImage(StartupCompanion.imageProvider(asset), context),
  ]);
});

StartupCompanionPainter startupPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('startup-companion-motion')),
            )
            .painter!
        as StartupCompanionPainter;

Widget _scene({
  bool reduced = false,
  bool enabled = true,
  bool animate = true,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: TickerMode(
      enabled: enabled,
      child: Scaffold(body: StartupCompanion(size: 300, animate: animate)),
    ),
  ),
);

void main() {
  testWidgets('companion hugs then nods, pausing without a time jump', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(_scene());
    await loadStartupArt(tester);
    await tester.pump();
    expect(startupPainter(tester).blink, isNotNull);
    expect(startupPainter(tester).nod, isNotNull);
    expect(startupPainter(tester).hugAmount, 0);
    expect(startupPainter(tester).blinkAmount, 0);
    await tester.pump(const Duration(milliseconds: 1040));
    expect(startupPainter(tester).halfBlink, isNotNull);
    expect(startupPainter(tester).blinkFrame, 1);
    expect(startupPainter(tester).hugAmount, greaterThan(.5));
    expect(startupPainter(tester).nodAmount, 0);
    await tester.pump(const Duration(milliseconds: 360));
    expect(startupPainter(tester).blinkAmount, 1);
    expect(startupPainter(tester).hugAmount, 1);
    expect(startupPainter(tester).nodAmount, inExclusiveRange(0, 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = startupPainter(tester).elapsed;
    await tester.pump(const Duration(seconds: 10));
    expect(startupPainter(tester).elapsed, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      startupPainter(tester).elapsed,
      paused + const Duration(milliseconds: 200),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(startupPainter(tester).nodAmount, 1);
    expect(startupPainter(tester).blinkAmount, 1);
    await tester.pump(const Duration(milliseconds: 2080));
    expect(startupPainter(tester).hugAmount, 0);
    expect(startupPainter(tester).nodAmount, 0);
    expect(startupPainter(tester).blinkAmount, 0);
    final resting = startupPainter(tester).elapsed;
    await tester.pump(const Duration(milliseconds: 17));
    expect(
      startupPainter(tester).elapsed,
      resting + const Duration(milliseconds: 17),
      reason: 'Small movements update on a 60Hz display frame',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reduced motion, muted ticker and retry state stop the companion',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(_scene());
      await loadStartupArt(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1280));
      expect(startupPainter(tester).blinkAmount, 1);
      await tester.pumpWidget(_scene(reduced: true));
      await tester.pumpAndSettle();
      expect(startupPainter(tester).elapsed, Duration.zero);
      expect(startupPainter(tester).hugAmount, 0);
      expect(startupPainter(tester).nodAmount, 0);
      expect(startupPainter(tester).blinkAmount, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(startupPainter(tester).elapsed, Duration.zero);

      await tester.pumpWidget(_scene());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(_scene(enabled: false));
      final stopped = startupPainter(tester).elapsed;
      await tester.pump(const Duration(seconds: 2));
      expect(startupPainter(tester).elapsed, stopped);
      await tester.pumpWidget(_scene(animate: false));
      await tester.pumpAndSettle();
      expect(startupPainter(tester).elapsed, Duration.zero);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'hug moves the book, nod follows, feet stay planted and loop is seamless',
    (tester) async {
      await tester.pumpWidget(_scene(animate: false));
      await loadStartupArt(tester);
      await tester.pump();
      // An inactive companion skips loading the optional blink; resolve it here
      // through an active widget to test the real paired artwork.
      await tester.pumpWidget(_scene());
      await tester.pump();
      final art = startupPainter(tester);
      expect(art.blink, isNotNull);
      expect(art.nod, isNotNull);
      await tester.runAsync(() async {
        Future<Uint8List> pixels(int milliseconds) async {
          final recorder = ui.PictureRecorder();
          StartupCompanionPainter(
            art.image,
            blink: art.blink,
            halfBlink: art.halfBlink,
            nod: art.nod,
            body: art.body,
            book: art.book,
            feet: art.feet,
            elapsed: Duration(milliseconds: milliseconds),
          ).paint(Canvas(recorder), const Size(300, 300));
          final picture = recorder.endRecording();
          final image = await picture.toImage(300, 300);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final result = Uint8List.fromList(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
          return result;
        }

        final neutral = await pixels(0);
        final hugged = await pixels(1400);
        final nodded = await pixels(2200);
        int changes(Uint8List a, Uint8List b, Rect region) {
          var count = 0;
          for (var y = region.top.toInt(); y < region.bottom; y++) {
            for (var x = region.left.toInt(); x < region.right; x++) {
              final i = (y * 300 + x) * 4;
              if (a[i] != b[i] ||
                  a[i + 1] != b[i + 1] ||
                  a[i + 2] != b[i + 2] ||
                  a[i + 3] != b[i + 3]) {
                count++;
              }
            }
          }
          return count;
        }

        expect(
          changes(neutral, hugged, const Rect.fromLTRB(175, 180, 220, 245)),
          greaterThan(500),
          reason: 'The book must visibly pull toward the chest',
        );
        expect(
          changes(hugged, nodded, const Rect.fromLTRB(100, 20, 260, 160)),
          greaterThan(1000),
          reason: 'The nod must follow the held hug',
        );
        for (final frame in [hugged, nodded]) {
          for (final fixed in [
            const Rect.fromLTRB(0, 276, 300, 300), // ground
            const Rect.fromLTRB(30, 155, 74, 250), // outer tail
            const Rect.fromLTRB(125, 235, 143, 253), // left foot
            const Rect.fromLTRB(227, 230, 241, 244), // right foot
          ]) {
            expect(
              changes(neutral, frame, fixed),
              0,
              reason: 'Feet, tail and ground remain stable: $fixed',
            );
          }
        }
        final loop = await pixels(
          StartupCompanion.cycleDuration.inMilliseconds,
        );
        expect(changes(neutral, loop, const Rect.fromLTWH(0, 0, 300, 300)), 0);
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'head and book retain proportions while shoulder stays attached',
    (tester) async {
      await tester.pumpWidget(_scene());
      await loadStartupArt(tester);
      await tester.pump();
      final art = startupPainter(tester);
      StartupCompanionPainter pose(int ms) => StartupCompanionPainter(
        art.image,
        elapsed: Duration(milliseconds: ms),
      );
      const headA = Offset(500, 250), headB = Offset(900, 550);
      const bookCorners = [
        Offset(600, 700),
        Offset(980, 700),
        Offset(980, 1080),
        Offset(600, 1080),
      ];
      const shoulder = Offset(445, 710);
      for (var ms = 0; ms <= 5400; ms += 20) {
        final frame = pose(ms);
        expect(
          (frame.headPosition(headA) - frame.headPosition(headB)).distance,
          closeTo((headA - headB).distance, .0001),
          reason: 'Nodding must not squash the head',
        );
        expect(
          frame.bookPosition(shoulder),
          shoulder,
          reason:
              'Pulling the book must not slide the upper arm off the shoulder',
        );
        for (var i = 0; i < 4; i++) {
          final a = bookCorners[i], b = bookCorners[(i + 1) % 4];
          expect(
            (frame.bookPosition(a) - frame.bookPosition(b)).distance,
            closeTo((a - b).distance, .0001),
            reason: 'The book stays rigid',
          );
        }
        if (ms > 0) {
          final previous = pose(ms - 20);
          expect(
            (frame.bookPosition(bookCorners.first) -
                    previous.bookPosition(bookCorners.first))
                .distance,
            lessThan(1.4),
          );
          expect(
            (frame.headPosition(headA) - previous.headPosition(headA)).distance,
            lessThan(1.4),
            reason: 'No large jumps between display frames',
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
