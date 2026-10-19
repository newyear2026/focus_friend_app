import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';

void main() {
  test('window tea takes 22 seconds and joins the same resting pose', () {
    expect(
      FriendMotionClock.windowTeaTimeline.length,
      22 * FriendMotionClock.windowTeaFramesPerSecond,
    );
    for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
      final start = FriendMotionClock.sample(
        Duration.zero,
        resting: true,
        friend: friend,
      );
      final end = FriendMotionClock.sample(
        const Duration(microseconds: 21999999),
        resting: true,
        friend: friend,
      );
      final next = FriendMotionClock.sample(
        const Duration(seconds: 22),
        resting: true,
        friend: friend,
      );
      expect(
        (start.from, start.to, start.blend),
        (next.from, next.to, next.blend),
      );
      expect((end.from, end.to, end.blend), (0, 0, 0));
      expect(
        FriendMotionClock.sample(
          const Duration(seconds: 2),
          resting: true,
          friend: friend,
        ).from,
        0,
      );
      expect(
        FriendMotionClock.sample(
          const Duration(seconds: 8),
          resting: true,
          friend: friend,
        ).from,
        16,
      );
    }
  });
  test(
    'window tea uses crisp drawings, gradual lift, blinks and bounded holds',
    () {
      for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
        final timeline = FriendMotionClock.windowTeaTimelineFor(friend);
        expect(timeline.length, 264);
        expect(timeline.toSet(), containsAll([0, 1, 2, 3, 10, 16, 17, 18, 27]));
        expect(timeline.any((cel) => cel >= 19), isTrue);
        // These old drawings raised the upright rim from the lip to the nose.
        for (var cel = 11; cel <= 15; cel++) {
          expect(timeline, isNot(contains(cel)));
        }
        var longest = 0, current = 0, previous = -1;
        // Two cycles include the otherwise easy-to-miss wraparound hold.
        for (var tick = 0; tick < timeline.length * 2; tick++) {
          final pose = FriendMotionClock.sample(
            Duration(microseconds: (tick * 1000000 / 12).ceil()),
            resting: true,
            friend: friend,
          );
          expect(pose.from, pose.to);
          expect(pose.blend, 0);
          expect(pose.from, inInclusiveRange(0, 27));
          current = pose.from == previous ? current + 1 : 1;
          if (current > longest) longest = current;
          previous = pose.from;
        }
        expect(longest, lessThanOrEqualTo(60));
      }
      expect(
        FriendMotionClock.windowTeaFrameAt(const Duration(seconds: -1)),
        0,
      );
    },
  );
  test(
    'upright cup only rises toward the mouth and lowers on the same path',
    () {
      // Top cream pixels inside the rim, measured consistently in the final
      // 384px atlas enlarged to 512px with LANCZOS. Values decrease upward.
      const heights = {
        FocusFriend.fennec: {
          0: 280,
          19: 277,
          20: 267,
          5: 261,
          6: 259,
          7: 253,
          23: 248,
          8: 241,
          24: 238,
          25: 237,
          9: 230,
          26: 227,
          10: 225,
          3: 225,
          27: 217,
          17: 217,
          18: 218,
          16: 217,
        },
        FocusFriend.squirrel: {
          0: 303,
          4: 293,
          25: 289,
          5: 285,
          21: 284,
          20: 282,
          6: 279,
          22: 276,
          7: 270,
          8: 266,
          9: 262,
          10: 262,
          3: 257,
          27: 256,
          17: 255,
          18: 256,
          16: 258,
        },
      };
      for (final friend in heights.keys) {
        final timeline = FriendMotionClock.windowTeaTimelineFor(friend);
        const lifted = 60 + FriendMotionClock.teaLiftTicks;
        final lift = timeline.sublist(60, lifted);
        final lower = timeline.sublist(
          lifted + 42,
          lifted + 42 + FriendMotionClock.teaLiftTicks,
        );
        expect(lower, lift.reversed.toList());
        expect(timeline.sublist(lifted, lifted + 4), [3, 3, 27, 27]);
        expect(timeline.sublist(lifted + 34, lifted + 38), [27, 27, 3, 3]);
        var lastHeight = heights[friend]![0]!;
        for (final frame in [...lift, 3, 27, 17]) {
          final y = heights[friend]![frame]!;
          expect(
            y,
            lessThanOrEqualTo(lastHeight),
            reason: '${friend.name}: cup reversed while lifting',
          );
          lastHeight = y;
        }
        expect(lift.first, 0);
        expect(lift.last, 10);
        expect(timeline.sublist(lifted + 10, lifted + 28).toSet(), {16});
      }
    },
  );
  for (final (friend, fixed) in [
    // Tail and ear tips.
    (
      FocusFriend.fennec,
      [Rect.fromLTWH(90, 260, 80, 60), Rect.fromLTWH(150, 60, 40, 40)],
    ),
    // Tail and acorn hat.
    (
      FocusFriend.squirrel,
      [Rect.fromLTWH(60, 150, 100, 150), Rect.fromLTWH(220, 100, 60, 25)],
    ),
  ]) {
    testWidgets(
      '${friend.name}: lift drawings keep the resting tail and ears',
      (tester) async {
        await tester.runAsync(() async {
          final data = await rootBundle.load(
            '${friend.motionDirectory}/rest.png',
          );
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final atlas = (await codec.getNextFrame()).image;
          codec.dispose();
          Future<List<int>> render(int cel) async {
            final recorder = ui.PictureRecorder();
            FriendMotionPainter(
              friend: friend,
              study: null,
              rest: atlas,
              pose: FriendMotionPose(cel, cel, 0, FriendMotionPhase.tea),
            ).paint(Canvas(recorder), const Size(512, 512));
            final picture = recorder.endRecording();
            final image = await picture.toImage(512, 512);
            final pixels = List<int>.from(
              (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List(),
            );
            image.dispose();
            picture.dispose();
            return pixels;
          }

          bool same(List<int> a, List<int> b) {
            for (final rect in fixed) {
              for (var y = rect.top.toInt(); y < rect.bottom; y++) {
                for (var x = rect.left.toInt(); x < rect.right; x++) {
                  final i = (y * 512 + x) * 4;
                  for (var c = 0; c < 4; c++) {
                    if (a[i + c] != b[i + c]) return false;
                  }
                }
              }
            }
            return true;
          }

          final base = await render(0);
          final timeline = FriendMotionClock.windowTeaTimelineFor(friend);
          expect(FriendMotionPainter.windowTeaWholeCels, isEmpty);
          for (final cel in timeline.toSet()) {
            expect(
              same(await render(cel), base),
              isTrue,
              reason: '${friend.name} cel $cel',
            );
          }
          atlas.dispose();
        });
      },
    );
  }
  for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
    testWidgets(
      '${friend.name}: book stays fixed and connected cels change while sipping',
      (tester) async {
        await tester.runAsync(() async {
          final data = await rootBundle.load(
            '${friend.motionDirectory}/rest.png',
          );
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final atlas = (await codec.getNextFrame()).image;
          codec.dispose();
          Future<List<int>> render(int cel, double blend) async {
            final recorder = ui.PictureRecorder();
            FriendMotionPainter(
              friend: friend,
              study: null,
              rest: atlas,
              pose: FriendMotionPose(
                cel,
                cel == 7 ? 6 : cel,
                blend,
                FriendMotionPhase.tea,
              ),
            ).paint(Canvas(recorder), const Size(512, 512));
            final picture = recorder.endRecording();
            final image = await picture.toImage(512, 512);
            final pixels = List<int>.from(
              (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List(),
            );
            image.dispose();
            picture.dispose();
            return pixels;
          }

          final base = await render(0, 0);
          var moved = 0;
          for (
            var cel = 1;
            cel < FriendMotionClock.windowTeaFrameCount;
            cel++
          ) {
            final pixels = await render(cel, .4);
            for (final rect in [const Rect.fromLTWH(130, 382, 270, 45)]) {
              for (var y = rect.top.toInt(); y < rect.bottom; y++) {
                for (var x = rect.left.toInt(); x < rect.right; x++) {
                  final i = (y * 512 + x) * 4;
                  expect(
                    pixels.sublist(i, i + 4),
                    base.sublist(i, i + 4),
                    reason: '$cel shifted fixed artwork at $x,$y',
                  );
                }
              }
            }
            for (var i = 0; i < pixels.length; i++) {
              if (pixels[i] != base[i]) moved++;
            }
          }
          expect(moved, greaterThan(100));
          atlas.dispose();
        });
      },
    );
    testWidgets(
      '${friend.name}: pause, room changes and reduced motion preserve rest',
      (tester) async {
        var paused = false, visible = true, reduced = false;
        var ambience = RoomAmbience.evening;
        Widget harness() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: visible,
              child: FriendMotionScene(
                friend: friend,
                ambience: ambience,
                animate: true,
                studying: false,
                resting: true,
                paused: paused,
              ),
            ),
          ),
        );
        await tester.pumpWidget(harness());
        await tester.runAsync(() async {
          for (final asset in [
            '${friend.motionDirectory}/rest.png',
            friend.restRoomAsset(ambience),
            friend.restRoomAsset(RoomAmbience.night),
          ]) {
            await precacheImage(
              AssetImage(asset),
              tester.element(find.byType(FriendMotionScene)),
            );
          }
        });
        await tester.pump();
        (int, int, double) stamp() {
          final p =
              (tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('friend-motion-cels')),
                          )
                          .painter!
                      as FriendMotionScenePainter)
                  .actor
                  .pose;
          return (p.from, p.to, p.blend);
        }

        await tester.pump(const Duration(milliseconds: 6500));
        paused = true;
        await tester.pumpWidget(harness());
        final held = stamp();
        await tester.pump(const Duration(seconds: 2));
        expect(stamp(), held);
        ambience = RoomAmbience.night;
        await tester.pumpWidget(harness());
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
        });
        await tester.pump(const Duration(seconds: 2));
        expect(stamp(), held);
        paused = false;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(milliseconds: 500));
        expect(stamp(), isNot(held));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        final background = stamp();
        await tester.pump(const Duration(seconds: 3));
        expect(stamp(), background);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(stamp(), isNot(background));
        visible = false;
        await tester.pumpWidget(harness());
        final hidden = stamp();
        await tester.pump(const Duration(seconds: 3));
        expect(stamp(), hidden);
        visible = true;
        reduced = true;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(seconds: 1));
        expect(stamp(), (0, 0, 0.0));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
