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
