import 'dart:ui';

/// Decorative handwriting. It contains no user text and never stores records.
abstract final class ReferenceNotebookInk {
  static const words = 12;

  static List<Path> paths(List<double> guide) {
    Offset point(double u, double v) => Offset(
      guide[0] + guide[2] * u + guide[4] * v,
      guide[1] + guide[3] * u + guide[5] * v,
    );
    final result = <Path>[];
    for (var word = 0; word < words; word++) {
      final u = (word % 4) * .245;
      final v = (word ~/ 4) * .45;
      final first = point(u, v);
      final path = Path()..moveTo(first.dx, first.dy);
      final letters = word % 3 == 1 ? 3 : 4;
      for (var letter = 0; letter < letters; letter++) {
        final x = u + letter * .043;
        final a = point(x + .011, v - .13);
        final b = point(x + .024, v + .16);
        final c = point(x + .043, v + (letter.isEven ? -.01 : .04));
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
      }
      result.add(path);
    }
    return result;
  }

  static void paint(
    Canvas canvas,
    double progress,
    List<double> guide, {
    double visibleFraction = 1,
  }) {
    if (progress <= 0) return;
    Offset point(double u, double v) => Offset(
      guide[0] + guide[2] * u + guide[4] * v,
      guide[1] + guide[3] * u + guide[5] * v,
    );
    final paper = Path()
      ..addPolygon([
        point(-.03, -.2),
        point(visibleFraction + .015, -.2),
        point(visibleFraction + .015, 1.12),
        point(-.03, 1.12),
      ], true);
    canvas.save();
    canvas.clipPath(paper);
    final paint = Paint()
      ..color = const Color(0xB080563B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final written = progress.clamp(0.0, 1.0) * words;
    final strokes = paths(guide);
    for (var i = 0; i < strokes.length && i < written; i++) {
      final amount = (written - i).clamp(0.0, 1.0);
      if (amount == 1) {
        canvas.drawPath(strokes[i], paint);
      } else {
        for (final metric in strokes[i].computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * amount), paint);
        }
      }
    }
    canvas.restore();
  }
}
