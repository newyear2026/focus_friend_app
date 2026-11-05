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
  StreamSubscription<List<PurchaseDetails>>? _updates;
  Future<bool>? _refreshing;

  @override
  Future<void> start() async {
    try {
      if (!await _store.isAvailable()) return;
      _updates = _store.purchaseStream.listen(
        _onUpdates,
        onError: (Object _) {},
      );
      await Future.wait([_loadPrices(), refresh()]);
    } catch (_) {
      // No Play Store or no network: free friends and ads still work.
    }
  }

  Future<void> _loadPrices() async {
    final response = await _store.queryProductDetails(Products.all);
    for (final product in response.productDetails) {
      _details[product.id] = product;
    }
    update(prices: {for (final p in _details.values) p.id: p.price});
  }

  @override
  Future<bool> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    try {
      final addition = _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) return false;
      final owned = <String>{}, pending = <String>{};
      for (final purchase in response.pastPurchases) {
        switch (purchase.status) {
          case PurchaseStatus.purchased || PurchaseStatus.restored:
            owned.add(purchase.productID);
            await _acknowledge(purchase);
          case PurchaseStatus.pending:
            pending.add(purchase.productID);
          case PurchaseStatus.error || PurchaseStatus.canceled:
            break;
        }
      }
      // Replace rather than merge so a refund also locks the item again.
      update(
        entitlements: Entitlements(owned: owned, pending: pending),
        checked: true,
      );
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

  Future<void> _onUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final id = purchase.productID;
      final owned = {...entitlements.owned};
      final pending = {...entitlements.pending};
      final PurchaseOutcome outcome;
      switch (purchase.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          owned.add(id);
          pending.remove(id);
          outcome = PurchaseOutcome.owned;
          await _acknowledge(purchase);
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
      update(
        entitlements: Entitlements(owned: owned, pending: pending),
      );
      _waiting.remove(id)?.complete(outcome);
    }
  }

  @override
  Future<PurchaseOutcome> buy(String id) async {
    final product = _details[id];
    if (product == null || _waiting.containsKey(id)) {
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
      _waiting.remove(id)?.complete(PurchaseOutcome.failed);
      await refresh();
    }
    return waiter.future;
  }

  @override
  void dispose() {
    unawaited(_updates?.cancel());
    super.dispose();
  }
}
