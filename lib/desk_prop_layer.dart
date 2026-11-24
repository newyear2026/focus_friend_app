import 'package:flutter/material.dart';
import 'desk_props.dart';
import 'focus_friend.dart';
import 'room_ambience.dart';

/// Props drawn in the same 853 × 1844 coordinates as the room and actor.
/// The other friends already have their default lamp in the room plate and
/// their own mug in the actor art. Only their earned plant needs an overlay.
class DeskPropLayer extends StatelessWidget {
  const DeskPropLayer({
    super.key,
    required this.friend,
    required this.unlocked,
    required this.ambience,
  });

  final FocusFriend friend;
  final Set<String> unlocked;
  final RoomAmbience ambience;

  Rect _bounds(DeskProp prop) {
    if (friend == FocusFriend.redpanda) {
      return Rect.fromLTWH(prop.left, prop.top, prop.width, prop.height);
    }
    // Opaque pot bases sit on the left book stack, away from the moving
    // notebook, the tea cup and the fixed decorative plant by the window.
    return switch (friend) {
      FocusFriend.penguin => const Rect.fromLTWH(28, 936, 126, 126),
      FocusFriend.otter => const Rect.fromLTWH(42, 938, 124, 124),
      // Pot bases (84.6% down the art) rest mid-way on each top book cover:
      // squirrel cover y 1013–1032, fennec cover y 1048–1068.
      FocusFriend.squirrel => const Rect.fromLTWH(52, 932, 116, 116),
      FocusFriend.fennec => const Rect.fromLTWH(66, 954, 128, 128),
      FocusFriend.redpanda => throw StateError('Handled above'),
    };
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          end: switch (ambience) {
            RoomAmbience.night => const Color(0xFFFFF0D9),
            RoomAmbience.evening => const Color(0xFFFFF3E4),
            _ => Colors.white,
          },
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(seconds: 2),
        builder: (context, tint, _) => Stack(
          children: [
            for (final prop in [
              ...deskProps,
            ]..sort((a, b) => a.layer.compareTo(b.layer)))
              if (prop.isAvailable(unlocked) &&
                  (friend == FocusFriend.redpanda || prop.key == 'plant')) ...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PropContactShadow(prop, _bounds(prop)),
                  ),
                ),
                Positioned.fromRect(
                  rect: _bounds(prop),
                  child: AnimatedSwitcher(
                    key: ValueKey('desk-prop-${prop.key}'),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(seconds: 2),
                    transitionBuilder: (child, animation) =>
                        child.key == ValueKey(prop.sceneAsset(ambience))
                        ? FadeTransition(opacity: animation, child: child)
                        : child,
                    child: Image.asset(
                      prop.sceneAsset(ambience),
                      key: ValueKey(prop.sceneAsset(ambience)),
                      fit: prop.contain ? BoxFit.contain : BoxFit.fill,
                      color: tint,
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    ),
  );
}

class _PropContactShadow extends CustomPainter {
  const _PropContactShadow(this.prop, this.bounds);
  final DeskProp prop;
  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 853, size.height / 1844);
    final footprint = switch (prop.key) {
      'plant' => const Rect.fromLTWH(.265, .818, .50, .06),
      'mug' => const Rect.fromLTWH(.11, .836, .66, .06),
      _ => const Rect.fromLTWH(.51, .89, .47, .045),
    };
    canvas.drawOval(
      Rect.fromLTWH(
        bounds.left + bounds.width * footprint.left,
        bounds.top + bounds.height * footprint.top,
        bounds.width * footprint.width,
        bounds.height * footprint.height,
      ),
      Paint()
        ..color = const Color(0x66282031)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PropContactShadow oldDelegate) =>
      prop != oldDelegate.prop || bounds != oldDelegate.bounds;
}
