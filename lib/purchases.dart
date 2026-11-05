import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'focus_friend.dart';

/// One-time Google Play products. The ids must match Play Console exactly and
/// can never be reused once created, so do not rename them.
abstract final class Products {
  static const penguin = 'friend_penguin';
  static const otter = 'friend_otter';
  static const squirrel = 'friend_squirrel';
  static const fennec = 'friend_fennec';
  static const removeAds = 'remove_ads';

  /// Every friend sold today plus ad removal. Friends added later are sold
  /// separately, so this list stays fixed.
  static const allFriends = 'all_friends';

  static const all = {penguin, otter, squirrel, fennec, removeAds, allFriends};
  static const friends = [penguin, otter, squirrel, fennec];

  /// Null for the free red panda.
  static String? forFriend(FocusFriend friend) => switch (friend) {
    FocusFriend.redpanda => null,
    FocusFriend.penguin => penguin,
    FocusFriend.otter => otter,
    FocusFriend.squirrel => squirrel,
    FocusFriend.fennec => fennec,
  };

  static Set<String> _covers(String id) =>
      id == allFriends ? {allFriends, ...friends, removeAds} : {id};
}

/// What the person owns, as Google Play last reported it.
@immutable
class Entitlements {
  const Entitlements({this.owned = const {}, this.pending = const {}});
  final Set<String> owned;

  /// Started but not paid yet, e.g. OXXO cash or a parent's approval.
  final Set<String> pending;

  bool has(String id) => owned.any((o) => Products._covers(o).contains(id));
  bool hasFriend(FocusFriend friend) => switch (Products.forFriend(friend)) {
    null => true,
    final id => has(id),
  };
  bool get adsRemoved => has(Products.removeAds);
  bool isPending(String id) => !has(id) && pending.contains(id);
}

enum PurchaseOutcome { owned, pending, cancelled, failed }

/// Purchases with no store behind them: tests, and phones without Google
/// Play. With [unlockAll] everything counts as owned, which keeps tests and
/// screenshots free of prices.
class Purchases extends ChangeNotifier {
  Purchases({
    Entitlements entitlements = const Entitlements(),
    Map<String, String> prices = const {},
    this.unlockAll = false,
    bool checked = false,
  }) : _entitlements = entitlements,
       _prices = prices,
       _checked = checked;

  final bool unlockAll;
  Entitlements _entitlements;
  Map<String, String> _prices;
  bool _checked;

  Entitlements get entitlements => _entitlements;

  /// True once Google Play answered which products are owned. Until then a
  /// locked friend may still be owned, so nothing is taken away.
  bool get checked => _checked;

  bool has(String id) => unlockAll || _entitlements.has(id);
  bool hasFriend(FocusFriend friend) =>
      unlockAll || _entitlements.hasFriend(friend);
  bool get adsRemoved => unlockAll || _entitlements.adsRemoved;
  bool isPending(String id) => !unlockAll && _entitlements.isPending(id);
  bool get sells => !unlockAll;

  /// Google Play's localized price, e.g. "₩1,500" or "MX$15.00". Null while
  /// loading or when the product is not set up for this country.
  String? price(String id) => _prices[id];

  @protected
  void update({
    Entitlements? entitlements,
    Map<String, String>? prices,
    bool? checked,
  }) {
    _entitlements = entitlements ?? _entitlements;
    _prices = prices ?? _prices;
    _checked = checked ?? _checked;
    notifyListeners();
  }

  Future<void> start() async {}

  /// Opens the Google Play sheet and waits until it reports back.
  Future<PurchaseOutcome> buy(String id) async => PurchaseOutcome.failed;

  /// Asks Google Play again; false when it could not answer.
  Future<bool> refresh() async => true;
}

/// Google Play Billing. No server: Play keeps the receipts, the app asks again
/// on every launch and resume, and acknowledges new purchases so Play does
/// not refund them after three days.
class PlayPurchases extends Purchases {
  PlayPurchases({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance;
  final InAppPurchase _store;
  final _details = <String, ProductDetails>{};
  final _waiting = <String, Completer<PurchaseOutcome>>{};
  final _lastUpdate = <String, int>{};
  int _revision = 0;
  bool _disposed = false;
  StreamSubscription<List<PurchaseDetails>>? _updates;
  Future<bool>? _refreshing;

  @override
  Future<void> start() async {
    if (_disposed) return;
    try {
      _updates ??= _store.purchaseStream.listen(
        _onUpdates,
        onError: (Object _) => _finishWaiting(PurchaseOutcome.failed),
      );
      await refresh();
    } catch (_) {
      // No Play Store or no network: free friends and ads still work.
    }
  }

  Future<void> _loadPrices() async {
    try {
      final response = await _store.queryProductDetails(Products.all);
      if (_disposed || response.error != null) return;
      _details
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
      update(prices: {for (final p in _details.values) p.id: p.price});
    } catch (_) {
      // Retry on resume/restore, independently of the ownership query.
    }
  }

  @override
  Future<bool> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    try {
      if (_disposed || !await _store.isAvailable() || _disposed) return false;
      final results = await Future.wait([
        _loadPrices().then((_) => true),
        _loadOwned(),
      ]);
      return results.last;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadOwned() async {
    final revision = _revision;
    try {
      final addition = _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (_disposed || response.error != null) return false;
      final owned = <String>{}, pending = <String>{};
      final toAcknowledge = <PurchaseDetails>[];
      for (final purchase in response.pastPurchases) {
        if (!Products.all.contains(purchase.productID)) continue;
        switch (purchase.status) {
          case PurchaseStatus.purchased || PurchaseStatus.restored:
            owned.add(purchase.productID);
            toAcknowledge.add(purchase);
          case PurchaseStatus.pending:
            pending.add(purchase.productID);
          case PurchaseStatus.error || PurchaseStatus.canceled:
            break;
        }
      }
      // A checkout update received while this query was in flight is newer
      // than its snapshot. Preserve those products, including pending removals.
      for (final entry in _lastUpdate.entries) {
        if (entry.value <= revision) continue;
        final id = entry.key;
        owned.remove(id);
        pending.remove(id);
        if (entitlements.owned.contains(id)) owned.add(id);
        if (entitlements.pending.contains(id)) pending.add(id);
      }
      // Replace rather than merge so a refund also locks the item again.
      update(
        entitlements: Entitlements(owned: owned, pending: pending),
        checked: true,
      );
      // Resume can recover a result whose stream callback was missed while
      // the app was in the background. An absent item is not a cancellation.
      for (final id in _waiting.keys.toList()) {
        if (has(id)) {
          _waiting.remove(id)?.complete(PurchaseOutcome.owned);
        } else if (isPending(id)) {
          _waiting.remove(id)?.complete(PurchaseOutcome.pending);
        }
      }
      await Future.wait(toAcknowledge.map(_acknowledge));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _acknowledge(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _store.completePurchase(purchase);
    } catch (_) {
      // Retried on the next launch or resume, well within Play's 3 days.
    }
  }

  void _finishWaiting(PurchaseOutcome outcome) {
    final waiting = _waiting.values.toList();
    _waiting.clear();
    for (final waiter in waiting) {
      waiter.complete(outcome);
    }
  }

  void _onUpdates(List<PurchaseDetails> purchases) {
    if (_disposed) return;
    for (final purchase in purchases) {
      final id = purchase.productID;
      // Android reports a dismissed/failed checkout with no product ID when
      // its purchase list is empty. There is only one active checkout.
      if (id.isEmpty) {
        if (purchase.status == PurchaseStatus.canceled) {
          _finishWaiting(PurchaseOutcome.cancelled);
        } else if (purchase.status == PurchaseStatus.error) {
          _finishWaiting(PurchaseOutcome.failed);
        }
        continue;
      }
      if (!Products.all.contains(id)) continue;
      final owned = {...entitlements.owned};
      final pending = {...entitlements.pending};
      final PurchaseOutcome outcome;
      switch (purchase.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          owned.add(id);
          pending.remove(id);
          outcome = PurchaseOutcome.owned;
        case PurchaseStatus.pending:
          pending.add(id);
          outcome = PurchaseOutcome.pending;
        case PurchaseStatus.canceled:
          pending.remove(id);
          outcome = PurchaseOutcome.cancelled;
        case PurchaseStatus.error:
          pending.remove(id);
          outcome = PurchaseOutcome.failed;
      }
      _lastUpdate[id] = ++_revision;
      update(
        entitlements: Entitlements(owned: owned, pending: pending),
      );
      _waiting.remove(id)?.complete(outcome);
      // Apply the entitlement before awaiting the store so overlapping updates
      // cannot overwrite one another with an old copy of the owned set.
      if (outcome == PurchaseOutcome.owned) unawaited(_acknowledge(purchase));
    }
  }

  @override
  Future<PurchaseOutcome> buy(String id) async {
    if (_disposed || !Products.all.contains(id)) return PurchaseOutcome.failed;
    if (has(id)) return PurchaseOutcome.owned;
    if (isPending(id)) return PurchaseOutcome.pending;
    final product = _details[id];
    if (product == null || _waiting.isNotEmpty) {
      return PurchaseOutcome.failed;
    }
    final waiter = Completer<PurchaseOutcome>();
    _waiting[id] = waiter;
    try {
      final opened = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!opened) _waiting.remove(id)?.complete(PurchaseOutcome.failed);
    } on Exception catch (_) {
      // Play says "already owned" this way when our copy is out of date.
      await refresh();
      _waiting
          .remove(id)
          ?.complete(has(id) ? PurchaseOutcome.owned : PurchaseOutcome.failed);
    }
    return waiter.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _finishWaiting(PurchaseOutcome.failed);
    unawaited(_updates?.cancel());
    super.dispose();
  }
}
