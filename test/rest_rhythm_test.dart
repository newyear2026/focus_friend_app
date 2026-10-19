import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/room_ambience.dart';

List<int> exposures(List<(int, int)> holds) => [
  for (final (cel, ticks) in holds)
    for (var tick = 0; tick < ticks; tick++) cel,
];

// Lift/sip timings frozen from 37cf920, plus the two-tick A/B exposures
// authored in e7ed48c on both sides of sipping. This independent fixture
// checks that every rhythm variant uses the complete combined action.
List<int> authoredAction(FocusFriend friend) {
  if (friend == FocusFriend.penguin) {
    return exposures([(4, 4), (5, 6), (6, 14), (5, 4), (4, 4)]);
  }
  if (friend == FocusFriend.otter) {
    return exposures([(3, 4), (4, 4), (6, 6), (7, 14), (6, 4), (4, 4), (3, 4)]);
  }
  final lift = friend == FocusFriend.fennec
      ? [
          0,
          0,
          19,
          19,
          19,
          20,
          20,
          5,
          6,
          7,
          23,
          23,
          8,
          25,
          25,
          9,
          26,
          26,
          10,
          10,
        ]
      : [0, 0, 0, 0, 0, 4, 4, 25, 5, 21, 6, 22, 22, 7, 7, 8, 9, 9, 10, 10];
  return [
    ...lift,
    ...exposures([
      (3, 2),
      (27, 2),
      (17, 3),
      (18, 3),
      (16, 18),
      (18, 3),
      (17, 3),
      (27, 2),
      (3, 2),
      (10, 4),
    ]),
    ...lift.reversed,
  ];
}

int longestCyclicHold(List<int> timeline) {
  var previous = -1, run = 0, longest = 0;
  for (final cel in [...timeline, ...timeline]) {
    run = cel == previous ? run + 1 : 1;
    if (run > longest) longest = run;
    previous = cel;
  }
  return longest;
}

Duration atTick(int tick) =>
    Duration(microseconds: (tick * 1000000 / 12).ceil());

void main() {
  for (final friend in FocusFriend.values.where(
    (friend) => friend != FocusFriend.redpanda,
  )) {
    test(
      '${friend.name}: deterministic variants preserve every authored action tick',
      () {
        final variants = FriendMotionClock.restVariantsFor(friend);
        expect(variants.length, inInclusiveRange(3, 4));
        expect(
          variants.map((v) => v.timeline.join(',')).toSet().length,
          variants.length,
        );
        final idle = friend == FocusFriend.penguin ? 3 : 0;
        var start = 0;
        for (final variant in variants) {
          expect(variant.action, authoredAction(friend));
          expect(
            variant.timeline.sublist(
              variant.actionStartTick,
              variant.actionEndTick,
            ),
            authoredAction(friend),
          );
          expect(variant.timeline.first, idle);
          expect(variant.timeline.last, idle);
          final seconds = variant.timeline.length / 12;
          expect(
            seconds,
            friend == FocusFriend.penguin
                ? inInclusiveRange(7.0, 7.7)
                : friend.hasWindowTeaMotion
                ? inInclusiveRange(18.0, 26.0)
                : inInclusiveRange(8.0, 12.0),
          );
          final rests = [...variant.before, ...variant.after];
          expect(
            rests.every(
              (cel) => friend == FocusFriend.penguin
                  ? cel == 3
                  : friend.hasWindowTeaMotion
                  ? [0, 1, 2].contains(cel)
                  : [0, 1].contains(cel),
            ),
            isTrue,
          );
          final blinkTicks = rests.where((cel) => cel != idle).length;
          final blinkLength = friend.hasWindowTeaMotion ? 4 : 2;
          expect(blinkTicks % blinkLength, 0);
          expect(blinkTicks ~/ blinkLength, inInclusiveRange(0, 2));
          for (final boundary in [start, start + variant.timeline.length]) {
            expect(
              FriendMotionClock.sample(
                atTick(boundary),
                resting: true,
                friend: friend,
              ).from,
              idle,
            );
            if (boundary > 0) {
              expect(
                FriendMotionClock.sample(
                  atTick(boundary - 1),
                  resting: true,
                  friend: friend,
                ).from,
                idle,
              );
            }
          }
          start += variant.timeline.length;
        }
        final timeline = FriendMotionClock.restTimelineFor(friend);
        expect(timeline.length, start);
        expect(longestCyclicHold(timeline), lessThanOrEqualTo(60));
        final duration = FriendMotionClock.restDurationFor(friend);
        expect((duration.inMicroseconds * 12 / 1000000).round(), start);
        for (var tick = 0; tick < start * 2; tick++) {
          final first = FriendMotionClock.sample(
            atTick(tick),
            resting: true,
            friend: friend,
          );
          final repeated = FriendMotionClock.sample(
            atTick(tick) + duration,
            resting: true,
            friend: friend,
          );
          expect(
            (first.from, first.to, first.blend),
            (timeline[tick % start], timeline[tick % start], 0),
          );
          expect(
            (repeated.from, repeated.to, repeated.blend),
            (first.from, first.to, first.blend),
          );
        }
        expect(
          FriendMotionClock.sample(
            const Duration(seconds: -1),
            resting: true,
            friend: friend,
          ).from,
          idle,
        );
      },
    );
  }

  for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
    testWidgets(
      '${friend.name}: rest rhythm freezes across pause, lifecycle and reduced motion',
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
                studying: false,
                resting: true,
                paused: paused,
              ),
            ),
          ),
        );
        await tester.pumpWidget(harness());
        await tester.runAsync(() async {
          final context = tester.element(find.byType(FriendMotionScene));
          for (final asset in [
            friend.restRoomAsset(RoomAmbience.evening),
            '${friend.motionDirectory}/study.png',
            '${friend.motionDirectory}/rest.png',
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
        });
        await tester.pump();
        (int, int, double) stamp() {
          final pose =
              (tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('friend-motion-cels')),
                          )
                          .painter!
                      as FriendMotionScenePainter)
                  .actor
                  .pose;
          return (pose.from, pose.to, pose.blend);
        }

        // Every friend has entered its first cup action by tick 32.
        await tester.pump(atTick(32));
        paused = true;
        await tester.pumpWidget(harness());
        final held = stamp();
        await tester.pump(const Duration(seconds: 30));
        expect(stamp(), held);
        paused = false;
        await tester.pumpWidget(harness());
        await tester.pump(atTick(16));
        expect(stamp(), isNot(held));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        final background = stamp();
        await tester.pump(const Duration(seconds: 20));
        expect(stamp(), background);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(atTick(16));
        expect(stamp(), isNot(background));
        visible = false;
        await tester.pumpWidget(harness());
        final hidden = stamp();
        await tester.pump(const Duration(seconds: 20));
        expect(stamp(), hidden);
        visible = true;
        reduced = true;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(seconds: 20));
        expect(stamp(), (
          friend == FocusFriend.penguin ? 3 : 0,
          friend == FocusFriend.penguin ? 3 : 0,
          0.0,
        ));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
