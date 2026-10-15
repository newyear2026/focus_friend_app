import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_picker.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

// Wait for route/save microtasks across frames; the preview loops forever.
Future<void> pumpPreviewTransition(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('old saves and unknown friend ids use the original room', () {
    final json = FocusState().toJson()..remove('friendId');
    expect(FocusState.decode(jsonEncode(json)).friend, FocusFriend.redpanda);
    json['friendId'] = 'future-friend';
    expect(FocusState.decode(jsonEncode(json)).friend, FocusFriend.redpanda);
  });

  test(
    'applying a friend persists without changing records or preferences',
    () async {
      final store = MemoryStore();
      var now = 1000000;
      final engine = SessionEngine(store, clock: () => now);
      await engine.restore();
      await engine.start(const Duration(minutes: 25));
      final session = engine.state.active!;
      now = session.endAt!;
      await engine.complete(session.id);
      await engine.dismiss(session.id);
      await engine.saveKeepScreenOn(true);
      final before = engine.state.toJson()
        ..remove('revision')
        ..remove('friendId');
      await engine.saveFriend(FocusFriend.fennec);
      final restored = SessionEngine(store);
      await restored.restore();
      expect(restored.state.friend, FocusFriend.fennec);
      expect(
        restored.state.toJson()
          ..remove('revision')
          ..remove('friendId'),
        before,
      );
      store.failBefore = true;
      await expectLater(engine.saveFriend(FocusFriend.otter), throwsStateError);
      expect(engine.state.friend, FocusFriend.fennec);
    },
  );

  testWidgets(
    'preview can be cancelled; failed apply retries and returns to the desk',
    (tester) async {
      await loadAppFont();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      final engine = SessionEngine(store);
      await tester.pumpWidget(
        FocusFriendApp(engine: engine, locale: const Locale('ko')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
      await tester.pumpAndSettle();
      expect(find.text('함께할 친구'), findsOneWidget);
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
      await tester.tap(find.byKey(const ValueKey('friend-preview')));
      await pumpPreviewTransition(tester);
      expect(find.byType(FriendPreview), findsOneWidget);
      expect(engine.state.friend, FocusFriend.redpanda);
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      expect(engine.state.friend, FocusFriend.redpanda);
      await tester.tap(find.byKey(const ValueKey('friend-preview')));
      await pumpPreviewTransition(tester);
      store.failBefore = true;
      await tester.tap(find.byKey(const ValueKey('friend-apply')));
      await pumpPreviewTransition(tester);
      expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(engine.state.friend, FocusFriend.redpanda);
      await tester.tap(find.byKey(const ValueKey('friend-apply')));
      await pumpPreviewTransition(tester);
      expect(find.byType(FriendPreview), findsNothing);
      expect(engine.state.friend, FocusFriend.fennec);
      expect(
        tester.widget<DeskIllustration>(find.byType(DeskIllustration)).friend,
        FocusFriend.fennec,
      );
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pumpAndSettle();
      expect(engine.state.active!.durationMs, 25 * 60000);
      expect(
        tester.widget<DeskIllustration>(find.byType(DeskIllustration)).friend,
        FocusFriend.fennec,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final language in ['ko', 'en', 'es', 'ja']) {
    testWidgets(
      '$language friend picker and preview fit large text on a small phone',
      (tester) async {
        await loadAppFont();
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          FocusFriendApp(
            engine: SessionEngine(MemoryStore()),
            locale: Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
        await tester.pumpAndSettle();
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
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('friend-preview')));
        await pumpPreviewTransition(tester);
        await tester.ensureVisible(find.byKey(const ValueKey('friend-apply')));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
