import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_picker.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets('capture the selected four-tab friend flow', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final (font, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font)..addFont(rootBundle.load(path))).load();
    }
    final now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
    final store = MemoryStore()
      ..raw = FocusState(
        dailyFocus: {
          '2026-10-14': const DailyFocus(milliseconds: 50 * 60000, count: 2),
        },
        completedMs: 50 * 60000,
        completedCount: 2,
        unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
      ).encode();
    final engine = SessionEngine(store, clock: () => now);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(RoomScreen));
    await tester.runAsync(() async {
      for (final asset in [
        for (final friend in FocusFriend.values)
          if (friend.sceneAsset != null) friend.sceneAsset!,
        'assets/images/immersive/room-evening.png',
        'assets/images/immersive/redpanda-reference.png',
        'assets/images/immersive/redpanda-slow-connected-body-38.png',
        'assets/images/immersive/redpanda-fixed-notebook.png',
        for (final prop in ['plant', 'mug', 'lamp'])
          'assets/images/immersive/reward-$prop.png',
        for (final tab in ['desk', 'records', 'settings'])
          'assets/images/immersive/nav-$tab.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/design/friend-picker-implementation')
          ..createSync(recursive: true);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('redpanda-home');
    await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
    await capture('friends-top');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('friend-card-fennec')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('friend-grid')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('friend-card-fennec')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('friend-card-fennec')));
    await capture('friends-selected');
    await tester.tap(find.byKey(const ValueKey('friend-preview')));
    await capture('fennec-preview');
    await tester.tap(find.byKey(const ValueKey('friend-apply')));
    await capture('fennec-home');
    expect(engine.state.friend, FocusFriend.fennec);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-2')));
    await capture('records');
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await capture('settings');
    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await capture('fennec-focusing');
    expect(engine.state.active!.durationMs, 25 * 60000);
    await tester.tap(find.text('잠시 멈추기'));
    await capture('fennec-paused');
    await tester.pumpWidget(const SizedBox.shrink());

    // Small-screen/large-text capture in a new, isolated store.
    tester.view.physicalSize = const Size(640, 1280);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FocusFriendApp(
          engine: SessionEngine(MemoryStore()),
          locale: const Locale('ko'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
    await capture('compact-friends');
    await tester.tap(find.byKey(const ValueKey('friend-preview')));
    await capture('compact-preview');
    expect(find.byType(FriendPreview), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('friend-apply')));
    await capture('compact-preview-details');
    await tester.tap(find.byKey(const ValueKey('friend-apply')));
    await tester.pumpAndSettle();
    expect(find.byType(FriendPreview), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
