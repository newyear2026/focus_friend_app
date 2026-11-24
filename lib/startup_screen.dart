import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'startup_companion.dart';

const startupPaper = Color(0xFFFEEBCF);
const startupInk = Color(0xFF654B3D);
const startupMuted = Color(0xFF806552);
const startupTeal = Color(0xFF168F91);

// Match the app's Korean headline wrapping: keep each word intact at large type.
String _withWordBoundaries(String text) => text.replaceAllMapped(
  RegExp(r'[가-힣]{2,}'),
  (word) => word[0]!.split('').join('\u2060'),
);

/// Covers the room until its saved state and language have been restored.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.failed = false, this.onRetry});

  static const companionAsset = StartupCompanion.asset;
  static const backgroundAsset = 'assets/images/startup/paper-background.png';
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = failed ? l10n.errorStorage : l10n.startupLoading;
    final title = Text(
      l10n.appTitle,
      key: const ValueKey('startup-title'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 29,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
        color: startupInk,
      ),
    );
    final status = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            _withWordBoundaries(message),
            semanticsLabel: message,
            key: const ValueKey('startup-status'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              height: 1.5,
              color: startupMuted,
            ),
          ),
        ),
        const SizedBox(height: 17),
        if (failed)
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: startupTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: startupTeal.withValues(alpha: .4),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(140, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retryCheck),
          )
        else
          const StartupLoadingDots(),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: startupPaper,
      ),
      child: Scaffold(
        backgroundColor: startupPaper,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final spacious =
                      height >= 560 &&
                      height >= width * 1.25 &&
                      MediaQuery.textScalerOf(context).scale(15) <= 19.5;
                  final companion = StartupCompanion(
                    key: const ValueKey('startup-companion'),
                    size: spacious ? math.min(width * .675, 320) : 200,
                    animate: !failed,
                  );
                  if (spacious) {
                    // Match the selected portrait's visual anchors while
                    // keeping the character's proportions on taller phones.
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: height * .17,
                          left: 24,
                          right: 24,
                          child: title,
                        ),
                        Align(
                          alignment: const Alignment(-.12, -.10),
                          child: companion,
                        ),
                        Positioned(
                          top: height * .71,
                          left: 24,
                          right: 24,
                          child: status,
                        ),
                      ],
                    );
                  }
                  // Large type and short/landscape windows get natural flow
                  // and scrolling so the status and retry stay reachable.
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: width,
                        minHeight: height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            title,
                            const SizedBox(height: 24),
                            companion,
                            const SizedBox(height: 24),
                            status,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet repeating pulse; status is announced by the text above the dots.
class StartupLoadingDots extends StatefulWidget {
  const StartupLoadingDots({super.key});

  @override
  State<StartupLoadingDots> createState() => _StartupLoadingDotsState();
}

class _StartupLoadingDotsState extends State<StartupLoadingDots>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse;
  bool _reduced = false, _enabled = true, _foreground = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _enabled = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (!_reduced && _enabled && _foreground) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      if (_reduced) _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < 3; index++)
            _dot(
              index,
              .5 +
                  .5 * math.cos(2 * math.pi * (_pulse.value - (index - 1) / 3)),
            ),
        ],
      ),
    ),
  );

  Widget _dot(int index, double pulse) => SizedBox(
    width: 18,
    height: 12,
    child: Center(
      child: Opacity(
        key: ValueKey('startup-dot-$index'),
        opacity: .4 + .6 * pulse,
        child: SizedBox.square(
          dimension: 7 + 3 * pulse,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: startupTeal,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}
