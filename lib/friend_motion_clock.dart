import 'focus_friend.dart';

enum FriendMotionPhase { writing, pageTurn, tea }

class FriendMotionPose {
  const FriendMotionPose(this.from, this.to, this.blend, this.phase);
  final int from, to;
  final double blend;
  final FriendMotionPhase phase;
}

/// One authored action with independently timed rests on either side.
/// Only [before] and [after] vary; [action] is the unchanged cel/tick sequence.
class FriendRestVariant {
  FriendRestVariant(List<int> before, List<int> action, List<int> after)
    : before = List.unmodifiable(before),
      action = List.unmodifiable(action),
      after = List.unmodifiable(after),
      timeline = List.unmodifiable([...before, ...action, ...after]);

  final List<int> before, action, after, timeline;
  int get actionStartTick => before.length;
  int get actionEndTick => before.length + action.length;
}

/// A visual clock only. Pausing it never affects the saved focus timer.
abstract final class FriendMotionClock {
  static const writingLoops = 9;
  static const writingDuration = Duration(seconds: 36);
  static const studyDuration = Duration(milliseconds: 40500);
  // Like the panda: a 12fps timing grid selects one complete drawing.
  // Holds belong to the whole action; no per-cel easing or image blending.
  static const framesPerSecond = 12;
  static const windowTeaFramesPerSecond = framesPerSecond;
  static const windowTeaFrameCount = 28;
  // Measured upright rim heights in the registered 512px drawings. A single
  // ease spans the whole lift, so unequal drawing distances do not create a
  // fresh stop/start at every cel. Candidates with a backwards path are unused.
  static const fennecTeaLift = [
    (0, 280.0),
    (19, 277.0),
    (20, 267.0),
    (5, 261.0),
    (6, 259.0),
    (7, 253.0),
    (23, 248.0),
    (8, 241.0),
    (24, 238.0),
    (25, 237.0),
    (9, 230.0),
    (26, 227.0),
    (10, 224.0),
  ];
  static const squirrelTeaLift = [
    (0, 303.0),
    (4, 293.0),
    (25, 289.0),
    (5, 285.0),
    (21, 284.0),
    (20, 282.0),
    (6, 279.0),
    (22, 276.0),
    (7, 270.0),
    (8, 266.0),
    (9, 262.0),
    (10, 261.0),
  ];
  // About 1.7s, close to the panda's 1.5s lift; 3.5s read as slow motion.
  static const teaLiftTicks = 20;
  static List<int> _liftExposure(List<(int, double)> poses) => [
    for (var tick = 0; tick < teaLiftTicks; tick++)
      poses.reduce((a, b) {
        final y =
            poses.first.$2 +
            (poses.last.$2 - poses.first.$2) * _ease(tick / (teaLiftTicks - 1));
        return (a.$2 - y).abs() <= (b.$2 - y).abs() ? a : b;
      }).$1,
  ];
  // Freeze this entire action, including its endpoint exposures. Rhythm
  // variants can only add idle holds/blinks before and after it.
  static List<int> _teaAction(List<(int, double)> lift) => List.unmodifiable([
    ..._liftExposure(lift),
    // Two authored inbetweens let lids and cup angle change gradually.
    3, 3, 27, 27,
    17, 17, 17, 18, 18, 18,
    ...[for (var i = 0; i < 18; i++) 16],
    18, 18, 18, 17, 17, 17,
    27, 27, 3, 3,
    10, 10, 10, 10,
    ..._liftExposure(lift).reversed,
  ]);

  // Two blinks are needed in these longer rests to bound every unchanged
  // drawing to five seconds. Locations and pre/post rests change each cycle.
  // The five idle endpoint ticks in the squirrel action count toward the cap.
  static List<FriendRestVariant> _teaVariants(List<(int, double)> lift) {
    final action = _teaAction(lift);
    List<int> idle(int first, int second) =>
        _exposures([(0, first), (1, 1), (2, 2), (1, 1), (0, second)]);
    return List.unmodifiable([
      // The eight added inbetween ticks replace four idle ticks on each side,
      // preserving the authored 18/19/20s rhythm variants and 57s supercycle.
      FriendRestVariant(idle(18, 45), action, idle(45, 18)), // 18s
      FriendRestVariant(idle(20, 48), action, idle(50, 20)), // 19s
      FriendRestVariant(idle(24, 51), action, idle(51, 24)), // 20s
    ]);
  }

  static final List<FriendRestVariant> fennecRestVariants = _teaVariants(
    fennecTeaLift,
  );
  static final List<FriendRestVariant> squirrelRestVariants = _teaVariants(
    squirrelTeaLift,
  );
  static final List<int> windowTeaTimeline = _joinVariants(fennecRestVariants);
  static final List<int> squirrelTeaTimeline = _joinVariants(
    squirrelRestVariants,
  );
  static List<int> windowTeaTimelineFor(FocusFriend friend) =>
      friend == FocusFriend.squirrel ? squirrelTeaTimeline : windowTeaTimeline;

  static int windowTeaFrameAt(
    Duration elapsed, {
    FocusFriend friend = FocusFriend.fennec,
  }) {
    if (elapsed.isNegative) return 0;
    final timeline = windowTeaTimelineFor(friend);
    return timeline[_tick(elapsed) % timeline.length];
  }

  static int _tick(Duration elapsed) =>
      elapsed.inMicroseconds *
      framesPerSecond ~/
      Duration.microsecondsPerSecond;

  static Duration restDurationFor(FocusFriend friend) {
    // The panda uses its own clock; keep this legacy query unchanged as well.
    if (friend == FocusFriend.redpanda) return const Duration(seconds: 10);
    return Duration(
      microseconds:
          (restTimelineFor(friend).length *
                  Duration.microsecondsPerSecond /
                  framesPerSecond)
              .ceil(),
    );
  }

  static List<int> _exposures(List<(int, int)> holds) => List.unmodifiable([
    for (final (cel, ticks) in holds)
      for (var tick = 0; tick < ticks; tick++) cel,
  ]);
  static List<int> _joinVariants(List<FriendRestVariant> variants) =>
      List.unmodifiable([for (final variant in variants) ...variant.timeline]);

  // The original cup action is shared without retiming a single drawing.
  static final List<int> _penguinAction = _exposures([
    (4, 4),
    (5, 6),
    (6, 14),
    (5, 4),
    (4, 4),
  ]);
  // No blink art exists for the penguin. At least eight seconds plus its
  // 32-tick action would force an idle hold over 60 ticks. The user approved
  // 7-7.7s variants for this friend, retaining the five-second hold limit.
  static final List<FriendRestVariant> penguinRestVariants = List.unmodifiable([
    for (final before in [26, 30, 32])
      FriendRestVariant(
        _exposures([(3, before)]),
        _penguinAction,
        _exposures([(3, 28)]),
      ),
  ]);
  static final List<int> penguinRestTimeline = _joinVariants(
    penguinRestVariants,
  );

  static final List<int> _otterAction = _exposures([
    (3, 4),
    (4, 4),
    (6, 6),
    (7, 14),
    (6, 4),
    (4, 4),
    (3, 4),
  ]);
  static final List<FriendRestVariant> otterRestVariants = List.unmodifiable([
    FriendRestVariant(
      _exposures([(0, 28)]),
      _otterAction,
      _exposures([(0, 28)]),
    ), // 8s, no blink
    FriendRestVariant(
      _exposures([(0, 18), (1, 2), (0, 18)]),
      _otterAction,
      _exposures([(0, 30)]),
    ), // 9s, one blink
    FriendRestVariant(
      _exposures([(0, 28), (1, 2), (0, 10)]),
      _otterAction,
      _exposures([(0, 20), (1, 2), (0, 18)]),
    ), // 10s, two blinks
    FriendRestVariant(
      _exposures([(0, 22), (1, 2), (0, 26)]),
      _otterAction,
      _exposures([(0, 18), (1, 2), (0, 22)]),
    ), // 11s, two blinks
  ]);
  static final List<int> otterRestTimeline = _joinVariants(otterRestVariants);

  static List<FriendRestVariant> restVariantsFor(FocusFriend friend) =>
      switch (friend) {
        FocusFriend.penguin => penguinRestVariants,
        FocusFriend.squirrel => squirrelRestVariants,
        FocusFriend.fennec => fennecRestVariants,
        _ => otterRestVariants,
      };
  static List<int> restTimelineFor(FocusFriend friend) => switch (friend) {
    FocusFriend.penguin => penguinRestTimeline,
    FocusFriend.squirrel => squirrelTeaTimeline,
    FocusFriend.fennec => windowTeaTimeline,
    _ => otterRestTimeline,
  };

  // The panda's pen stroke: out and back through adjacent drawings in 4s,
  // with no snap from the last drawing to the first.
  static final List<int> writingTimeline = _exposures([
    (0, 6),
    (1, 5),
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 6),
    (4, 4),
    (3, 4),
    (2, 5),
    (1, 6),
  ]);
  // Three ticks per drawing, near the panda's two to three.
  // Cel 7 contained a duplicate pen and is deliberately unused.
  static final List<int> pageTurnTimeline = _exposures([
    (0, 1),
    for (final cel in [
      6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, //
    ])
      (cel, 3),
    (0, 2),
  ]);
  // The window friends' drawings were authored out of order: the fennec's
  // cel 12 holds the page lower than 10 and 11, and the squirrel's cel 18
  // stands the falling page taller than 17. Same drawings and ticks.
  static List<int> _pageTurn(List<int> cels) =>
      _exposures([(0, 1), for (final cel in cels) (cel, 3), (0, 2)]);
  static final List<int> fennecPageTurnTimeline = _pageTurn([
    6, 8, 9, 12, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, //
  ]);
  static final List<int> squirrelPageTurnTimeline = _pageTurn([
    6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 17, 19, 20, 21, 22, 23, //
  ]);
  static List<int> pageTurnTimelineFor(FocusFriend friend) => switch (friend) {
    FocusFriend.fennec => fennecPageTurnTimeline,
    FocusFriend.squirrel => squirrelPageTurnTimeline,
    _ => pageTurnTimeline,
  };

  static double _ease(double value) => value * value * (3 - 2 * value);

  static FriendMotionPose sample(
    Duration elapsed, {
    bool resting = false,
    FocusFriend friend = FocusFriend.otter,
  }) {
    if (resting) {
      final timeline = restTimelineFor(friend);
      final tick = elapsed.isNegative ? 0 : _tick(elapsed);
      final frame = timeline[tick % timeline.length];
      return FriendMotionPose(frame, frame, 0, FriendMotionPhase.tea);
    }
    final turn = pageTurnTimelineFor(friend);
    final writingTicks = writingLoops * writingTimeline.length;
    final tick = elapsed.isNegative
        ? 0
        : _tick(elapsed) % (writingTicks + turn.length);
    if (tick < writingTicks) {
      final cel = writingTimeline[tick % writingTimeline.length];
      return FriendMotionPose(cel, cel, 0, FriendMotionPhase.writing);
    }
    final cel = turn[tick - writingTicks];
    return FriendMotionPose(cel, cel, 0, FriendMotionPhase.pageTurn);
  }
}
