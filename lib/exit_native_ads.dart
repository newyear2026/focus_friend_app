import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads.dart';
import 'purchases.dart';

enum ExitAdSize { small, medium }

class _ExitAdSlot {
  NativeAd? ad;
  DateTime? loadedAt;
  Timer? timeout;
  DateTime? requestedAt;
  bool attempted = false;
  bool presented = false;
}

/// Two independently preloaded layouts. The dialog freezes availability when
/// it opens: late loads can never move its buttons or appear under a finger.
class ExitNativeAds extends ChangeNotifier with WidgetsBindingObserver {
  ExitNativeAds({
    required this.consent,
    this.purchases,
    String? adUnitId,
    DateTime Function()? now,
  }) : adUnitId = adUnitId ?? AdUnits.nativeExit,
       _now = now ?? clock.now {
    consent.addListener(_eligibilityChanged);
    purchases?.addListener(_eligibilityChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_waitForConsent());
  }

  final AdsConsent consent;
  final Purchases? purchases;
  final String adUnitId;
  final DateTime Function() _now;
  final _slots = {for (final size in ExitAdSize.values) size: _ExitAdSlot()};
  bool _startupAllowed = false, _open = false, _disposed = false;
  String? _label;
  Timer? _gapTimer;

  /// AdMob asks for no new request sooner than 60 seconds, also when people
  /// reopen the popup or return to the app quickly. Each layout keeps its own.
  static const minRequestGap = Duration(seconds: 60);

  bool get _eligible =>
      !_disposed &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (_startupAllowed || consent.canRequestAds == true) &&
      consent.canRequestAds != false &&
      purchases?.adsRemoved != true;

  Future<void> _waitForConsent() async {
    try {
      _startupAllowed = await consent.ready;
    } catch (_) {
      _startupAllowed = false;
    }
    if (!_disposed) _eligibilityChanged();
  }

  void prepare(String adLabel) {
    if (_disposed || _label == adLabel) return;
    _label = adLabel;
    if (!_open) {
      _clearAll();
      _preload();
    }
  }

  void _eligibilityChanged() {
    if (_disposed) return;
    if (!_eligible) {
      _clearAll();
    } else {
      _preload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // A failed or timed-out slot gets one fresh try per return to the app,
    // e.g. after starting offline, once 60 seconds have passed since its last
    // request. Loading or loaded slots are left alone.
    if (!_open) {
      for (final slot in _slots.values) {
        if (slot.ad == null) slot.attempted = false;
      }
    }
    _preload();
  }

  void _preload() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!_eligible ||
        _open ||
        _label == null ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    Duration? wait;
    for (final entry in _slots.entries) {
      final slot = entry.value;
      if (slot.ad != null || slot.attempted) continue;
      final last = slot.requestedAt;
      if (last != null) {
        final since = _now().difference(last);
        if (!since.isNegative && since < minRequestGap) {
          final left = minRequestGap - since;
          if (wait == null || left < wait) wait = left;
          continue;
        }
      }
      slot.attempted = true;
      slot.requestedAt = _now();
      if (kDebugMode) {
        debugPrint('Exit native ad: requesting ${entry.key.name}');
      }
      final ad = NativeAd(
        adUnitId: adUnitId,
        factoryId: 'focusFriendExit',
        customOptions: {
          'compact': entry.key == ExitAdSize.small,
          'adLabel': _label!,
        },
        request: const AdRequest(),
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!identical(slot.ad, ad) || _disposed) return;
            if (!_eligible) {
              _clear(slot);
              return;
            }
            slot.timeout?.cancel();
            slot.loadedAt = _now();
            if (kDebugMode) {
              debugPrint('Exit native ad: loaded ${entry.key.name}');
            }
          },
          onAdFailedToLoad: (ad, error) {
            if (kDebugMode) {
              debugPrint(
                'Exit native ad: ${entry.key.name} failed (${error.code}) ${error.message}',
              );
            }
            if (identical(slot.ad, ad)) _clear(slot, retry: false);
          },
        ),
      );
      slot.ad = ad;
      slot.timeout = Timer(const Duration(seconds: 30), () {
        if (kDebugMode) {
          debugPrint('Exit native ad: ${entry.key.name} timed out');
        }
        if (identical(slot.ad, ad)) _clear(slot, retry: false);
      });
      unawaited(_load(ad, slot));
    }
    if (wait != null) {
      _gapTimer?.cancel();
      _gapTimer = Timer(wait, () {
        _gapTimer = null;
        _preload();
      });
    }
  }

  Future<void> _load(NativeAd ad, _ExitAdSlot slot) async {
    try {
      await ad.load();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Exit native ad: platform load failed: $error');
      }
      if (identical(slot.ad, ad)) _clear(slot, retry: false);
    }
  }

  Set<ExitAdSize> beginDialog() {
    if (_disposed || _open) return {};
    _open = true;
    final available = <ExitAdSize>{};
    if (!_eligible) return available;
    for (final entry in _slots.entries) {
      final slot = entry.value;
      final loadedAt = slot.loadedAt;
      if (loadedAt == null || slot.ad == null) continue;
      final age = _now().difference(loadedAt);
      if (age.isNegative || age >= const Duration(hours: 1)) {
        _clear(slot);
      } else {
        slot.presented = true;
        available.add(entry.key);
      }
    }
    return available;
  }

  NativeAd? presented(ExitAdSize size) =>
      _slots[size]!.presented ? _slots[size]!.ad : null;

  @visibleForTesting
  bool hasLoaded(ExitAdSize size) => _slots[size]!.loadedAt != null;

  void endDialog({required bool preloadNext}) {
    if (_disposed) return;
    _open = false;
    _clearAll();
    if (preloadNext) _preload();
  }

  void _clearAll() {
    for (final slot in _slots.values) {
      _clear(slot);
    }
  }

  void _clear(_ExitAdSlot slot, {bool retry = true}) {
    slot.timeout?.cancel();
    slot.timeout = null;
    final ad = slot.ad;
    final presented = slot.presented;
    slot.ad = null;
    slot.loadedAt = null;
    slot.presented = false;
    slot.attempted = !retry;
    if (presented && !_disposed) notifyListeners();
    if (ad == null) return;
    if (presented) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_release(ad)),
      );
      WidgetsBinding.instance.scheduleFrame();
    } else {
      unawaited(_release(ad));
    }
  }

  Future<void> _release(NativeAd ad) async {
    try {
      await ad.dispose();
    } catch (_) {
      // The native activity may already have been destroyed.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _gapTimer?.cancel();
    consent.removeListener(_eligibilityChanged);
    purchases?.removeListener(_eligibilityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _clearAll();
    super.dispose();
  }
}
