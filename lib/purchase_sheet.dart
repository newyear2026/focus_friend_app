import 'package:flutter/material.dart';
import 'desk_style.dart';
import 'focus_friend.dart';
import 'friend_picker.dart';
import 'l10n/app_localizations.dart';
import 'localized_names.dart';
import 'purchases.dart';

const _paper = Color(0xFFFFF8E9);
const _ink = Color(0xFF352724);
const _muted = Color(0xFF77665C);
const _line = Color(0xFFE8DDC9);
const _plum = Color(0xFF3A2F48);
const _owned = Color(0xFF3F6B4E);

/// The card label for a friend the person cannot use yet, or null.
String? lockTag(
  AppLocalizations l10n,
  Purchases? purchases,
  FocusFriend friend,
) {
  final id = Products.forFriend(friend);
  if (purchases == null || id == null || purchases.hasFriend(friend)) {
    return null;
  }
  if (purchases.isPending(id)) return l10n.purchasePending;
  return purchases.price(id) ?? l10n.friendLocked;
}

class LockChip extends StatelessWidget {
  const LockChip({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xD9262430),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_rounded, size: 12, color: deskInk),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: deskInk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// The strip above the friend cards that opens the bundle.
class BundleBanner extends StatelessWidget {
  const BundleBanner({super.key, required this.purchases});
  final Purchases purchases;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price = purchases.price(Products.allFriends);
    return Material(
      color: _plum,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('bundle-banner'),
        onTap: () => showBundleSheet(context, purchases),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.pets_rounded, color: deskAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bundleTitle,
                      style: const TextStyle(
                        color: deskInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.bundleSubtitle,
                      style: const TextStyle(color: deskMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (purchases.isPending(Products.allFriends))
                Text(
                  l10n.purchasePending,
                  style: const TextStyle(color: deskMuted, fontSize: 12),
                )
              else if (price != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deskAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: deskInkShadow,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: deskMuted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBundleSheet(BuildContext context, Purchases purchases) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      builder: (_) => BundleSheet(purchases: purchases),
    );

class BundleSheet extends StatefulWidget {
  const BundleSheet({super.key, required this.purchases});
  final Purchases purchases;

  @override
  State<BundleSheet> createState() => _BundleSheetState();
}

class _BundleSheetState extends State<BundleSheet> {
  bool buying = false;
  String? message;

  Future<void> _buy() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      buying = true;
      message = null;
    });
    final outcome = await widget.purchases.buy(Products.allFriends);
    if (!mounted) return;
    if (outcome == PurchaseOutcome.owned) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      buying = false;
      message = switch (outcome) {
        PurchaseOutcome.pending => l10n.purchasePendingNotice,
        PurchaseOutcome.failed => l10n.purchaseFailed,
        _ => null,
      };
    });
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      buying = true;
      message = null;
    });
    final ok = await widget.purchases.refresh();
    if (!mounted) return;
    setState(() {
      buying = false;
      message = ok ? l10n.restoreDone : l10n.restoreFailed;
    });
  }

  Widget _row({
    required Widget leading,
    required String title,
    required String subtitle,
    required String id,
  }) {
    final l10n = AppLocalizations.of(context);
    final owned = widget.purchases.has(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          SizedBox.square(dimension: 42, child: ClipOval(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (owned)
            Text(
              l10n.purchaseOwned,
              style: const TextStyle(
                color: _owned,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.purchases,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final purchases = widget.purchases;
      final price = purchases.price(Products.allFriends);
      final owned = purchases.has(Products.allFriends);
      final pending = purchases.isPending(Products.allFriends);
      return DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Pretendard', color: _ink),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.bundleTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.bundleSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                for (final friend in FocusFriend.values)
                  if (Products.forFriend(friend) case final id?)
                    _row(
                      leading: FriendArtwork(
                        friend: friend,
                        unlocked: const {},
                        thumbnail: true,
                      ),
                      title: friendName(l10n, friend),
                      subtitle: friendRoom(l10n, friend),
                      id: id,
                    ),
                _row(
                  leading: const ColoredBox(
                    color: Color(0xFFF3E6D3),
                    child: Icon(
                      Icons.hide_source_rounded,
                      color: Color(0xFFA26030),
                    ),
                  ),
                  title: l10n.removeAdsTitle,
                  subtitle: l10n.removeAdsSubtitle,
                  id: Products.removeAds,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.bundleNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _ink, fontSize: 13),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey('bundle-buy'),
                  onPressed: owned || pending || price == null || buying
                      ? null
                      : _buy,
                  style: FilledButton.styleFrom(
                    backgroundColor: deskAccent,
                    foregroundColor: deskInkShadow,
                    disabledBackgroundColor: deskAccent.withValues(alpha: .5),
                    disabledForegroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(
                    owned
                        ? l10n.purchaseOwned
                        : pending
                        ? l10n.purchasePending
                        : price == null
                        ? l10n.purchaseUnavailable
                        : l10n.bundleBuy(price),
                  ),
                ),
                TextButton(
                  key: const ValueKey('bundle-restore'),
                  style: TextButton.styleFrom(foregroundColor: _muted),
                  onPressed: buying ? null : _restore,
                  child: Text(l10n.restorePurchases),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
