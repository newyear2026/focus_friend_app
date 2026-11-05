import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/purchases.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

// Replace only the SDK boundary: every test exercises the production adapter.
class _Store implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final addition = _AndroidAddition();
  final launched = <String>[];
  final acknowledged = <String>[];
  final acknowledgementGates = <String, Completer<void>>{};
  bool available = true;
  bool opens = true;
  bool failAcknowledgement = false;
  Exception? launchError;
  IAPError? productError;
  Set<String> products = Products.all;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final id in products.intersection(ids))
            ProductDetails(
              id: id,
              title: id,
              description: id,
              price: 'MX\$15.00',
              rawPrice: 15,
              currencyCode: 'MXN',
            ),
        ],
        notFoundIDs: ids.difference(products).toList(),
        error: productError,
      );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    launched.add(purchaseParam.productDetails.id);
    if (launchError case final error?) throw error;
    return opens;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    acknowledged.add(purchase.productID);
    if (acknowledgementGates[purchase.productID] case final gate?) {
      await gate.future;
    }
    if (failAcknowledgement) throw Exception('Temporary acknowledgement error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getPlatformAddition) return addition;
    return super.noSuchMethod(invocation);
  }
}

class _AndroidAddition implements InAppPurchaseAndroidPlatformAddition {
  List<GooglePlayPurchaseDetails> purchases = [];
  IAPError? error;
  Completer<QueryPurchaseDetailsResponse>? queryGate;

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases({
    String? applicationUserName,
  }) async =>
      queryGate?.future ??
      QueryPurchaseDetailsResponse(pastPurchases: purchases, error: error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GooglePlayPurchaseDetails _purchase(
  String id, {
  PurchaseStatus status = PurchaseStatus.purchased,
  bool acknowledged = false,
}) => GooglePlayPurchaseDetails(
  productID: id,
  purchaseID: 'order-$id',
  verificationData: PurchaseVerificationData(
    localVerificationData: '{}',
    serverVerificationData: 'token-$id',
    source: 'google_play',
  ),
  transactionDate: '1000',
  status: status,
  billingClientPurchase: PurchaseWrapper(
    orderId: 'order-$id',
    packageName: 'com.example.test',
    purchaseTime: 1000,
    purchaseToken: 'token-$id',
    signature: 'test-signature',
    products: [id],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: acknowledged,
    purchaseState: status == PurchaseStatus.pending
        ? PurchaseStateWrapper.pending
        : PurchaseStateWrapper.purchased,
  ),
);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late _Store store;
  late PlayPurchases purchases;
  late bool disposed;

  setUp(() {
    store = _Store();
    purchases = PlayPurchases(store: store);
    disposed = false;
  });

  tearDown(() async {
    if (!disposed) purchases.dispose();
    await store.updates.close();
  });

  test(
    'loads localized prices and restores paid but not pending items',
    () async {
      store.addition.purchases = [
        _purchase(Products.otter),
        _purchase(Products.removeAds, status: PurchaseStatus.pending),
      ];
      await purchases.start();
      expect(purchases.checked, isTrue);
      expect(purchases.price(Products.otter), 'MX\$15.00');
      expect(purchases.has(Products.otter), isTrue);
      expect(purchases.adsRemoved, isFalse);
      expect(purchases.isPending(Products.removeAds), isTrue);
      expect(store.acknowledged, [Products.otter]);
    },
  );

  test(
    'successful purchase unlocks and acknowledges the nonconsumable',
    () async {
      await purchases.start();
      final result = purchases.buy(Products.otter);
      store.updates.add([_purchase(Products.otter)]);
      expect(await result, PurchaseOutcome.owned);
      expect(purchases.has(Products.otter), isTrue);
      expect(store.launched, [Products.otter]);
      expect(store.acknowledged, [Products.otter]);
    },
  );

  test('pending payment stays locked until a later purchased update', () async {
    await purchases.start();
    final result = purchases.buy(Products.removeAds);
    store.updates.add([
      _purchase(Products.removeAds, status: PurchaseStatus.pending),
    ]);
    expect(await result, PurchaseOutcome.pending);
    expect(purchases.adsRemoved, isFalse);
    expect(store.acknowledged, isEmpty);
    store.updates.add([_purchase(Products.removeAds)]);
    await _flush();
    expect(purchases.adsRemoved, isTrue);
    expect(purchases.isPending(Products.removeAds), isFalse);
    expect(store.acknowledged, [Products.removeAds]);
  });

  for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
    test(
      '$status with a product ID ends the request without unlocking',
      () async {
        await purchases.start();
        final result = purchases.buy(Products.fennec);
        store.updates.add([_purchase(Products.fennec, status: status)]);
        expect(
          await result,
          status == PurchaseStatus.canceled
              ? PurchaseOutcome.cancelled
              : PurchaseOutcome.failed,
        );
        expect(purchases.has(Products.fennec), isFalse);
        expect(store.acknowledged, isEmpty);
      },
    );

    test(
      'Android $status without a product ID ends the active request',
      () async {
        await purchases.start();
        PurchaseOutcome? outcome;
        unawaited(
          purchases.buy(Products.fennec).then((value) => outcome = value),
        );
        // Billing returns no purchase list on dismissal/failure. The Flutter
        // Android plugin represents that as a single update with productID ''.
        store.updates.add([_purchase('', status: status)]);
        await _flush();
        expect(
          outcome,
          status == PurchaseStatus.canceled
              ? PurchaseOutcome.cancelled
              : PurchaseOutcome.failed,
        );
        expect(purchases.has(Products.fennec), isFalse);
        expect(store.acknowledged, isEmpty);
      },
    );
  }

  test('unavailable store never opens checkout', () async {
    store.available = false;
    await purchases.start();
    expect(purchases.checked, isFalse);
    expect(await purchases.buy(Products.otter), PurchaseOutcome.failed);
    expect(store.launched, isEmpty);
  });

  test(
    'missing products cannot open checkout and can recover on refresh',
    () async {
      store.products = {};
      store.productError = IAPError(
        source: 'google_play',
        code: 'NETWORK_ERROR',
        message: 'Offline',
      );
      await purchases.start();
      expect(purchases.price(Products.otter), isNull);
      expect(await purchases.buy(Products.otter), PurchaseOutcome.failed);
      expect(store.launched, isEmpty);
      store.products = Products.all;
      store.productError = null;
      await purchases.refresh();
      expect(purchases.price(Products.otter), 'MX\$15.00');
    },
  );

  test(
    'already owned products return ownership without launching checkout',
    () async {
      store.addition.purchases = [
        _purchase(Products.allFriends, acknowledged: true),
      ];
      await purchases.start();
      expect(await purchases.buy(Products.otter), PurchaseOutcome.owned);
      expect(await purchases.buy(Products.removeAds), PurchaseOutcome.owned);
      expect(store.launched, isEmpty);
    },
  );

  test('pending products cannot start another checkout', () async {
    store.addition.purchases = [
      _purchase(Products.otter, status: PurchaseStatus.pending),
    ];
    await purchases.start();
    expect(await purchases.buy(Products.otter), PurchaseOutcome.pending);
    expect(store.launched, isEmpty);
  });

  test('repeated taps launch a single checkout', () async {
    await purchases.start();
    final result = purchases.buy(Products.otter);
    expect(await purchases.buy(Products.otter), PurchaseOutcome.failed);
    store.updates.add([_purchase(Products.otter)]);
    expect(await result, PurchaseOutcome.owned);
    expect(store.launched, [Products.otter]);
  });

  for (final status in [PurchaseStatus.purchased, PurchaseStatus.pending]) {
    test(
      'resume recovers checkout $status when its stream callback was missed',
      () async {
        await purchases.start();
        PurchaseOutcome? outcome;
        unawaited(
          purchases.buy(Products.otter).then((value) => outcome = value),
        );
        store.addition.purchases = [_purchase(Products.otter, status: status)];
        await purchases.refresh();
        await _flush();
        expect(
          outcome,
          status == PurchaseStatus.purchased
              ? PurchaseOutcome.owned
              : PurchaseOutcome.pending,
        );
        expect(
          purchases.has(Products.otter),
          status == PurchaseStatus.purchased,
        );
      },
    );
  }

  test('failed checkout launch ends the request and allows a retry', () async {
    store.opens = false;
    await purchases.start();
    expect(await purchases.buy(Products.otter), PurchaseOutcome.failed);
    store.opens = true;
    final result = purchases.buy(Products.otter);
    store.updates.add([_purchase(Products.otter)]);
    expect(await result, PurchaseOutcome.owned);
    expect(store.launched, [Products.otter, Products.otter]);
  });

  test('launch exceptions refresh ownership without throwing', () async {
    await purchases.start();
    store.launchError = PlatformException(code: 'ITEM_ALREADY_OWNED');
    store.addition.purchases = [_purchase(Products.otter, acknowledged: true)];
    await purchases.buy(Products.otter);
    expect(purchases.has(Products.otter), isTrue);
    expect(store.acknowledged, isEmpty);
  });

  test(
    'a failed refresh preserves ownership; successful refund removes it',
    () async {
      store.addition.purchases = [
        _purchase(Products.allFriends, acknowledged: true),
      ];
      await purchases.start();
      expect(purchases.adsRemoved, isTrue);
      store.addition.purchases = [];
      store.addition.error = IAPError(
        source: 'google_play',
        code: 'NETWORK_ERROR',
        message: 'Offline',
      );
      expect(await purchases.refresh(), isFalse);
      expect(purchases.adsRemoved, isTrue);
      store.addition.error = null;
      expect(await purchases.refresh(), isTrue);
      expect(purchases.adsRemoved, isFalse);
      expect(purchases.has(Products.otter), isFalse);
    },
  );

  test(
    'failed acknowledgement preserves purchase and retries on refresh',
    () async {
      store.failAcknowledgement = true;
      await purchases.start();
      final result = purchases.buy(Products.otter);
      store.updates.add([_purchase(Products.otter)]);
      expect(await result, PurchaseOutcome.owned);
      expect(purchases.has(Products.otter), isTrue);
      store.failAcknowledgement = false;
      store.addition.purchases = [_purchase(Products.otter)];
      expect(await purchases.refresh(), isTrue);
      expect(store.acknowledged, [Products.otter, Products.otter]);
    },
  );

  test(
    'concurrent updates retain both purchases while acknowledgement waits',
    () async {
      await purchases.start();
      final gate = Completer<void>();
      store.acknowledgementGates[Products.otter] = gate;
      store.updates.add([_purchase(Products.otter)]);
      await _flush();
      store.updates.add([_purchase(Products.removeAds)]);
      await _flush();
      gate.complete();
      await _flush();
      expect(purchases.has(Products.otter), isTrue);
      expect(purchases.adsRemoved, isTrue);
    },
  );

  test(
    'an old refresh response cannot revoke a newly reported purchase',
    () async {
      await purchases.start();
      final gate = Completer<QueryPurchaseDetailsResponse>();
      store.addition.queryGate = gate;
      final refresh = purchases.refresh();
      store.updates.add([_purchase(Products.otter)]);
      await _flush();
      expect(purchases.has(Products.otter), isTrue);
      gate.complete(QueryPurchaseDetailsResponse(pastPurchases: []));
      await refresh;
      expect(purchases.has(Products.otter), isTrue);
    },
  );

  test('a stream error releases the active checkout', () async {
    await purchases.start();
    PurchaseOutcome? outcome;
    unawaited(purchases.buy(Products.otter).then((value) => outcome = value));
    store.updates.addError(Exception('Billing connection interrupted'));
    await _flush();
    expect(outcome, PurchaseOutcome.failed);
    expect(purchases.has(Products.otter), isFalse);
  });

  test('disposing the adapter releases checkout and stops updates', () async {
    await purchases.start();
    PurchaseOutcome? outcome;
    unawaited(purchases.buy(Products.otter).then((value) => outcome = value));
    purchases.dispose();
    disposed = true;
    store.updates.add([_purchase(Products.otter)]);
    await _flush();
    expect(outcome, PurchaseOutcome.failed);
    expect(store.updates.hasListener, isFalse);
    expect(store.acknowledged, isEmpty);
  });
}
