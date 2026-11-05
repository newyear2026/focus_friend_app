import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'desk_style.dart';
import 'l10n/app_localizations.dart';
import 'our_apps.dart';
import 'play_store.dart';

const _paper = Color(0xFFFFF8E9);
const _card = Color(0xFFFFFBF4);
const _ink = Color(0xFF352724);
const _muted = Color(0xFF77665C);
const _line = Color(0xFFE8DDC9);

// Keep Korean words intact when large accessibility text wraps the headline.
String _headingWithWordBoundaries(String text) => text.replaceAllMapped(
  RegExp(r'[가-힣]{2,}'),
  (word) => word[0]!.split('').join('\u2060'),
);

class OurAppsScreen extends StatefulWidget {
  const OurAppsScreen({super.key, this.openListing = openPlayListing});

  final Future<bool> Function(String packageName) openListing;

  @override
  State<OurAppsScreen> createState() => _OurAppsScreenState();
}

class _OurAppsScreenState extends State<OurAppsScreen> {
  final _opening = <String>{};

  Future<void> _open(OurApp app) async {
    if (_opening.contains(app.packageName)) return;
    setState(() => _opening.add(app.packageName));
    var opened = false;
    try {
      opened = await widget.openListing(app.packageName);
    } catch (_) {
      // A launcher or platform failure should keep this page usable.
    }
    if (!mounted) return;
    setState(() => _opening.remove(app.packageName));
    if (!opened) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).ourAppsOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = MediaQuery.textScalerOf(context);
    return Scaffold(
      key: const ValueKey('our-apps-screen'),
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: math.max(kToolbarHeight, scale.scale(20) * 1.25 + 20),
        leading: const BackButton(color: _ink),
        title: Text(
          l10n.ourAppsTitle,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            key: const ValueKey('our-apps-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: LayoutBuilder(
                  builder: (context, content) {
                    final twoColumns =
                        content.maxWidth >= 350 && scale.scale(14) <= 18;
                    final columns = twoColumns ? 2 : 1;
                    final rows = <Widget>[];
                    for (
                      var index = 0;
                      index < ourApps.length;
                      index += columns
                    ) {
                      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
                      final cards = <Widget>[];
                      for (
                        var item = index;
                        item < math.min(index + columns, ourApps.length);
                        item++
                      ) {
                        final app = ourApps[item];
                        final card = _AppCard(
                          app: app,
                          stretch: twoColumns,
                          opening: _opening.contains(app.packageName),
                          onOpen: () => _open(app),
                        );
                        if (cards.isNotEmpty) {
                          cards.add(const SizedBox(width: 10));
                        }
                        cards.add(twoColumns ? Expanded(child: card) : card);
                      }
                      rows.add(
                        twoColumns
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: cards,
                                ),
                              )
                            : cards.single,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.ourAppsEyebrow,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Semantics(
                                header: true,
                                child: Text(
                                  _headingWithWordBoundaries(
                                    l10n.ourAppsHeading,
                                  ),
                                  semanticsLabel: l10n.ourAppsHeading,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 32,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.ourAppsIntro,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        ...rows,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.app,
    required this.stretch,
    required this.opening,
    required this.onOpen,
  });

  final OurApp app;
  final bool stretch, opening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: ValueKey('our-app-card-${app.packageName}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                app.icon,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            app.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            app.category(l10n),
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            app.description(l10n),
            style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
          ),
          if (stretch) const Spacer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey('our-app-open-${app.packageName}'),
              onPressed: opening ? null : onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: deskAccent,
                foregroundColor: deskInkShadow,
                disabledBackgroundColor: deskAccent.withValues(alpha: .65),
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              child: opening
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: deskInkShadow,
                        semanticsLabel: '${app.name}, ${l10n.ourAppsOpening}',
                      ),
                    )
                  : Text(
                      l10n.ourAppsViewOnPlay,
                      textAlign: TextAlign.center,
                      semanticsLabel: '${app.name}, ${l10n.ourAppsViewOnPlay}',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
