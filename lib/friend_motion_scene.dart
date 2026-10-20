import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'focus_friend.dart';
import 'friend_motion_clock.dart';
import 'room_ambience.dart';

/// Registered connected cels over a fixed room; no independent limb rotations.
class FriendMotionScene extends StatefulWidget {
  const FriendMotionScene({
    super.key,
    required this.friend,
    required this.animate,
    required this.studying,
    required this.resting,
    required this.paused,
    this.ambience = RoomAmbience.evening,
  });
  final FocusFriend friend;
  final RoomAmbience ambience;
  final bool animate, studying, resting, paused;
  @override
  State<FriendMotionScene> createState() => _FriendMotionSceneState();
}

class _FriendMotionSceneState extends State<FriendMotionScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker ticker = createTicker(_tick);
  final streams = <String, ImageStream>{};
  final listeners = <String, ImageStreamListener>{};
  final images = <String, ImageInfo>{};
  Duration played = Duration.zero, runBase = Duration.zero;
  int displayedTick = 0;
  bool reduced = false, enabled = true, foreground = true;
  String? currentRoom, previousRoom;
  RoomAmbience? currentAmbience, previousAmbience;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool get ready =>
      currentRoom != null &&
      images.containsKey(widget.resting ? 'rest' : 'study');

  void _load(String name, {String? asset}) {
    if (streams.containsKey(name)) return;
    final friend = widget.friend;
    final stream = AssetImage(
      asset ?? '${friend.motionDirectory}/$name.png',
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted || widget.friend != friend) {
        info.dispose();
        return;
      }
      final previous = images[name];
      setState(() {
        images[name] = info;
        if (name == 'room-${widget.ambience.assetName}') _selectRoom(name);
      });
      previous?.dispose();
      _sync();
    });
    streams[name] = stream;
    listeners[name] = listener;
    stream.addListener(listener);
  }

  void _selectRoom(String name) {
    if (currentRoom == name) return;
    previousRoom = currentRoom;
    previousAmbience = currentAmbience;
    currentRoom = name;
    currentAmbience = widget.ambience;
  }

  void _loadRoom() {
    final name = 'room-${widget.ambience.assetName}';
    if (images.containsKey(name)) {
      _selectRoom(name);
    } else {
      _load(name, asset: widget.friend.restRoomAsset(widget.ambience));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    enabled = TickerMode.valuesOf(context).enabled;
    _loadRoom();
    if (!widget.resting && widget.friend.hasStudyMotion) _load('study');
    if (widget.resting) _load('rest');
    _sync();
  }

  void _tick(Duration elapsed) {
    played = runBase + elapsed;
    final tick =
        played.inMicroseconds *
        FriendMotionClock.framesPerSecond ~/
        Duration.microsecondsPerSecond;
    if (tick != displayedTick) setState(() => displayedTick = tick);
  }

  void _sync() {
    if (ready &&
        widget.animate &&
        !widget.paused &&
        (widget.studying || widget.resting) &&
        !reduced &&
        enabled &&
        foreground) {
      if (!ticker.isActive) {
        runBase = played;
        ticker.start();
      }
    } else {
      ticker.stop();
    }
  }

  @override
  void didUpdateWidget(FriendMotionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friend != widget.friend) {
      _releaseImages();
    }
    if (!widget.resting && widget.friend.hasStudyMotion) _load('study');
    if (oldWidget.friend != widget.friend ||
        oldWidget.ambience != widget.ambience) {
      _loadRoom();
    }
    if (oldWidget.friend != widget.friend ||
        oldWidget.resting != widget.resting ||
        oldWidget.studying != widget.studying) {
      ticker.stop();
      played = runBase = Duration.zero;
      displayedTick = 0;
    }
    if (widget.resting) _load('rest');
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _releaseImages() {
    for (final entry in streams.entries) {
      entry.value.removeListener(listeners[entry.key]!);
    }
    for (final info in images.values) {
      info.dispose();
    }
    streams.clear();
    listeners.clear();
    images.clear();
    currentRoom = previousRoom = null;
    currentAmbience = previousAmbience = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    _releaseImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return Image.asset(
        widget.friend.sceneAsset!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
      );
    }
    final elapsed = reduced || (!widget.studying && !widget.resting)
        ? Duration.zero
        : played;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 853,
          height: 1844,
          child: TweenAnimationBuilder<double>(
            key: ValueKey((widget.friend, currentRoom)),
            tween: Tween(begin: previousRoom == null ? 1 : 0, end: 1),
            duration: reduced ? Duration.zero : const Duration(seconds: 2),
            builder: (context, blend, child) => CustomPaint(
              key: const ValueKey('friend-motion-cels'),
              painter: FriendMotionScenePainter(
                room: images[currentRoom]!.image,
                previousRoom: images[previousRoom]?.image,
                roomBlend: blend,
                ambience: currentAmbience!,
                previousAmbience: previousAmbience,
                actor: FriendMotionPainter(
                  friend: widget.friend,
                  study: images['study']?.image,
                  rest: images['rest']?.image,
                  pose: FriendMotionClock.sample(
                    elapsed,
                    resting: widget.resting,
                    friend: widget.friend,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FriendMotionScenePainter extends CustomPainter {
  const FriendMotionScenePainter({
    required this.room,
    required this.actor,
    this.previousRoom,
    this.roomBlend = 1,
    this.ambience = RoomAmbience.evening,
    this.previousAmbience,
  });
  final ui.Image room;
  final ui.Image? previousRoom;
  final double roomBlend;
  final RoomAmbience ambience;
  final RoomAmbience? previousAmbience;
  final FriendMotionPainter actor;
  static const stage = Rect.fromLTWH(100, 570, 704, 704);
  static List<Color> _light(RoomAmbience ambience) => switch (ambience) {
    RoomAmbience.morning => const [Color(0xFFF1E4ED), Color(0xFFFFF3DF)],
    RoomAmbience.day => const [Colors.white, Colors.white],
    RoomAmbience.evening => const [Color(0xFFE6CBD3), Color(0xFFFFE9CA)],
    RoomAmbience.night => const [Color(0xFFC4B6C8), Color(0xFFF4D9B4)],
  };
  static Path get foregroundBooks => Path()
    ..moveTo(0, 1040)
    ..lineTo(272, 1038)
    ..lineTo(299, 1055)
    ..lineTo(293, 1098)
    ..lineTo(315, 1114)
    ..lineTo(315, 1150)
    ..lineTo(330, 1164)
    ..lineTo(330, 1198)
    ..lineTo(0, 1210)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 853, size.height / 1844);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    void drawRoom(ui.Image image, double opacity) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 853, 1844),
      paint..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    void roomPlate() {
      if (previousRoom != null && roomBlend < 1) {
        drawRoom(previousRoom!, 1);
        drawRoom(room, roomBlend);
      } else {
        drawRoom(room, 1);
      }
    }

    roomPlate();
    canvas.save();
    canvas.translate(stage.left, stage.top);
    final actorBounds = Offset.zero & stage.size;
    canvas.saveLayer(actorBounds, Paint());
    actor.paint(canvas, stage.size);
    final from = _light(previousAmbience ?? ambience);
    final to = _light(ambience);
    canvas.drawRect(
      actorBounds,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(from[0], to[0], roomBlend)!,
            Color.lerp(from[1], to[1], roomBlend)!,
          ],
        ).createShader(actorBounds)
        ..blendMode = BlendMode.modulate,
    );
    canvas.restore();
    canvas.restore();
    // The fixed foreground remains in front of the character and book.
    canvas.save();
    canvas.clipPath(foregroundBooks, doAntiAlias: false);
    roomPlate();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FriendMotionScenePainter oldDelegate) =>
      room != oldDelegate.room ||
      previousRoom != oldDelegate.previousRoom ||
      roomBlend != oldDelegate.roomBlend ||
      ambience != oldDelegate.ambience ||
      previousAmbience != oldDelegate.previousAmbience ||
      actor.shouldRepaint(oldDelegate.actor);
}

class FriendMotionPainter extends CustomPainter {
  const FriendMotionPainter({
    required this.friend,
    required this.study,
    required this.pose,
    this.rest,
  });
  final ui.Image? study;
  final FocusFriend friend;
  final ui.Image? rest;
  final FriendMotionPose pose;
  static const stageBounds = Rect.fromLTWH(0, 0, 512, 512);

  // The canonical face, scarf/whiskers, torso and cup never move while writing.
  static Path get writingRegion => Path()
    ..moveTo(137, 302)
    ..lineTo(186, 300)
    ..lineTo(224, 352)
    ..lineTo(237, 390)
    ..lineTo(177, 390)
    ..lineTo(130, 357)
    ..close()
    ..addRect(const Rect.fromLTWH(165, 285, 50, 50));

  static Path pageRegion(int frame) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(stageBounds),
      Path()..addRect(const Rect.fromLTWH(323, 320, 120, 125)),
    );
  }

  // Retain the same ears and closed book while the connected arms lift. The
  // rest cels redraw the whole outline, so the edges stay outside the
  // shoulders, whiskers and tail; a cut through them leaves a straight seam.
  Path get teaRegion => Path()
    ..addRect(const Rect.fromLTRB(40, 170, 370, 280))
    ..addRect(const Rect.fromLTRB(20, 272, 380, 392));

  void _cel(Canvas canvas, ui.Image atlas, int index, Paint paint) {
    final cell = atlas.width / 4;
    canvas.drawImageRect(
      atlas,
      Rect.fromLTWH(index % 4 * cell, index ~/ 4 * cell, cell, cell),
      stageBounds,
      paint,
    );
  }

  // The edited sip cels now share the same registered canonical body.
  // Every rest drawing uses the same fixed ears, tail, hat and back.
  static const Set<int> windowTeaWholeCels = {};

  // Authored connected forearms and paper move over an invariant study cel.
  // Protect the face, ears, tail, backpack, mug and bottom book-cover edge.
  static Path windowStudyRegion(
    FocusFriend friend, {
    required bool turningPage,
    required int cel,
  }) {
    final points = friend == FocusFriend.squirrel
        ? (turningPage
              ? const [
                  (151, 303),
                  (198, 291),
                  (258, 306),
                  (287, 312),
                  (328, 320),
                  (360, 326),
                  (388, 365),
                  (388, 397),
                  (123, 397),
                  (124, 351),
                ]
              : const [
                  (160, 300),
                  (193, 289),
                  (235, 298),
                  (263, 320),
                  (277, 350),
                  (277, 383),
                  (196, 381),
                  (153, 348),
                ])
        : (turningPage
              ? const [
                  (111, 320),
                  (151, 309),
                  (177, 295),
                  (199, 296),
                  (239, 322),
                  (299, 321),
                  (338, 315),
                  (364, 334),
                  (389, 370),
                  (390, 397),
                  (121, 397),
                  (108, 351),
                ]
              : const [
                  (110, 315),
                  (153, 302),
                  (176, 292),
                  (227, 300),
                  (259, 328),
                  (271, 360),
                  (270, 387),
                  (196, 391),
                  (112, 377),
                  (106, 345),
                ]);
    final moving = Path()
      ..addPolygon([
        for (final (x, y) in points) Offset(x.toDouble(), y.toDouble()),
      ], true);
    if (turningPage && cel >= 14 && cel <= 20) {
      moving.addRect(
        friend == FocusFriend.squirrel
            ? const Rect.fromLTRB(245, 280, 360, 380)
            : const Rect.fromLTRB(214, 290, 350, 380),
      );
    }
    final fixed = Path()
      ..addRect(
        friend == FocusFriend.squirrel
            ? const Rect.fromLTRB(362, 320, 470, 450)
            : const Rect.fromLTRB(360, 340, 480, 450),
      );
    if (friend == FocusFriend.squirrel) {
      fixed.addRect(const Rect.fromLTRB(110, 270, 160, 356));
    }
    return Path.combine(PathOperation.difference, moving, fixed);
  }

  void _windowStudy(Canvas canvas, ui.Image atlas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final region = windowStudyRegion(
      friend,
      turningPage: pose.phase == FriendMotionPhase.pageTurn,
      cel: pose.from,
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(stageBounds),
        region,
      ),
      doAntiAlias: false,
    );
    _cel(canvas, atlas, 0, paint);
    canvas.restore();
    canvas.save();
    canvas.clipPath(region, doAntiAlias: false);
    _cel(canvas, atlas, pose.from, paint);
    canvas.restore();
    canvas.restore();
  }

  // Graph-cut seams between the face, arms and cup and the resting body,
  // through the pixels where every lift drawing agrees with cel 0 (measured
  // in the 512px registered drawings). Each lift drawing redraws the whole
  // outline, so a cut elsewhere leaves a step and the body shimmers.
  static Path windowTeaRegion(FocusFriend friend) => Path()
    ..addPolygon([
      for (final (x, y)
          in friend == FocusFriend.squirrel
              ? const [
                  (232, 198), (231, 215), (223, 223), (214, 225), (213, 245), //
                  (207, 247), (207, 268), (210, 275), (206, 277), (206, 308),
                  (196, 314), (192, 325), (186, 329), (187, 512), (512, 512),
                  (512, 198), (285, 200), (284, 195), (252, 193),
                ]
              : const [
                  (133, 138), (133, 223), (175, 227), (188, 237), (188, 321), //
                  (183, 336), (183, 512), (512, 512), (512, 142), (368, 142),
                  (355, 150), (293, 148), (288, 142), (260, 141), (256, 137),
                  (197, 135), (196, 132),
                ])
        Offset(x.toDouble(), y.toDouble()),
    ], true);

  void _windowTea(Canvas canvas, ui.Image atlas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    // The full connected character and cup are authored together, as for the
    // panda. No mesh warping, crossfade, separate head or limb replacement.
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (pose.from == 0 || windowTeaWholeCels.contains(pose.from)) {
      _cel(canvas, atlas, pose.from, paint);
    } else {
      final region = windowTeaRegion(friend);
      canvas.save();
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(stageBounds),
          region,
        ),
        doAntiAlias: false,
      );
      _cel(canvas, atlas, 0, paint);
      canvas.restore();
      canvas.save();
      canvas.clipPath(region, doAntiAlias: false);
      _cel(canvas, atlas, pose.from, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tea = pose.phase == FriendMotionPhase.tea && rest != null;
    final atlas = tea ? rest! : study;
    if (atlas == null) return;
    if (tea && friend.hasWindowTeaMotion) {
      _windowTea(canvas, atlas, size);
      return;
    }
    if (!tea && friend.hasWindowTeaMotion) {
      _windowStudy(canvas, atlas, size);
      return;
    }
    final region = tea
        ? teaRegion
        : pose.phase == FriendMotionPhase.writing
        ? writingRegion
        : Path.combine(
            PathOperation.union,
            pageRegion(pose.from),
            pageRegion(pose.to),
          );
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(stageBounds),
        region,
      ),
      doAntiAlias: false,
    );
    _cel(canvas, atlas, 0, paint);
    canvas.restore();
    // One complete authored drawing at a time, as for the panda. Blending
    // neighbouring cels showed double cups, eyes and see-through paws.
    canvas.save();
    canvas.clipPath(region, doAntiAlias: false);
    _cel(canvas, atlas, pose.blend < .5 ? pose.from : pose.to, paint);
    canvas.restore();
    if (tea) {
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(105, 370, 245, 100));
      _cel(canvas, atlas, 0, paint);
      canvas.restore();
    }
    if (pose.phase == FriendMotionPhase.pageTurn &&
        deskPencilGapCels.contains(pose.from)) {
      canvas.save();
      canvas.clipPath(deskPencilRegion(friend), doAntiAlias: false);
      _cel(canvas, atlas, deskPencilSourceCel, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  // The penguin's and otter's page-turn cels 18 and 19 were drawn without the
  // pencil lying on the desk in front of the book, so it vanished for half a
  // second. Cel 17's pencil is laid back over them; its surroundings in this
  // outline are transparent table, so neither book cover is replaced.
  static const deskPencilGapCels = {18, 19};
  static const deskPencilSourceCel = 17;
  static Path deskPencilRegion(FocusFriend friend) => Path()
    ..addPolygon([
      for (final (x, y)
          in friend == FocusFriend.penguin
              ? const [
                  (179, 404), (179, 412), (182, 415), (192, 416), (193, 417), //
                  (264, 417), (282, 410), (282, 399), (269, 399), (268, 400),
                  (265, 399), (221, 399), (220, 400), (210, 400), (203, 402),
                ]
              : const [
                  (295, 422), (292, 417), (279, 415), (278, 412), (257, 413), //
                  (253, 417), (246, 417), (245, 418), (241, 418), (237, 416),
                  (223, 416), (222, 417), (188, 419), (187, 420), (180, 420),
                  (180, 422), (178, 424), (178, 434), (183, 439), (189, 441),
                  (244, 440), (245, 439), (289, 439), (293, 437), (295, 434),
                ])
        Offset(x.toDouble(), y.toDouble()),
    ], true);

  @override
  bool shouldRepaint(covariant FriendMotionPainter oldDelegate) =>
      friend != oldDelegate.friend ||
      study != oldDelegate.study ||
      rest != oldDelegate.rest ||
      pose.from != oldDelegate.pose.from ||
      pose.to != oldDelegate.pose.to ||
      pose.blend != oldDelegate.pose.blend ||
      pose.phase != oldDelegate.pose.phase;
}
