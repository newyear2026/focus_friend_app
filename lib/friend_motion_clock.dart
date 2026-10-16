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
  static const writingDuration = Duration(seconds: 36);
  static const turnDuration = Duration(milliseconds: 6300);
  static const studyDuration = Duration(milliseconds: 42300);
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
  static List<int> _liftExposure(List<(int, double)> poses) => [
    for (var tick = 0; tick < 42; tick++)
      poses.reduce((a, b) {
        final y =
            poses.first.$2 +
            (poses.last.$2 - poses.first.$2) * _ease(tick / 41);
        return (a.$2 - y).abs() <= (b.$2 - y).abs() ? a : b;
      }).$1,
  ];
  static List<int> _teaTimeline(List<(int, double)> lift) => List.unmodifiable([
    ...[for (var i = 0; i < 30; i++) 0],
    1, 2, 2, 1,
    ...[for (var i = 0; i < 26; i++) 0],
    // Stop at the mouth. Old cels 11..15 raised the cup toward the nose.
    ..._liftExposure(lift),
    17, 17, 17, 18, 18, 18,
    ...[for (var i = 0; i < 18; i++) 16],
    18, 18, 18, 17, 17, 17,
    10, 10, 10, 10,
    ..._liftExposure(lift).reversed,
    ...[for (var i = 0; i < 22; i++) 0],
    1, 2, 2, 1,
    ...[for (var i = 0; i < 26; i++) 0],
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
  static const writingFrames = [0, 1, 2, 3, 4, 5, 0];
  // Cel 7 contained a duplicate pen and is deliberately unused.
  static const turnFrames = [
    0,
    6,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    0,
  ];
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

  static double _ease(double value) => value * value * (3 - 2 * value);

  // One authored drawing at a time, switching halfway through each step.
  // Blending neighbouring cels showed two cups and see-through paws.
  static FriendMotionPose _expose(
    int from,
    int to,
    double progress,
    FriendMotionPhase phase,
  ) {
    final cel = progress < .5 ? from : to;
    return FriendMotionPose(cel, cel, 0, phase);
  }

  static FriendMotionPose sample(
    Duration elapsed, {
    bool resting = false,
    FocusFriend friend = FocusFriend.otter,
  }) {
    final milliseconds = elapsed.isNegative ? 0 : elapsed.inMicroseconds / 1000;
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
    final local = milliseconds % studyDuration.inMilliseconds;
    if (local < writingDuration.inMilliseconds) {
      final stroke = (local % 3600) / 600;
      final index = stroke.floor();
      return _expose(
        writingFrames[index],
        writingFrames[index + 1],
        stroke - index,
        FriendMotionPhase.writing,
      );
    }
    final turn = (local - writingDuration.inMilliseconds) / 350;
    final index = turn.floor().clamp(0, turnFrames.length - 2);
    return _expose(
      turnFrames[index],
      turnFrames[index + 1],
      turn - index,
      FriendMotionPhase.pageTurn,
    );
  }
}
