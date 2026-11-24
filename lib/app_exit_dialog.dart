import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads.dart';
import 'desk_style.dart';
import 'exit_native_ads.dart';
import 'l10n/app_localizations.dart';
import 'purchases.dart';

const _paper = Color(0xFFFFF8E9);
const _ink = Color(0xFF352724);
const _muted = Color(0xFF77665C);
const _line = Color(0xFFE8DDC9);
const _brown = Color(0xFF765239);

/// Handles Android back only on the root route; pushed pages and sheets keep
/// their own back behavior. Exiting never stops or completes the saved timer.
class AppExitScope extends StatefulWidget {
  const AppExitScope({
    super.key,
    required this.child,
    required this.canExit,
    required this.timerRunning,
    this.ads,
    this.purchases,
  });
  final Widget child;
  final bool canExit, timerRunning;
  final AdsConsent? ads;
  final Purchases? purchases;

  @override
  State<AppExitScope> createState() => _AppExitScopeState();
}

class _AppExitScopeState extends State<AppExitScope> {
  ExitNativeAds? _ads;
  bool _confirming = false;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _createAds();
  }

  void _createAds() {
    if (_android && widget.ads != null) {
      _ads = ExitNativeAds(consent: widget.ads!, purchases: widget.purchases);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ads?.prepare(AppLocalizations.of(context).adLabel);
  }

  @override
  void didUpdateWidget(AppExitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads != widget.ads ||
        oldWidget.purchases != widget.purchases) {
      _ads?.dispose();
      _ads = null;
      _createAds();
      _ads?.prepare(AppLocalizations.of(context).adLabel);
    }
  }

  Future<void> _confirmExit() async {
    if (_confirming ||
        !widget.canExit ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _confirming = true;
    final ads = _ads;
    final available = ads?.beginDialog() ?? <ExitAdSize>{};
    final route = DialogRoute<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AppExitDialog(
        ads: ads,
        available: available,
        timerRunning: widget.timerRunning,
      ),
    );
    var confirmed = false;
    try {
      confirmed = await Navigator.of(context).push(route) ?? false;
      // Let the platform view leave the tree before disposing/reloading it.
      await route.completed;
      if (confirmed && mounted) await SystemNavigator.pop();
    } finally {
      ads?.endDialog(preloadNext: !confirmed);
      _confirming = false;
    }
  }

  @override
  void dispose() {
    _ads?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: !_android,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _android) unawaited(_confirmExit());
    },
    child: widget.child,
  );
}

class AppExitDialog extends StatelessWidget {
  const AppExitDialog({
    super.key,
    this.ads,
    this.available = const {},
    this.timerRunning = false,
  });
  static const mascotAsset = 'assets/images/ui/exit-friend-wave.png';
  static const adWidth = 320.0;
  static double adHeight(ExitAdSize size) =>
      size == ExitAdSize.small ? 188 : 350;
  final ExitNativeAds? ads;
  final Set<ExitAdSize> available;
  final bool timerRunning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final width =
        media.size.width -
        media.padding.horizontal -
        media.viewInsets.horizontal;
    final height =
        media.size.height - media.padding.vertical - media.viewInsets.vertical;
    final scale = media.textScaler.scale(1);
    // Keep 120x120 MediaView on the small layout and full-size media on medium.
    // Huge type/narrow windows get a regular exit confirmation instead.
    final smallMinHeight = scale > 1.2 ? 640 : (timerRunning ? 620 : 580);
    final canSmall =
        width >= adWidth && height >= smallMinHeight && scale <= 1.4;
    final canMedium =
        width >= 352 && height >= (timerRunning ? 800 : 760) && scale <= 1.2;
    final size = canMedium && available.contains(ExitAdSize.medium)
        ? ExitAdSize.medium
        : canSmall && available.contains(ExitAdSize.small)
        ? ExitAdSize.small
        : null;
    final narrow = size != null && width < 352;
    return Dialog(
      key: const ValueKey('app-exit-dialog'),
      backgroundColor: _paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 0 : 16,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: narrow ? 320 : 352),
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Pretendard', color: _ink),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          children: [
                            if (height >= 500) ...[
                              Image.asset(
                                mascotAsset,
                                width: 130,
                                height: 100,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.exitAppTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.exitAppConfirm,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            if (timerRunning) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.exitTimerContinues,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (size != null)
                        SizedBox(
                          key: ValueKey('exit-ad-${size.name}'),
                          width: adWidth,
                          height: adHeight(size),
                          child: ads == null
                              ? null
                              : ListenableBuilder(
                                  listenable: ads!,
                                  builder: (context, _) {
                                    final ad = ads!.presented(size);
                                    // Keep the slot if eligibility changes while open.
                                    return ad == null
                                        ? const SizedBox.shrink()
                                        : AdWidget(key: ValueKey(ad), ad: ad);
                                  },
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, size == null ? 4 : 24, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, thickness: 1, color: _line),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('exit-cancel'),
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _brown,
                              side: const BorderSide(color: _brown),
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('exit-confirm'),
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              foregroundColor: deskInkShadow,
                              backgroundColor: deskAccent,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(
                              l10n.exitAppAction,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
