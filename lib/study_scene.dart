import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'room_ambience.dart';

class DeskIllustration extends StatelessWidget {
  const DeskIllustration({
    super.key,
    required this.unlocked,
    required this.ambience,
    this.studying = false,
    this.animate = false,
    this.paused = false,
  });
  final Set<String> unlocked;
  final RoomAmbience ambience;
  final bool studying;
  final bool animate;
  final bool paused;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        '${ambience.label}의 책상. ${paused
            ? '잠시 쉬는'
            : studying
            ? '노트에 필기하고 페이지를 넘기는'
            : '책상에서 기다리는'} 랫서팬더. '
        '얻은 소품 ${unlocked.contains('plant') ? '화분 ' : ''}'
        '${unlocked.contains('mug') ? '머그컵 ' : ''}'
        '${unlocked.contains('lamp') ? '조명' : ''}',
    child: ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey('study-scene'),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1182,
            height: 1330,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(seconds: 2),
                    child: Image.asset(
                      ambience.asset,
                      key: ValueKey(ambience),
                      width: 1182,
                      height: 1330,
                    ),
                  ),
                ),
                Positioned(
                  left: 342,
                  top: 335,
                  width: 440,
                  height: 440,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(switch (ambience) {
                      RoomAmbience.night => const Color(0xFFBCC3E4),
                      RoomAmbience.evening => const Color(0xFFFFDDCA),
                      _ => Colors.white,
                    }, BlendMode.modulate),
                    child: StudyCompanion(
                      studying: studying,
                      animate: animate,
                      paused: paused,
                    ),
                  ),
                ),
                if (unlocked.contains('lamp'))
                  Positioned(
                    left: 742,
                    top: 622,
                    width: 152,
                    height: 216,
                    child: Image.asset('assets/images/reward-lamp.png'),
                  ),
                if (unlocked.contains('plant'))
                  Positioned(
                    left: 692,
                    top: 644,
                    width: 114,
                    height: 164,
                    child: Image.asset('assets/images/reward-plant.png'),
                  ),
                if (unlocked.contains('mug'))
                  Positioned(
                    left: 637,
                    top: 789,
                    width: 95,
                    height: 99,
                    child: Image.asset('assets/images/reward-mug.png'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Decorative motion never changes the durable focus timer.
class StudyCompanion extends StatefulWidget {
  const StudyCompanion({
    super.key,
    required this.studying,
    required this.animate,
    this.paused = false,
  });
  final bool studying, animate, paused;
  @override
  State<StudyCompanion> createState() => _StudyCompanionState();
}

class _StudyCompanionState extends State<StudyCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: StudyMotion.cycleSeconds),
  );
  ImageStream? stream;
  ImageStreamListener? listener;
  ImageInfo? imageInfo;
  bool reducedMotion = false;
  bool tickerEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (stream == null) {
      stream = const AssetImage(
        'assets/images/redpanda-study-sheet.png',
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
    _syncMotion();
  }

  @override
  void didUpdateWidget(StudyCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studying != oldWidget.studying) motion.value = 0;
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.studying &&
        widget.animate &&
        !widget.paused &&
        !reducedMotion &&
        tickerEnabled) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
    }
  }

  @override
  void dispose() {
    if (listener != null) stream?.removeListener(listener!);
    imageInfo?.dispose();
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: motion,
      builder: (context, _) => CustomPaint(
        painter: StudyCompanionPainter(
          imageInfo?.image,
          widget.studying ? motion.value * StudyMotion.cycleSeconds : -1,
          resting: widget.paused,
          reducedMotion: reducedMotion,
        ),
      ),
    ),
  );
}

/// Mostly quiet handwriting, with a short review and a deliberate page turn.
abstract final class StudyMotion {
  static const cycleSeconds = 24;
  static const writingFrames = [1, 2, 3, 2];

  static ({int previous, int current, double blend}) sample(double seconds) {
    final t = seconds % cycleSeconds;
    int previous, current;
    double elapsed;
    if (t < 16) {
      final stroke = (t / .8).floor();
      current = writingFrames[stroke % 4];
      previous = stroke == 0 ? 1 : writingFrames[(stroke + 3) % 4];
      elapsed = t - stroke * .8;
    } else if (t < 19) {
      previous = 2;
      current = 4;
      elapsed = t - 16;
    } else if (t < 19.8) {
      previous = 4;
      current = 5;
      elapsed = t - 19;
    } else if (t < 21.2) {
      previous = 5;
      current = 6;
      elapsed = t - 19.8;
    } else if (t < 22) {
      previous = 6;
      current = 7;
      elapsed = t - 21.2;
    } else {
      previous = 7;
      current = 1;
      elapsed = t - 22;
    }
    return (
      previous: previous,
      current: current,
      blend: Curves.easeInOut.transform((elapsed / .16).clamp(0.0, 1.0)),
    );
  }
}

class StudyCompanionPainter extends CustomPainter {
  StudyCompanionPainter(
    this.sheet,
    this.seconds, {
    this.resting = false,
    this.reducedMotion = false,
  });
  final ui.Image? sheet;
  final double seconds;
  final bool resting, reducedMotion;

  // Full-cell registration corrections in the 512px authoring coordinate space.
  static const offsets = [
    Offset.zero,
    Offset(-.5772, 0),
    Offset.zero,
    Offset(-.5772, 0),
    Offset(0, .5772),
    Offset(-.5772, .5772),
    Offset(0, .5772),
    Offset(-.5772, .5772),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (sheet == null) return;
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final cellWidth = sheet!.width / 4;
    final cellHeight = sheet!.height / 2;
    void draw(int frame, double opacity, {BlendMode mode = BlendMode.srcOver}) {
      canvas.drawImageRect(
        sheet!,
        Rect.fromLTWH(
          (frame % 4) * cellWidth,
          (frame ~/ 4) * cellHeight,
          cellWidth,
          cellHeight,
        ),
        offsets[frame] & const Size(512, 512),
        Paint()
          ..blendMode = mode
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }

    if (seconds < 0 || resting) {
      draw(0, 1);
    } else if (reducedMotion) {
      draw(1, 1);
    } else {
      final pose = StudyMotion.sample(seconds);
      if (pose.blend < 1) {
        // Interpolate premultiplied pixels in isolation. Two srcOver draws
        // would lower coverage and let the room show through opaque fur.
        canvas.saveLayer(Offset.zero & const Size(512, 512), Paint());
        draw(pose.previous, 1 - pose.blend);
        draw(pose.current, pose.blend, mode: BlendMode.plus);
        canvas.restore();
      } else {
        draw(pose.current, 1);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StudyCompanionPainter oldDelegate) =>
      sheet != oldDelegate.sheet ||
      seconds != oldDelegate.seconds ||
      resting != oldDelegate.resting ||
      reducedMotion != oldDelegate.reducedMotion;
}
