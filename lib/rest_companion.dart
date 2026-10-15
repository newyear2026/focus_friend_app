import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'rest_animation.dart';

/// The cushion belongs to the room; this layer contains only the panda and cup.
class RestCompanion extends StatefulWidget {
  const RestCompanion({super.key, required this.animate, this.paused = false});
  final bool animate, paused;

  @override
  State<RestCompanion> createState() => _RestCompanionState();
}

class _RestCompanionState extends State<RestCompanion>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker = createTicker(_tick);
  ImageStream? stream;
  ImageStreamListener? listener;
  ImageInfo? imageInfo;
  ImageStream? inbetweensStream;
  ImageStreamListener? inbetweensListener;
  ImageInfo? inbetweensInfo;
  Duration played = Duration.zero;
  Duration runBase = Duration.zero;
  int displayedTick = 0;
  bool reducedMotion = false;
  bool tickerEnabled = true;

  void _tick(Duration elapsed) {
    played = runBase + elapsed;
    final tick = RestAnimation.tickAt(played);
    if (tick != displayedTick) setState(() => displayedTick = tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (stream == null) {
      stream = const AssetImage(
        RestAnimation.asset,
      ).resolve(createLocalImageConfiguration(context));
      listener = ImageStreamListener((info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final oldInfo = imageInfo;
        setState(() => imageInfo = info);
        oldInfo?.dispose();
      });
      stream!.addListener(listener!);
    }
    if (inbetweensStream == null) {
      inbetweensStream = const AssetImage(
        RestAnimation.inbetweensAsset,
      ).resolve(createLocalImageConfiguration(context));
      inbetweensListener = ImageStreamListener((info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final oldInfo = inbetweensInfo;
        setState(() => inbetweensInfo = info);
        oldInfo?.dispose();
      });
      inbetweensStream!.addListener(inbetweensListener!);
    }
    _syncMotion();
  }

  @override
  void didUpdateWidget(RestCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.animate && !widget.paused && !reducedMotion && tickerEnabled) {
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
    imageInfo?.dispose();
    if (inbetweensListener != null) {
      inbetweensStream?.removeListener(inbetweensListener!);
    }
    inbetweensInfo?.dispose();
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: RestCompanionPainter(
        imageInfo?.image,
        reducedMotion ? Duration.zero : played,
        inbetweens: inbetweensInfo?.image,
      ),
    ),
  );
}

/// Full cel playback: the approved twelve drawings are rendered unchanged.
class RestCompanionPainter extends CustomPainter {
  RestCompanionPainter(this.atlas, this.elapsed, {this.inbetweens});
  final ui.Image? atlas, inbetweens;
  final Duration elapsed;
  int get frame => RestAnimation.frameAt(elapsed);

  @override
  void paint(Canvas canvas, Size size) {
    final image = atlas;
    if (image == null) return;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (frame >= 12 && inbetweens != null) {
      final extra = inbetweens!;
      final cell = extra.width / 2;
      // Register the complete drawing once. Source cells are 887px square;
      // the seat aligns to y=349 in the original 362px coordinate space.
      canvas.save();
      canvas.scale(size.width / 362, size.height / 362);
      canvas.drawImageRect(
        extra,
        Rect.fromLTWH((frame - 12) * cell, 0, cell, extra.height.toDouble()),
        const Rect.fromLTWH(19, 16, 354.8, 354.8),
        paint,
      );
      canvas.restore();
      return;
    }
    // While the extra atlas loads, hold the adjacent approved drawing.
    final originalFrame = switch (frame) {
      12 => 3,
      13 => 8,
      _ => frame,
    };
    final width = image.width / RestAnimation.columns;
    final height = image.height / RestAnimation.rows;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        originalFrame % RestAnimation.columns * width,
        originalFrame ~/ RestAnimation.columns * height,
        width,
        height,
      ),
      Offset.zero & size,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RestCompanionPainter oldDelegate) =>
      oldDelegate.atlas != atlas ||
      oldDelegate.inbetweens != inbetweens ||
      oldDelegate.frame != frame;
}
