import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_picker.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/purchase_sheet.dart';
import 'package:focus_friend_app/purchases.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'friend_picker_test.dart' show pumpPreviewTransition;
import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

const _prices = {
  Products.penguin: '₩1,500',
  Products.otter: '₩1,500',
  Products.squirrel: '₩1,500',
  Products.fennec: '₩1,500',
  Products.removeAds: '₩1,000',
  Products.allFriends: '₩3,500',
};

/// Google Play stand-in: answers every purchase with [next].
class FakePurchases extends Purchases {
  FakePurchases({super.entitlements, super.checked = true})
    : super(prices: _prices);
  PurchaseOutcome next = PurchaseOutcome.owned;
  final bought = <String>[];

  /// Google Play's first answer about what is owned.
  void answer() => update(checked: true);

  @override
  Future<PurchaseOutcome> buy(String id) async {
    bought.add(id);
    final e = entitlements;
    update(
      entitlements: switch (next) {
        PurchaseOutcome.owned => Entitlements(
          owned: {...e.owned, id},
          pending: e.pending,
        ),
        PurchaseOutcome.pending => Entitlements(
          owned: e.owned,
          pending: {...e.pending, id},
        ),
        _ => e,
      },
    );
    return next;
  }
}

Future<void> _openFriends(WidgetTester tester, FocusFriendApp app) async {
  await loadAppFont();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
  await tester.pumpAndSettle();
}

void main() {
  group('entitlements', () {
    test('only the red panda is free; the others are sold', () {
      const none = Entitlements();
      expect(none.hasFriend(FocusFriend.redpanda), isTrue);
      expect(Products.forFriend(FocusFriend.redpanda), isNull);
      for (final friend in [
        FocusFriend.penguin,
        FocusFriend.otter,
        FocusFriend.squirrel,
        FocusFriend.fennec,
      ]) {
        expect(none.hasFriend(friend), isFalse, reason: friend.name);
        expect(Products.forFriend(friend), isNotNull);
      }
      expect(none.adsRemoved, isFalse);
    });

    test('the bundle covers every sold friend and ad removal', () {
      const bundle = Entitlements(owned: {Products.allFriends});
      for (final friend in FocusFriend.values) {
        expect(bundle.hasFriend(friend), isTrue, reason: friend.name);
      }
      expect(bundle.adsRemoved, isTrue);
    });

    test('one friend unlocks only that friend; ads stay', () {
      const otter = Entitlements(owned: {Products.otter});
      expect(otter.hasFriend(FocusFriend.otter), isTrue);
      expect(otter.hasFriend(FocusFriend.fennec), isFalse);
      expect(otter.adsRemoved, isFalse);
      expect(otter.has(Products.allFriends), isFalse);
    });

    test('pending is not owned, and owning clears pending', () {
      const waiting = Entitlements(pending: {Products.removeAds});
      expect(waiting.adsRemoved, isFalse);
      expect(waiting.isPending(Products.removeAds), isTrue);
      const paid = Entitlements(
        owned: {Products.allFriends},
        pending: {Products.removeAds},
      );
      expect(paid.isPending(Products.removeAds), isFalse);
    });
  });

  testWidgets('locked friends show a price; buying one applies it', (
    tester,
  ) async {
    final purchases = FakePurchases();
    final engine = SessionEngine(MemoryStore());
    await _openFriends(
      tester,
      FocusFriendApp(
        engine: engine,
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    expect(find.byType(BundleBanner), findsOneWidget);
    expect(find.byType(LockChip), findsNWidgets(3)); // penguin, otter, squirrel
    await tester.tap(find.byKey(const ValueKey('friend-card-otter')));
    await tester.tap(find.byKey(const ValueKey('friend-preview')));
    await pumpPreviewTransition(tester);
    expect(find.byKey(const ValueKey('friend-apply')), findsNothing);
    expect(find.text('₩1,500에 함께하기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('friend-buy')));
    await pumpPreviewTransition(tester);
    expect(purchases.bought, [Products.otter]);
    expect(find.byType(FriendPreview), findsNothing);
    expect(engine.state.friend, FocusFriend.otter);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a pending payment keeps the friend locked and says so', (
    tester,
  ) async {
    final purchases = FakePurchases()..next = PurchaseOutcome.pending;
    final engine = SessionEngine(MemoryStore());
    await _openFriends(
      tester,
      FocusFriendApp(
        engine: engine,
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('friend-card-otter')));
    await tester.tap(find.byKey(const ValueKey('friend-preview')));
    await pumpPreviewTransition(tester);
    await tester.tap(find.byKey(const ValueKey('friend-buy')));
    await pumpPreviewTransition(tester);
    expect(engine.state.friend, FocusFriend.redpanda);
    expect(find.text('결제 대기 중'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('friend-buy')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the bundle sheet lists what it unlocks and buys it', (
    tester,
  ) async {
    final purchases = FakePurchases(
      entitlements: const Entitlements(owned: {Products.otter}),
    );
    await _openFriends(
      tester,
      FocusFriendApp(
        engine: SessionEngine(MemoryStore()),
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('bundle-banner')));
    await tester.pumpAndSettle();
    expect(find.byType(BundleSheet), findsOneWidget);
    expect(find.text('보유'), findsOneWidget); // the otter
    expect(find.text('광고 제거'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bundle-buy')));
    await tester.pumpAndSettle();
    expect(purchases.bought, [Products.allFriends]);
    expect(find.byType(BundleSheet), findsNothing);
    expect(find.byType(BundleBanner), findsNothing);
    expect(find.byType(LockChip), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a friend Play says is not owned goes back to the red panda', (
    tester,
  ) async {
    final store = MemoryStore();
    final engine = SessionEngine(store);
    await engine.restore();
    await engine.saveFriend(FocusFriend.fennec);
    final purchases = FakePurchases(checked: false);
    await loadAppFont();
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.pumpAndSettle();
    // Play has not answered yet: keep what was chosen.
    expect(engine.state.friend, FocusFriend.fennec);
    purchases.answer();
    await tester.pumpAndSettle();
    expect(engine.state.friend, FocusFriend.redpanda);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('without a store every friend is open and nothing is sold', (
    tester,
  ) async {
    await _openFriends(
      tester,
      FocusFriendApp(
        engine: SessionEngine(MemoryStore()),
        locale: const Locale('ko'),
      ),
    );
    expect(find.byType(BundleBanner), findsNothing);
    expect(find.byType(LockChip), findsNothing);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    // Scroll past where the purchase tiles would be.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collection-tile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-bundle')), findsNothing);
    expect(find.byKey(const ValueKey('restore-purchases')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings lists purchases with owned and pending states', (
    tester,
  ) async {
    final purchases = FakePurchases(
      entitlements: const Entitlements(pending: {Products.removeAds}),
    );
    await _openFriends(
      tester,
      FocusFriendApp(
        engine: SessionEngine(MemoryStore()),
        purchases: purchases,
        locale: const Locale('ko'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restore-purchases')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-bundle')), findsOneWidget);
    expect(find.text('₩3,500'), findsOneWidget);
    expect(find.text('결제 대기 중'), findsOneWidget);
    expect(find.byKey(const ValueKey('restore-purchases')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
