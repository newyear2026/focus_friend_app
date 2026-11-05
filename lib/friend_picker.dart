import 'package:flutter/material.dart';
import 'desk_style.dart';
import 'focus_friend.dart';
import 'l10n/app_localizations.dart';
import 'localized_names.dart';
import 'purchase_sheet.dart';
import 'purchases.dart';
import 'room_ambience.dart';
import 'study_scene.dart';

const _paper = Color(0xFFFFF8E9);
const _ink = Color(0xFF352724);
const _muted = Color(0xFF77665C);

class FriendPicker extends StatefulWidget {
  const FriendPicker({
    super.key,
    required this.current,
    required this.unlocked,
    required this.onApply,
    required this.onApplied,
    this.purchases,
  });
  final FocusFriend current;
  final Set<String> unlocked;
  final Future<void> Function(FocusFriend) onApply;
  final VoidCallback onApplied;

  /// Null means every friend is owned (tests and builds without billing).
  final Purchases? purchases;

  @override
  State<FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<FriendPicker> {
  late FocusFriend selected = widget.current;

  Future<void> _preview() async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FriendPreview(
          friend: selected,
          unlocked: widget.unlocked,
          purchases: widget.purchases,
          onApply: () => widget.onApply(selected),
        ),
      ),
    );
    if (applied == true && mounted) widget.onApplied();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.purchases ?? Listenable.merge(const []),
    builder: _build,
  );

  Widget _build(BuildContext context, Widget? _) {
    final l10n = AppLocalizations.of(context);
    final purchases = widget.purchases;
    final showBundle =
        purchases != null &&
        purchases.sells &&
        !purchases.has(Products.allFriends) &&
        FocusFriend.values.any((f) => !purchases.hasFriend(f));
    return ColoredBox(
      color: _paper,
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Pretendard', color: _ink),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  Text(
                    l10n.friendsTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.friendsSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (showBundle)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: BundleBanner(purchases: purchases),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 560 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - 32 - (columns - 1) * 12) /
                      columns;
                  double labelHeight = 0;
                  double measure(String text, TextStyle style) {
                    final painter = TextPainter(
                      text: TextSpan(
                        text: text,
                        style: style.copyWith(fontFamily: 'Pretendard'),
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(maxWidth: width - 12);
                    final height = painter.height;
                    painter.dispose();
                    return height;
                  }

                  for (final friend in FocusFriend.values) {
                    final height =
                        measure(
                          friendName(l10n, friend),
                          const TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ) +
                        measure(
                          friendRoom(l10n, friend),
                          const TextStyle(fontSize: 12, height: 1.3),
                        ) +
                        24;
                    if (height > labelHeight) labelHeight = height;
                  }
                  return GridView.builder(
                    key: const ValueKey('friend-grid'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: width + labelHeight,
                    ),
                    itemCount: FocusFriend.values.length,
                    itemBuilder: (context, index) {
                      final friend = FocusFriend.values[index];
                      final chosen = selected == friend;
                      final tag = lockTag(l10n, purchases, friend);
                      return Semantics(
                        selected: chosen,
                        button: true,
                        label: [
                          friendName(l10n, friend),
                          friendRoom(l10n, friend),
                          ?tag,
                        ].join(', '),
                        child: Material(
                          color: _paper,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: chosen
                                  ? deskAccent
                                  : const Color(0xFFE8DDC9),
                              width: chosen ? 3 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('friend-card-${friend.name}'),
                            onTap: () => setState(() => selected = friend),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FriendArtwork(
                                        friend: friend,
                                        unlocked: widget.unlocked,
                                        thumbnail: true,
                                      ),
                                      if (friend == widget.current)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: deskAccent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              l10n.friendCurrent,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (tag != null)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: LockChip(text: tag),
                                        ),
                                      if (chosen && friend != widget.current)
                                        const Positioned(
                                          top: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            radius: 15,
                                            backgroundColor: deskAccent,
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: _ink,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          friendName(l10n, friend),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            height: 1.2,
                                            color: _ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          friendRoom(l10n, friend),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _muted,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: _FriendButton(
                key: const ValueKey('friend-preview'),
                onPressed: _preview,
                text: l10n.preview,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Use the same full room on cards, preview and home. Cards crop around the desk.
class FriendArtwork extends StatelessWidget {
  const FriendArtwork({
    super.key,
    required this.friend,
    required this.unlocked,
    this.thumbnail = false,
    this.animate = false,
  });
  final FocusFriend friend;
  final Set<String> unlocked;
  final bool thumbnail;
  final bool animate;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 853,
          height: 1844,
          child: Transform.scale(
            scale: thumbnail ? 1.3 : 1,
            alignment: const Alignment(0, .05),
            child: DeskIllustration(
              friend: friend,
              unlocked: unlocked,
              ambience: RoomAmbience.evening,
              studying: animate && friend.hasDeskMotion,
              resting: animate && friend.hasWindowTeaMotion,
              animate: animate && friend.hasRestMotion,
            ),
          ),
        ),
      ),
    ),
  );
}

class FriendPreview extends StatefulWidget {
  const FriendPreview({
    super.key,
    required this.friend,
    required this.unlocked,
    required this.onApply,
    this.purchases,
  });
  final FocusFriend friend;
  final Set<String> unlocked;
  final Future<void> Function() onApply;
  final Purchases? purchases;

  @override
  State<FriendPreview> createState() => _FriendPreviewState();
}

class _FriendPreviewState extends State<FriendPreview> {
  bool saving = false;
  bool failed = false;
  bool buying = false;

  Future<void> _buy(String id) async {
    if (buying || saving) return;
    setState(() => buying = true);
    final outcome = await widget.purchases!.buy(id);
    if (!mounted) return;
    setState(() => buying = false);
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case PurchaseOutcome.owned:
        await _apply();
      case PurchaseOutcome.pending:
        _notice(l10n.purchasePendingNotice);
      case PurchaseOutcome.failed:
        _notice(l10n.purchaseFailed);
      case PurchaseOutcome.cancelled:
        break;
    }
  }

  void _notice(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );

  Widget _action(AppLocalizations l10n) {
    final purchases = widget.purchases;
    final id = Products.forFriend(widget.friend);
    if (purchases == null || id == null || purchases.hasFriend(widget.friend)) {
      return _FriendButton(
        key: const ValueKey('friend-apply'),
        onPressed: saving ? null : _apply,
        text: saving ? l10n.saving : l10n.friendApply,
      );
    }
    final price = purchases.price(id);
    final pending = purchases.isPending(id);
    final bundle = purchases.price(Products.allFriends);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.purchasePendingNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
          ),
        _FriendButton(
          key: const ValueKey('friend-buy'),
          onPressed: pending || price == null || buying || saving
              ? null
              : () => _buy(id),
          text: pending
              ? l10n.purchasePending
              : price == null
              ? l10n.purchaseUnavailable
              : l10n.friendBuy(price),
        ),
        if (bundle != null && !purchases.isPending(Products.allFriends))
          TextButton(
            key: const ValueKey('friend-open-bundle'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFA26030),
            ),
            onPressed: buying || saving
                ? null
                : () => showBundleSheet(context, purchases),
            child: Text('${l10n.bundleTitle} · $bundle'),
          ),
      ],
    );
  }

  Future<void> _apply() async {
    if (saving) return;
    setState(() {
      saving = true;
      failed = false;
    });
    try {
      await widget.onApply();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          failed = true;
        });
      }
    }
  }

  Widget _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            friendName(l10n, widget.friend),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            friendRoom(l10n, widget.friend),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA26030),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            l10n.friendApplyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 5),
          Text(
            widget.friend.hasWindowTeaMotion
                ? l10n.friendRestAnimated
                : widget.friend.hasMotion
                ? l10n.friendAnimated
                : l10n.friendStill,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.saveError,
                  style: const TextStyle(color: Color(0xFF9B3529)),
                ),
              ),
            ),
          const SizedBox(height: 22),
          ListenableBuilder(
            listenable: widget.purchases ?? Listenable.merge(const []),
            builder: (context, _) => _action(l10n),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final scrollPage =
        size.height < 700 || MediaQuery.textScalerOf(context).scale(16) > 21;
    final artwork = FriendArtwork(
      friend: widget.friend,
      unlocked: widget.unlocked,
      animate: widget.friend.hasRestMotion,
    );
    return PopScope(
      canPop: !saving && !buying,
      child: Scaffold(
        backgroundColor: _paper,
        appBar: scrollPage
            ? AppBar(
                backgroundColor: _paper,
                foregroundColor: _ink,
                surfaceTintColor: Colors.transparent,
                toolbarHeight:
                    56 *
                    (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
                      1,
                      2,
                    ),
                centerTitle: true,
                title: Text(
                  l10n.friendPreviewTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                leading: IconButton(
                  tooltip: l10n.back,
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              )
            : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (scrollPage)
              SingleChildScrollView(
                key: const ValueKey('friend-preview-scroll'),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: size.width * 1.75,
                      child: artwork,
                    ),
                    _details(context),
                  ],
                ),
              )
            else ...[
              artwork,
              SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: size.height * .56),
                    child: SingleChildScrollView(child: _details(context)),
                  ),
                ),
              ),
            ],
            if (!scrollPage)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 56, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: l10n.back,
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: deskInk,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x55352724),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.friendPreviewTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: deskInk,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Color(0x99352724),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FriendButton extends StatelessWidget {
  const _FriendButton({super.key, required this.onPressed, required this.text});
  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: deskAccent,
        foregroundColor: deskInkShadow,
        disabledBackgroundColor: deskAccent.withValues(alpha: .6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
