import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _separator = Color(0xFFD9D2C7);
const _navigationTone = Color(0xFFF1ECE4);

/// The footer reaches the screen bottom, so the Android navigation bar (read
/// from the lowest region) needs dark buttons while the ad is shown. A
/// different tone and a line keep the system buttons apart from the ad.
const sessionBannerNavigationStyle = SystemUiOverlayStyle(
  systemNavigationBarColor: _navigationTone,
  systemNavigationBarDividerColor: _separator,
  systemNavigationBarIconBrightness: Brightness.dark,
);

/// A compact banner in its own footer, separate from the session controls.
/// The fixed slot keeps controls still while consent/loading is pending.
class SessionBannerAd extends StatefulWidget {
  const SessionBannerAd({
    super.key,
    required this.adUnitId,
    required this.ready,
  });

  static const width = 320.0;

  /// 50 dp creative, a line above, and a line plus a 4 dp buffer below it.
  /// None of the separators are clickable.
  static const height = 56.0;

  /// AdMob asks for no new request sooner than 60 seconds, including when
  /// people move to and from the screen with the ad. Sheets, backgrounding
  /// and new sessions all recreate this widget, so the gap is shared.
  static const minRequestGap = Duration(seconds: 60);
  static DateTime? _lastRequest;

  @visibleForTesting
  static void resetRequestGap() => _lastRequest = null;

  final String adUnitId;
  final Future<bool> ready;

  @override
  State<SessionBannerAd> createState() => _SessionBannerAdState();
}

class _SessionBannerAdState extends State<SessionBannerAd>
    with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false;
  int _generation = 0;
  Timer? _gapTimer;

  bool get _foreground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_ad != null || !_foreground) return;
    final generation = ++_generation;
    BannerAd? requested;
    try {
      if (!await widget.ready ||
          !mounted ||
          !_foreground ||
          generation != _generation) {
        return;
      }
      final last = SessionBannerAd._lastRequest;
      if (last != null) {
        final since = clock.now().difference(last);
        if (!since.isNegative && since < SessionBannerAd.minRequestGap) {
          // The reserved slot stays empty until the gap has passed.
          _gapTimer?.cancel();
          _gapTimer = Timer(SessionBannerAd.minRequestGap - since, () {
            _gapTimer = null;
            if (mounted) unawaited(_load());
          });
          return;
        }
      }
      SessionBannerAd._lastRequest = clock.now();
      final banner = BannerAd(
        adUnitId: widget.adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted && identical(ad, _ad)) {
              setState(() => _loaded = true);
            }
          },
          onAdFailedToLoad: (ad, _) => _failed(ad),
        ),
      );
      requested = banner;
      _ad = banner;
      await banner.load();
    } catch (_) {
      // Missing SDK/network/consent must never interrupt a focus session.
      if (requested != null) _failed(requested);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    } else {
      // Paused apps may not draw another frame. Release the native ad now,
      // rather than waiting for the parent's visibility rebuild to dispose us.
      _generation++;
      _gapTimer?.cancel();
      _gapTimer = null;
      final ad = _ad;
      setState(() {
        _ad = null;
        _loaded = false;
      });
      if (ad != null) unawaited(_release(ad));
    }
  }

  void _failed(Ad ad) {
    if (mounted && identical(ad, _ad)) {
      setState(() {
        _ad = null;
        _loaded = false;
      });
    }
    unawaited(_release(ad));
  }

  Future<void> _release(Ad ad) async {
    try {
      await ad.dispose();
    } catch (_) {
      // Disposal may race the native activity being torn down.
    }
  }

  @override
  void dispose() {
    _generation++;
    _gapTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final ad = _ad;
    _ad = null;
    if (ad != null) unawaited(_release(ad));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: sessionBannerNavigationStyle,
      child: ColoredBox(
        // Also fills the system navigation area below the buffer.
        color: _navigationTone,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 1,
                width: double.infinity,
                child: ColoredBox(color: _separator),
              ),
              ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  height: AdSize.banner.height.toDouble(),
                  child: Center(
                    child: SizedBox(
                      key: const ValueKey('session-banner-creative'),
                      width: SessionBannerAd.width,
                      height: AdSize.banner.height.toDouble(),
                      child: AdWidget(ad: ad),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                key: ValueKey('session-banner-bottom-separator'),
                height: 1,
                width: double.infinity,
                child: ColoredBox(color: _separator),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
