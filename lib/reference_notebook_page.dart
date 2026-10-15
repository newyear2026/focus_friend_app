import 'dart:ui';

/// Only the loose sheet moves. Its two spine points never leave the notebook.
/// The outer corner follows the grip in the connected, authored body drawing.
abstract final class ReferenceNotebookPage {
  static const spineTop = Offset(326, 412);
  static const spineBottom = Offset(341, 463);

  // Grip / lower outer corner / curl. Coordinates are in the fixed 512px cel.
  static const shapes = <int, (Offset, Offset, double)>{
    7: (Offset(463, 409), Offset(484, 454), 3),
    9: (Offset(394, 351), Offset(439, 437), 20),
    8: (Offset(402, 321), Offset(405, 431), 18),
    10: (Offset(372, 330), Offset(371, 435), 7),
    12: (Offset(347, 361), Offset(305, 445), -12),
    13: (Offset(338, 389), Offset(258, 454), -18),
    14: (Offset(288, 396), Offset(189, 459), -4),
    24: (Offset(433, 390), Offset(466, 447), 8),
    25: (Offset(420, 369), Offset(451, 442), 14),
    26: (Offset(406, 354), Offset(441, 438), 18),
    27: (Offset(372, 340), Offset(352, 438), -2),
    28: (Offset(360, 356), Offset(330, 443), -8),
    21: (Offset(305, 378), Offset(223, 456), -14),
    31: (Offset(404, 341), Offset(436, 437), 19),
    33: (Offset(400, 355), Offset(439, 438), 18),
    34: (Offset(365, 366), Offset(319, 444), -10),
    36: (Offset(334, 389), Offset(240.5, 455), -16),
  };

  static const paws = <int, Offset>{
    7: Offset(433, 396),
    8: Offset(392, 335),
    9: Offset(407, 356),
    10: Offset(393, 333),
    12: Offset(368, 371),
    13: Offset(357, 399),
    14: Offset(314, 396),
    24: Offset(437, 403),
    25: Offset(420, 388),
    26: Offset(415, 368),
    27: Offset(401, 344),
    28: Offset(388, 368),
    21: Offset(319, 388),
    31: Offset(412, 355),
    33: Offset(408, 369),
    34: Offset(391, 380),
    36: Offset(345, 400),
  };

  static Path hands(int cel) => Path()
    ..addOval(Rect.fromCenter(center: paws[cel]!, width: 68, height: 57))
    ..addRect(const Rect.fromLTWH(160, 330, 111, 110));

  static Path? paint(Canvas canvas, int cel) {
    final shape = shapes[cel];
    if (shape == null) return null;
    final (grip, bottom, curl) = shape;
    // As the sheet settles, the paw presses the upper edge while the released
    // outer corner reaches the left edge of the book. Cover all old ink before
    // clearing it; a still-curled triangle would leave the first words exposed.
    final outerTop = switch (cel) {
      21 => const Offset(240, 406),
      14 => const Offset(191, 414),
      36 => const Offset(289, 397.5),
      _ => grip,
    };
    final topControl = switch (cel) {
      21 || 14 => grip,
      36 => const Offset(318.5, 381),
      _ => Offset((spineTop.dx + grip.dx) / 2, grip.dy - 5),
    };
    final edge = (outerTop + bottom) / 2 + Offset(curl, 0);
    final page = Path()
      ..moveTo(spineTop.dx, spineTop.dy)
      ..quadraticBezierTo(
        topControl.dx,
        topControl.dy,
        outerTop.dx,
        outerTop.dy,
      )
      ..quadraticBezierTo(edge.dx, edge.dy, bottom.dx, bottom.dy)
      ..quadraticBezierTo(
        (bottom.dx + spineBottom.dx) / 2,
        spineBottom.dy - 3,
        spineBottom.dx,
        spineBottom.dy,
      )
      ..close();
    canvas.drawShadow(page, const Color(0x554E3425), 2, false);
    canvas.drawPath(
      page,
      Paint()
        ..shader = Gradient.linear(
          spineTop,
          grip,
          const [Color(0xFFE8D0AD), Color(0xFFFFEBD1), Color(0xFFFFF3DF)],
          const [0, .3, 1],
        ),
    );
    canvas.drawPath(
      page,
      Paint()
        ..color = const Color(0xC0987357)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.save();
    canvas.clipPath(page);
    final ruling = Paint()
      ..color = const Color(0x507F593C)
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    for (var row = 1; row < 7; row++) {
      final fraction = row / 8;
      final start = Offset.lerp(spineTop, spineBottom, fraction)!;
      final end = Offset.lerp(outerTop, bottom, fraction)!;
      canvas.drawPath(
        Path()
          ..moveTo(start.dx + (end.dx - start.dx) * .08, start.dy)
          ..quadraticBezierTo(
            (start.dx + end.dx) / 2 + curl * .3,
            (start.dy + end.dy) / 2 - 3,
            end.dx - (end.dx - start.dx) * .07,
            end.dy,
          ),
        ruling,
      );
    }
    canvas.restore();
    return page;
  }
}
