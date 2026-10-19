import 'focus_friend.dart';

enum FriendMotionPhase { writing, pageTurn, tea }

class FriendMotionPose {
  const FriendMotionPose(this.from, this.to, this.blend, this.phase);
  final int from, to;
  final double blend;
  final FriendMotionPhase phase;
}

/// A visual clock only. Pausing it never affects the saved focus timer.
abstract final class FriendMotionClock {
  static const writingLoops = 9;
  static const writingDuration = Duration(seconds: 36);
  static const studyDuration = Duration(milliseconds: 40500);
  static const restDuration = Duration(seconds: 10);
  static const windowTeaDuration = Duration(seconds: 22);
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
  static List<int> _teaTimeline(List<(int, double)> lift) => List.unmodifiable([
    ...[for (var i = 0; i < 30; i++) 0],
    1, 2, 2, 1,
    ...[for (var i = 0; i < 26; i++) 0],
    // Stop at the mouth. Old cels 11..15 raised the cup toward the nose.
    ..._liftExposure(lift),
    // Two authored inbetweens let lids and cup angle change gradually.
    3, 3, 27, 27,
    17, 17, 17, 18, 18, 18,
    ...[for (var i = 0; i < 18; i++) 16],
    18, 18, 18, 17, 17, 17,
    27, 27, 3, 3,
    10, 10, 10, 10,
    ..._liftExposure(lift).reversed,
    // The faster lift's spare time stays in these rests, keeping 22s.
    ...[for (var i = 0; i < 36; i++) 0],
    1, 2, 2, 1,
    ...[for (var i = 0; i < 48; i++) 0],
    1, 2, 2, 1,
    ...[for (var i = 0; i < 30; i++) 0],
  ]);
  static final List<int> windowTeaTimeline = _teaTimeline(fennecTeaLift);
  static final List<int> squirrelTeaTimeline = _teaTimeline(squirrelTeaLift);
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

  static Duration restDurationFor(FocusFriend friend) =>
      friend.hasWindowTeaMotion ? windowTeaDuration : restDuration;
  static List<int> _exposures(List<(int, int)> holds) => List.unmodifiable([
    for (final (cel, ticks) in holds)
      for (var tick = 0; tick < ticks; tick++) cel,
  ]);
  // The panda's ten-second rhythm: a long rest, quick 4-6 tick steps through
  // the lift, about a second at the cup and the same steps back down.
  // Lower the cup through the same poses, avoiding the abrupt return drawings.
  static final List<int> penguinRestTimeline = _exposures([
    (3, 40),
    (4, 4),
    (5, 6),
    (6, 14),
    (5, 4),
    (4, 4),
    (3, 48),
  ]);
  // Cel 3 holds the cup lower than cel 4, so it comes first on the way up.
  static final List<int> otterRestTimeline = _exposures([
    (0, 30),
    (1, 2),
    (0, 8),
    (3, 4),
    (4, 4),
    (6, 6),
    (7, 14),
    (6, 4),
    (4, 4),
    (3, 4),
    (0, 40),
  ]);

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

  static double _ease(double value) => value * value * (3 - 2 * value);

  static FriendMotionPose sample(
    Duration elapsed, {
    bool resting = false,
    FocusFriend friend = FocusFriend.otter,
  }) {
    if (resting) {
      if (friend.hasWindowTeaMotion) {
        final frame = windowTeaFrameAt(elapsed, friend: friend);
        return FriendMotionPose(frame, frame, 0, FriendMotionPhase.tea);
      }
      final timeline = friend == FocusFriend.penguin
          ? penguinRestTimeline
          : otterRestTimeline;
      final frame = timeline[_tick(elapsed) % timeline.length];
      return FriendMotionPose(frame, frame, 0, FriendMotionPhase.tea);
    }
    final writingTicks = writingLoops * writingTimeline.length;
    final tick = elapsed.isNegative
        ? 0
        : _tick(elapsed) % (writingTicks + pageTurnTimeline.length);
    if (tick < writingTicks) {
      final cel = writingTimeline[tick % writingTimeline.length];
      return FriendMotionPose(cel, cel, 0, FriendMotionPhase.writing);
    }
    final cel = pageTurnTimeline[tick - writingTicks];
    return FriendMotionPose(cel, cel, 0, FriendMotionPhase.pageTurn);
  }
}
