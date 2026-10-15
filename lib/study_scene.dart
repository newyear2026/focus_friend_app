import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'localized_names.dart';
import 'room_ambience.dart';
import 'reference_companion.dart';
import 'rest_companion.dart';
import 'focus_friend.dart';
import 'friend_motion_scene.dart';
export 'reference_companion.dart' show ReferenceCompanion;

class DeskIllustration extends StatelessWidget {
  const DeskIllustration({
    super.key,
    required this.unlocked,
    required this.ambience,
    this.studying = false,
    this.animate = false,
    this.paused = false,
    this.resting = false,
    this.friend = FocusFriend.redpanda,
  });
  final Set<String> unlocked;
  final RoomAmbience ambience;
  final bool studying;
  final bool animate;
  final bool paused;
  final bool resting;
  final FocusFriend friend;

  Color get _foregroundTint => switch (ambience) {
    RoomAmbience.night => const Color(0xFFBCC3E4),
    RoomAmbience.evening => const Color(0xFFFFDDCA),
    _ => Colors.white,
  };

  // Keep the authored cels intact. A gentle room light crosses the whole
  // silhouette, so every writing, page-turn and tea frame shares one light.
  Widget _roomLitCompanion(Widget child) => ShaderMask(
    blendMode: BlendMode.modulate,
    shaderCallback: (bounds) => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: switch (ambience) {
        RoomAmbience.evening => const [
          Color(0xFFD9BCC0),
          Color(0xFFF5D3BF),
          Color(0xFFFFE7BC),
        ],
        RoomAmbience.night => const [
          Color(0xFFC4B6C8),
          Color(0xFFD8C6C5),
          Color(0xFFF4D9B4),
        ],
        _ => const [Color(0xFFE8DADB), Color(0xFFFFF1DE), Color(0xFFFFF1D2)],
      },
      stops: const [0, .53, 1],
    ).createShader(bounds),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (friend != FocusFriend.redpanda) {
      return Semantics(
        image: true,
        label:
            '${friendName(l10n, friend)} · ${friendRoom(l10n, friend)} · ${ambienceName(l10n, ambience)}',
        child: RepaintBoundary(
          key: const ValueKey('study-scene'),
          child: friend.hasDeskMotion || (resting && friend.hasWindowTeaMotion)
              ? FriendMotionScene(
                  friend: friend,
                  ambience: ambience,
                  animate: animate,
                  studying: studying,
                  resting: resting,
                  paused: paused,
                )
              : _friendRoom(context),
        ),
      );
    }
    return Semantics(
      image: true,
      label: l10n.sceneLabel(
        ambienceName(l10n, ambience),
        resting
            ? (paused ? l10n.poseRestPaused : l10n.poseTea)
            : paused
            ? l10n.posePaused
            : studying
            ? l10n.poseWriting
            : l10n.poseWaiting,
        [
          if (unlocked.contains('plant')) l10n.propShortPlant,
          if (unlocked.contains('mug')) l10n.propShortMug,
          if (unlocked.contains('lamp')) l10n.propShortLamp,
        ].join(' '),
      ),
      child: ExcludeSemantics(
        child: RepaintBoundary(
          key: const ValueKey('study-scene'),
          child: _scene(context),
        ),
      ),
    );
  }

  Widget _friendRoom(BuildContext context) {
    final asset = friend.ambienceAsset(ambience);
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(seconds: 2),
      transitionBuilder: (child, animation) => child.key == ValueKey(asset)
          ? FadeTransition(opacity: animation, child: child)
          : child,
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
      ),
    );
  }

  // The foreground books are a clipped copy of the room, so both copies must
  // change together. The new room fades in over the opaque previous one.
  Widget _room(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(seconds: 2),
    transitionBuilder: (child, animation) => child.key == ValueKey(ambience)
        ? FadeTransition(opacity: animation, child: child)
        : child,
    child: Image.asset(
      ambience.asset,
      key: ValueKey(ambience),
      width: 853,
      height: 1844,
      fit: BoxFit.fill,
    ),
  );

  Widget _scene(BuildContext context) => ClipRect(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: 853,
        height: 1844,
        child: Stack(
          children: [
            Positioned.fill(child: _room(context)),
            if (!resting)
              const Positioned.fill(
                child: CustomPaint(painter: _DeskContactShadowPainter()),
              ),
            if (!resting)
              Positioned(
                left: 90,
                top: 610,
                width: 580,
                height: 580,
                child: _roomLitCompanion(
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _foregroundTint,
                      BlendMode.modulate,
                    ),
                    child: ReferenceCompanion(
                      studying: studying,
                      animate: animate,
                      paused: paused,
                    ),
                  ),
                ),
              ),
            if (!resting)
              Positioned.fill(
                child: ClipPath(
                  clipper: _ForegroundBooksClipper(),
                  child: _room(context),
                ),
              ),
            if (resting) ...[
              const Positioned.fill(
                child: CustomPaint(painter: _RestContactShadowPainter()),
              ),
              Positioned(
                left: 105,
                top: 680,
                width: 490,
                height: 377,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: 490,
                    maxWidth: 490,
                    minHeight: 490,
                    maxHeight: 490,
                    child: _roomLitCompanion(
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _foregroundTint,
                          BlendMode.modulate,
                        ),
                        child: RestCompanion(animate: animate, paused: paused),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 222,
                top: 1033,
                width: 330,
                height: 150,
                child: Image.asset(
                  'assets/images/rest/closed-book.png',
                  color: _foregroundTint,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            ],
            if (unlocked.contains('lamp'))
              Positioned(
                left: 608,
                top: 739,
                width: 266,
                height: 400,
                child: Image.asset(
                  'assets/images/immersive/reward-lamp.png',
                  fit: BoxFit.fill,
                  color: _foregroundTint,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            if (unlocked.contains('plant'))
              Positioned(
                left: 648,
                top: 957,
                width: 115,
                height: 138,
                child: Image.asset(
                  'assets/images/immersive/reward-plant.png',
                  fit: BoxFit.contain,
                  color: _foregroundTint,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            if (unlocked.contains('mug'))
              Positioned(
                left: 613,
                top: 1010,
                width: 156,
                height: 170,
                child: Image.asset(
                  'assets/images/immersive/reward-mug.png',
                  fit: BoxFit.fill,
                  color: _foregroundTint,
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            const Positioned.fill(child: ColoredBox(color: Color(0x0A11131F))),
          ],
        ),
      ),
    ),
  );
}

class _DeskContactShadowPainter extends CustomPainter {
  const _DeskContactShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 853;
    final sy = size.height / 1844;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawOval(
      const Rect.fromLTWH(276, 1090, 355, 76),
      Paint()
        ..color = const Color(0x66282031)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawOval(
      const Rect.fromLTWH(145, 1010, 220, 84),
      Paint()
        ..color = const Color(0x33282031)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeskContactShadowPainter oldDelegate) => false;
}

class _RestContactShadowPainter extends CustomPainter {
  const _RestContactShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 853, size.height / 1844);
    canvas.drawOval(
      const Rect.fromLTWH(191, 1001, 381, 73),
      Paint()
        ..color = const Color(0x54291724)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 21),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RestContactShadowPainter oldDelegate) => false;
}

class _ForegroundBooksClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final sx = size.width / 853;
    final sy = size.height / 1844;
    return Path()..addPolygon([
      Offset(0, 1035 * sy),
      Offset(294 * sx, 1035 * sy),
      Offset(345 * sx, 1198 * sy),
      Offset(0, 1198 * sy),
    ], true);
  }

  @override
  bool shouldReclip(covariant _ForegroundBooksClipper oldClipper) => false;
}
