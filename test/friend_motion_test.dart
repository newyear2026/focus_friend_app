import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';

Future<ui.Image> _decode(String path) async {
  final bytes = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final result = (await codec.getNextFrame()).image;
  codec.dispose();
  return result;
}

void main() {
  test('slow study and tea loops join the exact canonical cel', () {
    expect(
      FriendMotionClock.studyDuration,
      const Duration(milliseconds: 40500),
    );
    expect(
      FriendMotionClock.writingLoops *
              FriendMotionClock.writingTimeline.length +
          FriendMotionClock.pageTurnTimeline.length,
      FriendMotionClock.studyDuration.inMilliseconds *
          FriendMotionClock.framesPerSecond ~/
          1000,
    );
    expect(
      FriendMotionClock.writingLoops * FriendMotionClock.writingTimeline.length,
      FriendMotionClock.writingDuration.inSeconds *
          FriendMotionClock.framesPerSecond,
    );
    for (final timeline in [
      FriendMotionClock.penguinRestTimeline,
      FriendMotionClock.otterRestTimeline,
    ]) {
      expect(
        timeline.length,
        FriendMotionClock.restDuration.inSeconds *
            FriendMotionClock.framesPerSecond,
      );
      expect(timeline.first, timeline.last);
    }
    for (final boundary in [
      const Duration(seconds: 4),
      FriendMotionClock.writingDuration,
      FriendMotionClock.studyDuration,
    ]) {
      final before = FriendMotionClock.sample(
        boundary - const Duration(microseconds: 1),
      );
      final after = FriendMotionClock.sample(boundary);
      // Each join is the rest cel or its neighbouring stroke drawing.
      expect(before.from, anyOf(0, 1));
      expect(after.from, 0);
      expect((before.blend, after.blend), (0, 0));
    }
    final before = FriendMotionClock.sample(
      FriendMotionClock.restDuration - const Duration(microseconds: 1),
      resting: true,
    );
    final after = FriendMotionClock.sample(
      FriendMotionClock.restDuration,
      resting: true,
    );
    expect(before.from, after.from);
    expect((before.blend, after.blend), (0, 0));
    expect(FriendMotionClock.sample(const Duration(seconds: -1)).blend, 0);
  });

  test('desk friends show one complete drawing at a time', () {
    for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
      for (final resting in [false, true]) {
        final cycle = resting
            ? FriendMotionClock.restDurationFor(friend)
            : FriendMotionClock.studyDuration;
        final seen = <int>{};
        var changes = 0, previous = -1;
        for (var ms = 0; ms < cycle.inMilliseconds; ms += 1000 ~/ 12) {
          final pose = FriendMotionClock.sample(
            Duration(milliseconds: ms),
            resting: resting,
            friend: friend,
          );
          expect(pose.from, pose.to, reason: '${friend.name} at $ms ms');
          expect(pose.blend, 0, reason: '${friend.name} at $ms ms');
          if (previous != -1 && pose.from != previous) changes++;
          previous = pose.from;
          seen.add(pose.from);
        }
        expect(seen.length, greaterThan(3));
        expect(changes, greaterThan(3));
      }
    }
  });

  for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
    testWidgets(
      '${friend.name}: actual sprite writing keeps face, cup and book still',
      (tester) async {
        await tester.runAsync(() async {
          final study = await _decode('${friend.motionDirectory}/study.png');
          Future<List<int>> render(int frame) async {
            final recorder = ui.PictureRecorder();
            FriendMotionPainter(
              friend: friend,
              study: study,
              pose: FriendMotionPose(
                frame,
                frame,
                0,
                FriendMotionPhase.writing,
              ),
            ).paint(Canvas(recorder), const Size(512, 512));
            final picture = recorder.endRecording();
            final image = await picture.toImage(512, 512);
            final result = List<int>.from(
              (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List(),
            );
            image.dispose();
            picture.dispose();
            return result;
          }

          final base = await render(0);
          var movement = 0;
          for (var frame = 1; frame <= 5; frame++) {
            final pixels = await render(frame);
            for (final region in [
              const Rect.fromLTWH(90, 80, 245, 200),
              const Rect.fromLTWH(325, 320, 100, 115),
              const Rect.fromLTWH(120, 398, 195, 20),
            ]) {
              for (var y = region.top.toInt(); y < region.bottom; y++) {
                for (var x = region.left.toInt(); x < region.right; x++) {
                  final i = (y * 512 + x) * 4;
                  expect(
                    pixels.sublist(i, i + 4),
                    base.sublist(i, i + 4),
                    reason: 'Frame $frame moved a fixed part at $x,$y',
                  );
                }
              }
            }
            for (var i = 0; i < pixels.length; i++) {
              if (pixels[i] != base[i]) movement++;
            }
          }
          expect(movement, greaterThan(100));
          study.dispose();
        });
      },
    );

    testWidgets(
      '${friend.name}: pause, background and reduced motion stop the visual clock',
      (tester) async {
        var paused = false, visible = true, reduced = false;
        Widget harness() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: visible,
              child: FriendMotionScene(
                friend: friend,
                animate: true,
                studying: true,
                resting: false,
                paused: paused,
              ),
            ),
          ),
        );
        await tester.pumpWidget(harness());
        await tester.runAsync(() async {
          for (final asset in [
            friend.ambienceAsset(RoomAmbience.evening),
            '${friend.motionDirectory}/study.png',
          ]) {
            await precacheImage(
              AssetImage(asset),
              tester.element(find.byType(FriendMotionScene)),
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        FriendMotionPose pose() =>
            (tester
                        .widget<CustomPaint>(
                          find.byKey(const ValueKey('friend-motion-cels')),
                        )
                        .painter!
                    as FriendMotionScenePainter)
                .actor
                .pose;
        (int, int, double) stamp() => (pose().from, pose().to, pose().blend);
        await tester.pump(const Duration(milliseconds: 800));
        paused = true;
        await tester.pumpWidget(harness());
        final held = stamp();
        await tester.pump(const Duration(seconds: 2));
        expect(stamp(), held);
        paused = false;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(milliseconds: 500));
        expect(stamp(), isNot(held));
        visible = false;
        await tester.pumpWidget(harness());
        final background = stamp();
        await tester.pump(const Duration(seconds: 3));
        expect(stamp(), background);
        visible = true;
        reduced = true;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(seconds: 2));
        expect(stamp(), (0, 0, 0.0));
        reduced = false;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(milliseconds: 500));
        expect(stamp(), isNot((0, 0, 0.0)));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
