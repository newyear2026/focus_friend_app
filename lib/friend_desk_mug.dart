import 'dart:ui';

import 'focus_friend.dart';

/// The authored desk mug in the canonical 512 × 512 study drawing.
///
/// These contours follow the cup rather than its rectangular fixed-cel region:
/// the hand and the visible edge of the open notebook touch its left side.
/// Removing this area from the study actor reveals the room plate underneath.
/// The held tea cup belongs to the rest animation and must not use this mask.
/// Coordinates include a small margin around the antialiased cup outline.
Path friendDeskMugMask(FocusFriend friend) {
  final points = switch (friend) {
    FocusFriend.penguin => const [
      (331.0, 331.0),
      (382.0, 331.0),
      (391.0, 340.0),
      (393.0, 345.0),
      (410.0, 346.0),
      (411.0, 378.0),
      (397.0, 390.0),
      (386.0, 395.0),
      (384.0, 400.0),
      (374.0, 403.0),
      (338.0, 403.0),
      (326.0, 398.0),
      (323.0, 388.0),
      (323.0, 347.0),
      (327.0, 337.0),
    ],
    FocusFriend.otter => const [
      (346.0, 341.0),
      (380.0, 341.0),
      (402.0, 349.0),
      (403.0, 357.0),
      (419.0, 357.0),
      (420.0, 392.0),
      (408.0, 407.0),
      (402.0, 412.0),
      (398.0, 422.0),
      (377.0, 428.0),
      (347.0, 428.0),
      (331.0, 419.0),
      (328.0, 395.0),
      (328.0, 357.0),
      (334.0, 347.0),
    ],
    FocusFriend.squirrel => const [
      (372.0, 323.0),
      (416.0, 323.0),
      (428.0, 330.0),
      (429.0, 337.0),
      (449.0, 337.0),
      (450.0, 366.0),
      (443.0, 378.0),
      (430.0, 384.0),
      (427.0, 394.0),
      (414.0, 401.0),
      (378.0, 401.0),
      (362.0, 394.0),
      (361.0, 340.0),
      (365.0, 331.0),
    ],
    FocusFriend.fennec => const [
      (375.0, 347.0),
      (428.0, 347.0),
      (440.0, 353.0),
      (441.0, 361.0),
      (465.0, 361.0),
      (466.0, 393.0),
      (458.0, 407.0),
      (438.0, 417.0),
      (433.0, 430.0),
      (417.0, 435.0),
      (382.0, 435.0),
      (369.0, 430.0),
      (364.0, 419.0),
      (361.0, 377.0),
      (361.0, 355.0),
      (367.0, 350.0),
    ],
    // The original friend already renders its earned mug as a separate asset.
    FocusFriend.redpanda => const <(double, double)>[],
  };
  return Path()..addPolygon([for (final (x, y) in points) Offset(x, y)], true);
}

/// Extend the exposed paper, page block and cover underneath the locked mug
/// using the adjacent strip of the same drawing. Coordinates are in cel space.
void paintUncoveredBookCorner(Canvas canvas, Image atlas, FocusFriend friend) {
  final corner = switch (friend) {
    FocusFriend.penguin => (321.0, 356.0, 356.0, 377.0, 390.5, .09),
    FocusFriend.otter => (326.0, 393.0, 344.0, 403.0, 411.0, .04),
    FocusFriend.squirrel => (358.0, 359.5, 393.0, 377.0, 392.0, .13),
    FocusFriend.fennec => (359.0, 373.0, 383.0, 386.0, 402.5, .05),
    FocusFriend.redpanda => null,
  };
  if (corner == null) return;
  final (join, top, tip, paper, bottom, slope) = corner;
  final outline = Path()
    ..moveTo(join - 2, top - 1)
    ..lineTo(tip - 1, paper - 1)
    ..quadraticBezierTo(tip, paper, tip, paper + 1)
    ..lineTo(tip + 1, bottom - 1)
    ..quadraticBezierTo(tip + 1, bottom, tip - 1, bottom)
    ..lineTo(join - 2, bottom + (tip - join + 2) * slope)
    ..close();
  canvas.save();
  canvas.clipPath(outline);
  // Reflect nearby paper into the gap. Cancel the reflected cover's slope
  // so that the line of the binding continues through the join.
  final span = tip - join + 3;
  final scale = atlas.width / (4 * 512);
  final strip = Rect.fromLTRB(join - span, top - 2, join + 2, bottom + 12);
  final src = Rect.fromLTRB(
    strip.left * scale,
    strip.top * scale,
    strip.right * scale,
    strip.bottom * scale,
  );
  canvas.save();
  canvas.translate(join, 0);
  canvas.skew(0, -2 * slope);
  canvas.scale(-1, 1);
  canvas.drawImageRect(
    atlas,
    src,
    strip.shift(Offset(-join, 0)),
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
  final edge = Path()
    ..moveTo(join - 1, top - .5)
    ..lineTo(tip - 1, paper - 1)
    ..quadraticBezierTo(tip, paper, tip, paper + 1)
    ..lineTo(tip + 1, bottom - 1)
    ..quadraticBezierTo(tip + 1, bottom, tip - 1, bottom);
  canvas.drawPath(
    edge,
    Paint()
      ..color = const Color(0xFF583F30)
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke,
  );
  canvas.restore();
}
