import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Pulls the book close, closes the eyes and gives a small, contented nod.
class StartupCompanion extends StatefulWidget {
  const StartupCompanion({super.key, required this.size, this.animate = true});

  static const asset = 'assets/images/startup/reading-companion.png';
  static const blinkAsset = 'assets/images/startup/reading-companion-blink.png';
  static const halfBlinkAsset =
      'assets/images/startup/reading-companion-half-blink.png';
  static const nodAsset = 'assets/images/startup/reading-companion-nod.png';
  static const bodyAsset = 'assets/images/startup/hug-body-base.png';
  static const bookAsset = 'assets/images/startup/hug-book-arms.png';
  static const feetAsset = 'assets/images/startup/hug-feet.png';
  static const motionAssets = [
    blinkAsset,
    halfBlinkAsset,
    nodAsset,
    bodyAsset,
    bookAsset,
    feetAsset,
  ];
  static const cycleDuration = Duration(milliseconds: 5400);

  // The largest phone rendering is about 800 physical pixels. Share the same
  // resized decode between the fallback, painter and prefetch paths.
  static ImageProvider<Object> imageProvider(String asset) =>
      ResizeImage(AssetImage(asset), width: 800);
  final double size;
  final bool animate;

  @override
  State<StartupCompanion> createState() => _StartupCompanionState();
}

class _StartupCompanionState extends State<StartupCompanion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_tick);
  final _streams = <String, ImageStream>{};
  final _listeners = <String, ImageStreamListener>{};
  final _images = <String, ImageInfo>{};
  Duration _played = Duration.zero, _runBase = Duration.zero;
  int _frame = 0;
  bool _reduced = false, _enabled = true, _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  void _load(String asset) {
    if (_streams.containsKey(asset)) return;
    final stream = StartupCompanion.imageProvider(
      asset,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final previous = _images[asset];
        setState(() => _images[asset] = info);
        previous?.dispose();
        _sync();
      },
      // Optional expression artwork must never keep the room from opening.
      onError: (Object error, StackTrace? stack) {},
    );
    _streams[asset] = stream;
    _listeners[asset] = listener;
    stream.addListener(listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _enabled = TickerMode.valuesOf(context).enabled;
    _load(StartupCompanion.asset);
    if (!_reduced && widget.animate) {
      for (final asset in StartupCompanion.motionAssets) {
        _load(asset);
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(StartupCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reduced && widget.animate) {
      for (final asset in StartupCompanion.motionAssets) {
        _load(asset);
      }
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _tick(Duration elapsed) {
    final played = _runBase + elapsed;
    final frame = played.inMicroseconds * 60 ~/ Duration.microsecondsPerSecond;
    if (frame == _frame) return;
    setState(() {
      _played = played;
      _frame = frame;
    });
  }

  void _sync() {
    if (widget.animate &&
        !_reduced &&
        _enabled &&
        _foreground &&
        _images.containsKey(StartupCompanion.asset) &&
        _images.containsKey(StartupCompanion.bodyAsset) &&
        _images.containsKey(StartupCompanion.bookAsset) &&
        _images.containsKey(StartupCompanion.feetAsset)) {
      if (!_ticker.isActive) {
        _runBase = _played;
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    for (final entry in _streams.entries) {
      entry.value.removeListener(_listeners[entry.key]!);
    }
    for (final info in _images.values) {
      info.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _images[StartupCompanion.asset]?.image;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: image == null
              ? Image(
                  image: StartupCompanion.imageProvider(StartupCompanion.asset),
                  fit: BoxFit.contain,
                )
              : CustomPaint(
                  key: const ValueKey('startup-companion-motion'),
                  painter: StartupCompanionPainter(
                    image,
                    blink: _images[StartupCompanion.blinkAsset]?.image,
                    halfBlink: _images[StartupCompanion.halfBlinkAsset]?.image,
                    nod: _images[StartupCompanion.nodAsset]?.image,
                    body: _images[StartupCompanion.bodyAsset]?.image,
                    book: _images[StartupCompanion.bookAsset]?.image,
                    feet: _images[StartupCompanion.feetAsset]?.image,
                    elapsed: _reduced || !widget.animate
                        ? Duration.zero
                        : _played,
                  ),
                ),
        ),
      ),
    );
  }
}

class StartupCompanionPainter extends CustomPainter {
  StartupCompanionPainter(
    this.image, {
    this.blink,
    this.halfBlink,
    this.nod,
    this.body,
    this.book,
    this.feet,
    required this.elapsed,
  });

  final ui.Image image;
  final ui.Image? blink;
  final ui.Image? halfBlink;
  final ui.Image? nod;
  final ui.Image? body;
  final ui.Image? book;
  final ui.Image? feet;
  final Duration elapsed;
  static const _artSize = 1254.0;
  static final _identity = Float64List.fromList([
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);
  static final _body = _MeshPatch(
    const Rect.fromLTWH(0, 0, _artSize, _artSize),
    40,
  );
  static final _bookArms = _MeshPatch(
    const Rect.fromLTRB(380, 620, 1080, 1120),
    32,
  );
  static final _eyes = [
    _MeshPatch(const Rect.fromLTRB(525, 435, 725, 620), 16, feather: 14),
    _MeshPatch(const Rect.fromLTRB(745, 500, 915, 663), 16, feather: 14),
  ];

  double get _milliseconds =>
      elapsed.inMicroseconds %
      StartupCompanion.cycleDuration.inMicroseconds /
      Duration.microsecondsPerMillisecond;

  // Overlapping actions avoid three stop-and-start poses: the arms lead, the
  // head follows while the book is still moving, then both settle and release.
  late final double anticipation = _envelope(120, 420, 420, 900);
  late final double hugAmount = _envelope(260, 1400, 2000, 4100);
  late final double settleAmount = _envelope(1200, 1720, 1720, 2500);
  late final double nodAmount = _envelope(1050, 2200, 2200, 3600);
  late final double blinkAmount = _envelope(980, 1120, 3300, 3500);
  late final double _headAngle = .025 * nodAmount;
  late final double _headCos = math.cos(_headAngle);
  late final double _headSin = math.sin(_headAngle);
  late final double _bookPull = hugAmount - .055 * settleAmount;
  late final double _bookAngle = -.008 * _bookPull;
  late final double _bookCos = math.cos(_bookAngle);
  late final double _bookSin = math.sin(_bookAngle);

  double _envelope(double start, double peak, double release, double end) {
    final ms = _milliseconds;
    return _ease((ms - start) / (peak - start)) *
        (1 - _ease((ms - release) / (end - release)));
  }

  int get blinkFrame => blinkAmount < .22
      ? 0
      : blinkAmount < .82
      ? 1
      : 2;

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  // Zero velocity AND acceleration at the joins keeps the small movements
  // soft when changing direction. Spatial feathering uses _smooth separately.
  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * x * (10 + x * (-15 + 6 * x));
  }

  /// Rotate the head around the neck instead of compressing its height.
  /// The neck blends into the fixed torso, tail and feet.
  @visibleForTesting
  Offset headPosition(Offset point) {
    final x = point.dx, y = point.dy;
    final head = _smooth((x - 330) / 100) * (1 - _smooth((y - 610) / 95));
    final dx = x - 720, dy = y - 660;
    return Offset(
      x + (dx * _headCos - dy * _headSin - dx) * head,
      y +
          (dx * _headSin +
                  dy * _headCos -
                  dy +
                  12 * nodAmount -
                  3 * hugAmount -
                  4 * anticipation) *
              head,
    );
  }

  /// All of the book receives one rigid transform. Only the upper left arm
  /// blends back to its fixed shoulder, keeping that joint from sliding.
  @visibleForTesting
  Offset bookPosition(Offset point) {
    final dx = point.dx - 820, dy = point.dy - 850;
    final follow = math.max(
      _smooth((point.dx - 470) / 90),
      _smooth((point.dy - 735) / 120),
    );
    return Offset(
      point.dx + (dx * _bookCos - dy * _bookSin - dx - 8 * _bookPull) * follow,
      point.dy +
          (dx * _bookSin +
                  dy * _bookCos -
                  dy -
                  24 * _bookPull +
                  2 * anticipation) *
              follow,
    );
  }

  void _drawMesh(
    Canvas canvas,
    ui.Image art,
    _MeshPatch patch, {
    bool bookMotion = false,
  }) {
    final shader = ui.ImageShader(
      art,
      TileMode.clamp,
      TileMode.clamp,
      _identity,
      filterQuality: FilterQuality.medium,
    );
    final vertices = ui.Vertices(
      VertexMode.triangles,
      patch.points.map(bookMotion ? bookPosition : headPosition).toList(),
      textureCoordinates: [
        for (final point in patch.points)
          Offset(
            point.dx * art.width / _artSize,
            point.dy * art.height / _artSize,
          ),
      ],
      colors: patch.feather == 0
          ? null
          : [
              for (final alpha in patch.alphas)
                Color.fromRGBO(255, 255, 255, alpha),
            ],
      indices: patch.indices,
    );
    canvas.drawVertices(
      vertices,
      BlendMode.modulate,
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
    shader.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _artSize, size.height / _artSize);
    if (body == null || book == null || feet == null) {
      _drawLayer(canvas, image);
      canvas.restore();
      return;
    }
    _drawMesh(canvas, body!, _body);
    final eyeImage = switch (blinkFrame) {
      1 => halfBlink,
      // One closed-eye expression throughout the hug; no mid-nod face swap.
      2 => nod ?? blink,
      _ => null,
    };
    if (eyeImage != null) {
      // Only the two eye regions use the alternate image. Generated differences
      // in the book, paws, mouth or silhouette can never leak into a blink.
      for (final eye in _eyes) {
        _drawMesh(canvas, eyeImage, eye);
      }
    }
    _drawMesh(canvas, book!, _bookArms, bookMotion: true);
    _drawLayer(canvas, feet!, solid: true);
    canvas.restore();
  }

  void _drawLayer(
    Canvas canvas,
    ui.Image art, {
    bool solid = false,
  }) => canvas.drawImageRect(
    art,
    Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
    const Rect.fromLTWH(0, 0, _artSize, _artSize),
    Paint()
      ..filterQuality = FilterQuality.medium
      // The extracted feet have alpha 252–253 even in their solid interiors.
      // Normalize that tiny transparency so the book cannot shimmer through;
      // the antialiased outline retains its soft edge.
      ..colorFilter = solid
          ? const ColorFilter.matrix([
              1,
              0,
              0,
              0,
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
              0,
              0,
              0,
              0,
              255 / 252,
              0,
            ])
          : null,
  );

  @override
  bool shouldRepaint(covariant StartupCompanionPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.blink != blink ||
      oldDelegate.halfBlink != halfBlink ||
      oldDelegate.nod != nod ||
      oldDelegate.body != body ||
      oldDelegate.book != book ||
      oldDelegate.feet != feet ||
      oldDelegate.elapsed != elapsed;
}

class _MeshPatch {
  _MeshPatch(this.bounds, this.divisions, {this.feather = 0});
  final Rect bounds;
  final int divisions;
  final double feather;
  late final points = [
    for (var y = 0; y <= divisions; y++)
      for (var x = 0; x <= divisions; x++)
        Offset(
          bounds.left + bounds.width * x / divisions,
          bounds.top + bounds.height * y / divisions,
        ),
  ];
  late final indices = [
    for (var y = 0; y < divisions; y++)
      for (var x = 0; x < divisions; x++) ...[
        y * (divisions + 1) + x,
        y * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x,
        y * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x,
      ],
  ];
  late final alphas = [
    for (final point in points)
      StartupCompanionPainter._smooth(
        [
              point.dx - bounds.left,
              bounds.right - point.dx,
              point.dy - bounds.top,
              bounds.bottom - point.dy,
            ].reduce(math.min) /
            feather,
      ),
  ];
}
