import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'reference_study_animation.dart';
import 'reference_notebook_ink.dart';
import 'reference_notebook_page.dart';

/// Each cel contains the connected body, shoulders, arms and pencil.
class ReferenceCompanion extends StatefulWidget {
  const ReferenceCompanion({
    super.key,
    required this.animate,
    this.studying = false,
    this.paused = false,
  });

  static const asset = 'assets/images/immersive/redpanda-reference.png';
  final bool animate, studying, paused;

  @override
  State<ReferenceCompanion> createState() => _ReferenceCompanionState();
}

class _ReferenceCompanionState extends State<ReferenceCompanion>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker = createTicker(_tick);
  ImageStream? stream;
  ImageStreamListener? listener;
  ImageInfo? imageInfo;
  ImageStream? notebookStream;
  ImageStreamListener? notebookListener;
  ImageInfo? notebookImageInfo;
  Duration played = Duration.zero;
  Duration runBase = Duration.zero;
  ReferenceStudyPose pose = const ReferenceStudyPose(0);
  bool reducedMotion = false;
  bool tickerEnabled = true;

  void _tick(Duration elapsed) {
    played = runBase + elapsed;
    final next = ReferenceStudyAnimation.poseAt(played);
    if (next != pose) setState(() => pose = next);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (stream == null) {
      stream = const AssetImage(
        ReferenceStudyAnimation.bodyAsset,
      ).resolve(createLocalImageConfiguration(context));
      listener = ImageStreamListener((info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final previous = imageInfo;
        setState(() => imageInfo = info);
        previous?.dispose();
        _syncMotion();
      });
      stream!.addListener(listener!);
      notebookStream = const AssetImage(
        ReferenceStudyAnimation.notebookAsset,
      ).resolve(createLocalImageConfiguration(context));
      notebookListener = ImageStreamListener((info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final previous = notebookImageInfo;
        setState(() => notebookImageInfo = info);
        previous?.dispose();
        _syncMotion();
      });
      notebookStream!.addListener(notebookListener!);
    }
    _syncMotion();
  }

  @override
  void didUpdateWidget(ReferenceCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studying != oldWidget.studying) {
      ticker.stop();
      played = Duration.zero;
      runBase = Duration.zero;
      pose = const ReferenceStudyPose(0);
    }
    _syncMotion();
  }

  void _syncMotion() {
    if (imageInfo != null &&
        notebookImageInfo != null &&
        widget.studying &&
        widget.animate &&
        !widget.paused &&
        !reducedMotion &&
        tickerEnabled) {
      if (!ticker.isActive) {
        runBase = played;
        ticker.start();
      }
    } else {
      ticker.stop();
    }
  }

  @override
  void dispose() {
    if (listener != null) stream?.removeListener(listener!);
    if (notebookListener != null) {
      notebookStream?.removeListener(notebookListener!);
    }
    imageInfo?.dispose();
    notebookImageInfo?.dispose();
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePose = widget.studying && !reducedMotion
        ? pose
        : const ReferenceStudyPose(0);
    return RepaintBoundary(
      child: imageInfo == null || notebookImageInfo == null
          ? Image.asset(
              ReferenceCompanion.asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            )
          : CustomPaint(
              key: const ValueKey('reference-companion-cels'),
              painter: ReferenceCompanionPainter(
                imageInfo!.image,
                visiblePose.frame,
                notebook: notebookImageInfo!.image,
                turningPage: visiblePose.turningPage,
                inkProgress: visiblePose.ink,
              ),
            ),
    );
  }
}

/// Registered authored cels, with a stationary writing body and small strokes.
class ReferenceCompanionPainter extends CustomPainter {
  ReferenceCompanionPainter(
    this.atlas,
    this.frame, {
    required this.notebook,
    this.turningPage = false,
    this.inkProgress = 0,
  });
  final ui.Image atlas;
  final ui.Image notebook;
  final int frame;
  final bool turningPage;
  final double inkProgress;

  // Keep the face, torso and tail from the canonical drawing. Only the
  // connected writing forearm/pencil region changes. Both complete source cels
  // use exactly the same coordinates; no limb rotations or detached overlays.
  static Path get writingStrokeRegion => Path()
    ..moveTo(179, 318)
    ..lineTo(210, 318)
    ..quadraticBezierTo(224, 327, 240, 342)
    ..lineTo(279, 420)
    ..lineTo(267, 440)
    ..lineTo(139, 431)
    ..quadraticBezierTo(112, 395, 138, 345)
    ..quadraticBezierTo(153, 320, 179, 318)
    ..close()
    ..addPolygon(const [
      Offset(211, 314),
      Offset(245, 314),
      Offset(264, 363),
      Offset(230, 365),
    ], true);

  void _paintBody(Canvas canvas, Rect source, Rect destination, Paint paint) {
    if (frame == 0 || frame > 5) {
      canvas.drawImageRect(atlas, source, destination, paint);
      return;
    }
    final stroke = writingStrokeRegion;
    // Replace pixels inside the stroke region instead of drawing them over
    // the resting hand. This keeps a moving pencil from leaving double edges.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(destination),
        stroke,
      ),
      doAntiAlias: false,
    );
    canvas.drawImageRect(
      atlas,
      Rect.fromLTWH(0, 0, source.width, source.height),
      destination,
      paint,
    );
    canvas.restore();
    canvas.save();
    canvas.clipPath(stroke, doAntiAlias: false);
    canvas.drawImageRect(atlas, source, destination, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const columns = ReferenceStudyAnimation.columns;
    const rows = ReferenceStudyAnimation.rows;
    final width = atlas.width / columns;
    final height = atlas.height / rows;
    canvas.save();
    canvas.translate(size.width * 64 / 580, size.height * 35 / 580);
    canvas.scale(size.width * 500 / 580 / 512, size.height * 500 / 580 / 512);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 512, 466), doAntiAlias: false);
    canvas.drawImageRect(
      notebook,
      Rect.fromLTWH(
        0,
        0,
        notebook.width.toDouble(),
        notebook.height.toDouble(),
      ),
      const Rect.fromLTWH(172, 403, 320, 76),
      paint,
    );
    canvas.restore();
    // Ink and loose paper share fixed book coordinates.
    ReferenceNotebookInk.paint(canvas, inkProgress, const [
      207,
      435,
      80,
      -4,
      9,
      15,
    ]);
    final bodySource = Rect.fromLTWH(
      frame % columns * width,
      frame ~/ columns * height,
      width,
      height,
    );
    const bodyDestination = Rect.fromLTWH(0, 0, 512, 512);
    _paintBody(canvas, bodySource, bodyDestination, paint);
    if (turningPage) {
      final sheet = ReferenceNotebookPage.paint(canvas, frame);
      if (sheet != null) {
        // Depth ordering reuses the SAME complete cel at the SAME coordinates.
        // Only actual sprite pixels occlude paper, never rectangular holes.
        canvas.save();
        canvas.clipPath(ReferenceNotebookPage.hands(frame));
        canvas.drawImageRect(atlas, bodySource, bodyDestination, paint);
        canvas.restore();
      }
    }
    // The lower cover is always in front of a turning sheet's shadow.
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 466, 512, 46), doAntiAlias: false);
    canvas.drawImageRect(
      notebook,
      Rect.fromLTWH(
        0,
        0,
        notebook.width.toDouble(),
        notebook.height.toDouble(),
      ),
      const Rect.fromLTWH(172, 403, 320, 76),
      paint,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ReferenceCompanionPainter oldDelegate) =>
      oldDelegate.atlas != atlas ||
      oldDelegate.notebook != notebook ||
      oldDelegate.frame != frame ||
      oldDelegate.turningPage != turningPage ||
      oldDelegate.inkProgress != inkProgress;
}
