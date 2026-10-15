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
  static const restDuration = Duration(seconds: 14);
  static const windowTeaDuration = Duration(seconds: 22);
  // Like the panda: a 12fps timing grid selects one complete drawing.
  // Holds belong to the whole action; no per-cel easing or image blending.
  static const windowTeaFramesPerSecond = 12;
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
    final tick =
        elapsed.inMicroseconds *
        windowTeaFramesPerSecond ~/
        Duration.microsecondsPerSecond;
    return timeline[tick % timeline.length];
  }

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
  // Lower the cup through the same poses, avoiding the abrupt return drawings.
  static const penguinRestFrames = [3, 3, 3, 4, 5, 6, 6, 6, 5, 4, 3, 3, 3];
  static const otterRestFrames = [0, 1, 0, 4, 3, 6, 7, 7, 6, 3, 4, 0, 0];
  // Time to reach the next drawing; relaxed holds at the bottom and while sipping.
  static const restSegmentsMs = [
    2700,
    160,
    900,
    700,
    700,
    600,
    1600,
    600,
    700,
    700,
    900,
    3740,
  ];

  static double _ease(double value) => value * value * (3 - 2 * value);

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
      final frames = friend == FocusFriend.penguin
          ? penguinRestFrames
          : otterRestFrames;
      const segments = restSegmentsMs;
      var local = milliseconds % restDurationFor(friend).inMilliseconds;
      for (var i = 0; i < segments.length; i++) {
        final duration = segments[i];
        if (local < duration) {
          if (i < 2) {
            return FriendMotionPose(
              frames[i],
              frames[i],
              0,
              FriendMotionPhase.tea,
            );
          }
          return FriendMotionPose(
            frames[i],
            frames[i + 1],
            _ease(local / duration),
            FriendMotionPhase.tea,
          );
        }
        local -= duration;
      }
      return const FriendMotionPose(0, 0, 0, FriendMotionPhase.tea);
    }
    final local = milliseconds % studyDuration.inMilliseconds;
    if (local < writingDuration.inMilliseconds) {
      final stroke = (local % 3600) / 600;
      final index = stroke.floor();
      return FriendMotionPose(
        writingFrames[index],
        writingFrames[index + 1],
        _ease(stroke - index),
        FriendMotionPhase.writing,
      );
    }
    final turn = (local - writingDuration.inMilliseconds) / 350;
    final index = turn.floor().clamp(0, turnFrames.length - 2);
    return FriendMotionPose(
      turnFrames[index],
      turnFrames[index + 1],
      _ease(turn - index),
      FriendMotionPhase.pageTurn,
    );
  }
}
