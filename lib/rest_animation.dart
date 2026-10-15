/// Fourteen complete drawings on the original relaxed ten-second tea loop.
abstract final class RestAnimation {
  static const asset = 'assets/images/rest/redpanda-tea-sheet.png';
  static const inbetweensAsset =
      'assets/images/rest/redpanda-tea-inbetweens.png';
  static const columns = 4;
  static const rows = 3;
  static const frameCount = 14;
  // A timing grid, not the number of drawings or the display refresh rate.
  static const framesPerSecond = 12;
  static const cycleTicks = 120;

  static final List<int> timeline = List.unmodifiable([
    for (final (frame, ticks) in [
      (0, 30),
      (1, 2),
      (0, 8),
      (2, 4),
      (3, 4),
      (12, 2),
      (4, 2),
      (5, 6),
      (6, 12),
      (7, 4),
      (8, 4),
      (13, 2),
      (9, 2),
      (10, 6),
      (11, 32),
    ])
      for (var tick = 0; tick < ticks; tick++) frame,
  ]);

  static int tickAt(Duration elapsed) =>
      elapsed.inMicroseconds *
      framesPerSecond ~/
      Duration.microsecondsPerSecond;

  static int frameAt(Duration elapsed) =>
      elapsed.isNegative ? 0 : timeline[tickAt(elapsed) % timeline.length];
}
