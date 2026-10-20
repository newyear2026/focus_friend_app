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
  // Five lift drawings each, picked by the measured upright rim height in the
  // registered 512px drawings (fennec 267-224px, squirrel 293-261px) so the
  // cup only rises. Other candidates sat too close together or ran backwards.
  static const fennecTeaLift = [20, 6, 23, 9, 10];
  static const squirrelTeaLift = [4, 5, 22, 8, 10];

  // The panda's tea shape: 4,4,2,2 ticks through the lift with a short hold at
  // the top, about a second at the mouth, and the same steps back down.
  // Rhythm variants only change the idle holds and blinks around it.
  static List<int> _teaAction(List<int> lift) => _exposures([
    (lift[0], 4), (lift[1], 4), (lift[2], 2), (lift[3], 2), (lift[4], 3), //
    // Two authored inbetweens let lids and cup angle change gradually.
    (3, 2), (27, 2),
    (17, 2), (18, 2), (16, 6), (18, 2), (17, 2),
    (27, 2), (3, 2),
    (lift[4], 3), (lift[3], 2), (lift[2], 2), (lift[1], 4), (lift[0], 4),
  ]);

  // A drink about every ten seconds, like the panda; the rest before and
  // after it and the blink change each cycle.
  static List<FriendRestVariant> _teaVariants(List<int> lift) {
    final action = _teaAction(lift);
    List<int> blink(int first, int second) =>
        _exposures([(0, first), (1, 1), (2, 2), (1, 1), (0, second)]);
    return List.unmodifiable([
      FriendRestVariant(blink(28, 8), action, _exposures([(0, 28)])), // 10s
      FriendRestVariant(blink(20, 20), action, blink(22, 10)), // 11s
      FriendRestVariant(_exposures([(0, 34)]), action, _exposures([(0, 28)])),
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

  // The panda's tea shape on the otter's own drawings. Cel 5 (cup high, eyes
  // closing) sits between 4 and 6; cels 2 and 8-11 shift the whole body.
  static final List<int> _otterAction = _exposures([
    (3, 4), (4, 4), (5, 4), (6, 6), //
    (7, 12),
    (6, 4), (5, 4), (4, 4), (3, 6),
  ]);
  static final List<FriendRestVariant> otterRestVariants = List.unmodifiable([
    FriendRestVariant(
      _exposures([(0, 28), (1, 2), (0, 10)]),
      _otterAction,
      _exposures([(0, 32)]),
    ), // 10s, one blink
    FriendRestVariant(
      _exposures([(0, 22), (1, 2), (0, 20)]),
      _otterAction,
      _exposures([(0, 20), (1, 2), (0, 18)]),
    ), // 11s, two blinks
    FriendRestVariant(
      _exposures([(0, 30)]),
      _otterAction,
      _exposures([(0, 30)]),
    ), // 9s, no blink
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
