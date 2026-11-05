import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'desk_style.dart';

/// One native ad with Google's media-capable template in the desk colors.
/// Takes no space until an ad has loaded, so a refused consent, no network
/// or no fill leaves the screen as it was.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key, required this.adUnitId, required this.ready});
  final String adUnitId;

  /// Whether ads may be requested this run (see `AdsConsent.ready`).
  final Future<bool> ready;
  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!await widget.ready || !mounted) return;
    ad = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => loaded = true);
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          ad = null;
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        // The small template has no MediaView and fails native-ad validation
        // when AdMob returns an image/video creative that needs one.
        templateType: TemplateType.medium,
        mainBackgroundColor: deskCream,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: deskPaper,
          backgroundColor: deskAccent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: deskInk,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: deskMuted,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: deskMuted,
          size: 13,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = this.ad;
    if (!loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      // Match the Android medium template's 350 dp height so its MediaView,
      // attribution, text and call to action are all inside the ad bounds.
      child: SizedBox(height: 350, child: AdWidget(ad: ad)),
    );
  }
}
