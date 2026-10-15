/// A visual clock, independent of focus sessions and saved records.
abstract final class ReferenceStudyAnimation {
  static const bodyAsset =
      'assets/images/immersive/redpanda-slow-connected-body-38.png';
  static const notebookAsset =
      'assets/images/immersive/redpanda-fixed-notebook.png';
  static const columns = 6;
  static const rows = 7;
  static const fps = 12;
  static const writingCycleTicks = 48;
  static const writingLoops = 9;
  static const writingTicks = writingLoops * writingCycleTicks;

  // Small pen strokes travel out and back. Each join is an adjacent drawing;
  // there is no preparation/return hold on every writing cycle.
  static final List<int> writingTimeline = List.unmodifiable([
    for (final (cel, ticks) in const [
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
    ])
      for (var hold = 0; hold < ticks; hold++) cel,
  ]);

  // The exact writing rest cel starts and ends the turn. Whole connected
  // bridge drawings carry the reaching/returning arm between the actions.
  static final List<int> pageTurnTimeline = List.unmodifiable([
    for (final (cel, ticks) in const [
      (0, 1),
      (18, 3),
      (19, 3),
      (20, 3),
      (7, 3),
      (24, 2),
      (25, 2),
      (26, 2),
      (33, 2),
      (31, 2),
      (9, 2),
      (8, 2),
      (10, 2),
      (27, 2),
      (28, 2),
      (34, 2),
      (12, 3),
      (13, 3),
      (36, 3),
      (21, 3),
      (14, 3),
      (15, 3),
      (37, 3),
      (29, 3),
      (22, 3),
      (23, 3),
      (0, 1),
    ])
      for (var hold = 0; hold < ticks; hold++) cel,
  ]);
  static int get pageTurnTicks => pageTurnTimeline.length;
  static int get cycleTicks => writingTicks + pageTurnTicks;

  static int tickAt(Duration elapsed) =>
      elapsed.isNegative ? 0 : elapsed.inMicroseconds * fps ~/ 1000000;

  static ReferenceStudyPose poseAt(Duration elapsed) {
    final tick = tickAt(elapsed) % cycleTicks;
    if (tick >= writingTicks) {
      final local = tick - writingTicks;
      final cel = pageTurnTimeline[local];
      final settled = pageTurnTimeline.indexOf(15);
      return ReferenceStudyPose(
        cel,
        turningPage: true,
        ink: local < settled ? 1 : 0,
      );
    }
    return ReferenceStudyPose(
      writingTimeline[tick % writingCycleTicks],
      ink: tick / writingTicks,
    );
  }
}

class ReferenceStudyPose {
  const ReferenceStudyPose(
    this.frame, {
    this.turningPage = false,
    this.ink = 0,
  });
  final int frame;
  final bool turningPage;
  final double ink;

  @override
  bool operator ==(Object other) =>
      other is ReferenceStudyPose &&
      other.frame == frame &&
      other.turningPage == turningPage &&
      other.ink == ink;

  @override
  int get hashCode => Object.hash(frame, turningPage, ink);
}
