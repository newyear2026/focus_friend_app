import 'package:flutter/material.dart';
import 'desk_props.dart';
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
    RoomAmbience.night => const Color(0xFFFFF0D9),
    RoomAmbience.evening => const Color(0xFFFFF3E4),
    _ => Colors.white,
  };

  // Keep the authored cels intact. A gentle room light crosses the whole
  // silhouette, so every writing, page-turn and tea frame shares one light.
  // Apply it once: a second blue night tint used to muddy the orange fur.
  Widget _roomLitCompanion(Widget child) => ShaderMask(
    blendMode: BlendMode.modulate,
    shaderCallback: (bounds) => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: switch (ambience) {
        RoomAmbience.evening => const [
          Color(0xFFFFE8D6),
          Color(0xFFFFF4DF),
          Color(0xFFFFF5D5),
        ],
        RoomAmbience.night => const [
          Color(0xFFFFDFBD),
          Color(0xFFFFF1D3),
          Color(0xFFFFFFE8),
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
          child: friend.hasStudyMotion || (resting && friend.hasWindowTeaMotion)
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
          for (final prop in deskProps)
            if (prop.isAvailable(unlocked)) propShortName(l10n, prop.key),
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

  Widget _roomImage() =>
      Image.asset(ambience.asset, width: 853, height: 1844, fit: BoxFit.fill);

  // Light the desk and nearby furniture while keeping the upper night sky
  // untouched. Grading the plate here also keeps the foreground cutouts aligned.
  Widget _litRoomPlate() => SizedBox(
    key: ValueKey(ambience),
    width: 853,
    height: 1844,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _roomImage(),
        if (ambience == RoomAmbience.night || ambience == RoomAmbience.evening)
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0, .43, .56, .70, 1],
            ).createShader(bounds),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(
                ambience == RoomAmbience.night
                    ? const [
                        1.32,
                        0,
                        0,
                        0,
                        10,
                        0,
                        1.17,
                        0,
                        0,
                        5,
                        0,
                        0,
                        .99,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]
                    : const [
                        1.13,
                        0,
                        0,
                        0,
                        3,
                        0,
                        1.08,
                        0,
                        0,
                        2,
                        0,
                        0,
                        1,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ],
              ),
              child: _roomImage(),
            ),
          ),
      ],
    ),
  );

  // Foreground books and the pen cup are clipped copies of this same lit plate.
  // The new room fades in over the opaque previous one.
  Widget _room(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(seconds: 2),
    transitionBuilder: (child, animation) => child.key == ValueKey(ambience)
        ? FadeTransition(opacity: animation, child: child)
        : child,
    child: _litRoomPlate(),
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
                  ReferenceCompanion(
                    studying: studying,
                    animate: animate,
                    paused: paused,
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
                      RestCompanion(animate: animate, paused: paused),
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
            for (final prop in [
              ...deskProps,
            ]..sort((a, b) => a.layer.compareTo(b.layer)))
              if (prop.isAvailable(unlocked)) ...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DeskPropContactShadowPainter(prop),
                  ),
                ),
                Positioned(
                  left: prop.left,
                  top: prop.top,
                  width: prop.width,
                  height: prop.height,
                  child: Image.asset(
                    prop.asset,
                    fit: prop.contain ? BoxFit.contain : BoxFit.fill,
                    color: _foregroundTint,
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ],
            Positioned.fill(
              child: ClipPath(
                clipper: _ForegroundPenCupClipper(),
                child: _room(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeskPropContactShadowPainter extends CustomPainter {
  const _DeskPropContactShadowPainter(this.prop);

  final DeskProp prop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 853, size.height / 1844);
    // These footprints follow the opaque bases inside the sprite padding.
    // Each shadow is drawn directly beneath its prop in the same depth order.
    final footprint = switch (prop.key) {
      'plant' => const Rect.fromLTWH(.265, .818, .50, .06),
      'mug' => const Rect.fromLTWH(.11, .836, .66, .06),
      _ => const Rect.fromLTWH(.51, .89, .47, .045),
    };
    canvas.drawOval(
      Rect.fromLTWH(
        prop.left + prop.width * footprint.left,
        prop.top + prop.height * footprint.top,
        prop.width * footprint.width,
        prop.height * footprint.height,
      ),
      Paint()
        ..color = const Color(0x66282031)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeskPropContactShadowPainter oldDelegate) =>
      prop != oldDelegate.prop;
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

// The pen cup belongs to the room plate. Repaint its silhouette over the lamp
// so the lamp base can sit behind it instead of crossing the middle of the cup.
class _ForegroundPenCupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(778, 1043)
      ..quadraticBezierTo(792, 1031, 853, 1035)
      ..lineTo(853, 1145)
      ..quadraticBezierTo(812, 1146, 780, 1133)
      ..close()
      ..addPolygon(const [
        Offset(770, 1012),
        Offset(778, 947),
        Offset(839, 959),
        Offset(833, 1027),
      ], true)
      ..addPolygon(const [
        Offset(789, 1010),
        Offset(806, 1005),
        Offset(820, 1048),
        Offset(799, 1048),
      ], true)
      ..addPolygon(const [
        Offset(825, 1046),
        Offset(838, 970),
        Offset(849, 967),
        Offset(853, 977),
        Offset(841, 1048),
      ], true);
    return path.transform(
      Matrix4.diagonal3Values(size.width / 853, size.height / 1844, 1).storage,
    );
  }

  @override
  bool shouldReclip(covariant _ForegroundPenCupClipper oldClipper) => false;
}
