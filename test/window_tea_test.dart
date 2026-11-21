import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';

void main() {
  test('window tea repeats its complete three-variant supercycle', () {
    for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
      final timeline = FriendMotionClock.windowTeaTimelineFor(friend);
      // 10s + 11s + 9.5s variants, a drink about every ten seconds.
      expect(timeline.length, 366);
      final cycle = FriendMotionClock.restDurationFor(friend);
      final start = FriendMotionClock.sample(
        Duration.zero,
        resting: true,
        friend: friend,
      );
      final end = FriendMotionClock.sample(
        cycle - const Duration(microseconds: 1),
        resting: true,
        friend: friend,
      );
      final next = FriendMotionClock.sample(
        cycle,
        resting: true,
        friend: friend,
      );
      expect(
        (start.from, start.to, start.blend),
        (next.from, next.to, next.blend),
      );
      expect((end.from, end.to, end.blend), (0, 0, 0));
      for (final variant in FriendMotionClock.restVariantsFor(friend)) {
        expect(variant.action.sublist(23, 29).toSet(), {16});
      }
    }
  });
  test(
    'window tea uses crisp drawings, gradual lift, blinks and bounded holds',
    () {
      for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
        final timeline = FriendMotionClock.windowTeaTimelineFor(friend);
        expect(timeline.length, 366);
        expect(timeline.toSet(), containsAll([0, 1, 2, 3, 10, 16, 27]));
        // These old drawings raised the upright rim from the lip to the nose.
        for (var cel = 11; cel <= 15; cel++) {
          expect(timeline, isNot(contains(cel)));
        }
        // Cel 18 dips the fennec's cup 5px and pales the squirrel's lids, and
        // 19-26 sit 2-5px above the resting drawing: the whole body hopped.
        for (var cel = 18; cel <= 26; cel++) {
          expect(timeline, isNot(contains(cel)));
        }
        // The squirrel's cel 17 throws its cup 10px sideways.
        expect(timeline.contains(17), friend == FocusFriend.fennec);
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
      // The fennec's 10, 3, 27, 17 and 16 are slid 1-2px onto the resting
      // head by docs/design/rest-body-motion-fix-v1/bake.py.
      const heights = {
        FocusFriend.fennec: {
          0: 280,
          19: 277,
          4: 273,
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
          10: 226,
          3: 227,
          27: 218,
          17: 218,
          18: 218,
          16: 218,
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
        for (final variant in FriendMotionClock.restVariantsFor(friend)) {
          // Panda shape: 4,4,2,2,3 ticks up, about a second at the mouth.
          const lifted = 15;
          final action = variant.action;
          final lift = action.sublist(0, lifted);
          final lower = action.sublist(action.length - lifted);
          expect(lower, lift.reversed.toList());
          expect(action.sublist(lifted, lifted + 4), [3, 3, 27, 27]);
          expect(action.sublist(lifted + 18, lifted + 22), [27, 27, 3, 3]);
          expect(action.length, lifted + 22 + lifted);
          var lastHeight = heights[friend]![0]!;
          for (final frame in [
            ...lift,
            3,
            27,
            if (friend == FocusFriend.fennec) 17,
          ]) {
            final y = heights[friend]![frame]!;
            // A pixel is the error of measuring a rim top: the fennec's cup
            // print sits 1px higher in cel 3 than in cel 10, its rim 1px lower.
            expect(
              y,
              lessThanOrEqualTo(lastHeight + 1),
              reason: '${friend.name}: cup reversed while lifting',
            );
            lastHeight = y;
          }
          expect(lift.toSet().length, 5);
          expect(lift.last, 10);
          expect(action.sublist(lifted + 8, lifted + 14).toSet(), {16});
        }
      }
    },
  );
  for (final (friend, fixed) in [
    // Tail and ear tips, then the parts each drawing traced 1-3px apart
    // inside the repainted region: ear edge and cheek fluff.
    (
      FocusFriend.fennec,
      [
        Rect.fromLTWH(90, 260, 80, 60),
        Rect.fromLTWH(150, 60, 40, 40),
        Rect.fromLTRB(136, 140, 196, 200),
        Rect.fromLTRB(150, 196, 214, 240),
      ],
    ),
    // Tail and acorn hat.
    (
      FocusFriend.squirrel,
      [Rect.fromLTWH(60, 150, 100, 150), Rect.fromLTWH(220, 100, 60, 25)],
    ),
  ]) {
    testWidgets(
      '${friend.name}: drinking and blinking keep the resting head, ears and tail',
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
  for (final (friend, seat) in [
    // The strip under the middle of the body, where it sits on the closed book.
    (FocusFriend.fennec, Rect.fromLTRB(220, 330, 335, 346)),
    (FocusFriend.squirrel, Rect.fromLTRB(220, 348, 335, 362)),
  ]) {
    testWidgets('${friend.name}: the body never lifts off the book', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final atlas = await _restAtlas(friend);
        final base = await _paintTea(atlas, friend, 0);
        for (final cel in FriendMotionClock.windowTeaTimelineFor(
          friend,
        ).toSet()) {
          final pixels = await _paintTea(atlas, friend, cel);
          for (var y = seat.top.toInt(); y < seat.bottom; y++) {
            for (var x = seat.left.toInt(); x < seat.right; x++) {
              final alpha = (y * 512 + x) * 4 + 3;
              // The room showed through here when a drawing sat higher.
              expect(
                pixels[alpha],
                greaterThanOrEqualTo(base[alpha] - 8),
                reason: '${friend.name} cel $cel is see-through at $x,$y',
              );
            }
          }
        }
        atlas.dispose();
      });
    });
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

Future<ui.Image> _restAtlas(FocusFriend friend) async {
  final data = await rootBundle.load('${friend.motionDirectory}/rest.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final atlas = (await codec.getNextFrame()).image;
  codec.dispose();
  return atlas;
}

/// The rest cel as the app paints it on the 512px stage, as RGBA bytes.
Future<List<int>> _paintTea(ui.Image atlas, FocusFriend friend, int cel) async {
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
