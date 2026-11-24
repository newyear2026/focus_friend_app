import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

void main() {
  for (final friend in FocusFriend.values.where(
    (friend) => friend != FocusFriend.redpanda,
  )) {
    testWidgets(
      '${friend.name}: collection previews the selected room without changing shared rewards',
      (tester) async {
        await loadAppFont();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final saved = FocusState(
          friend: friend,
          completedMs: 25 * 60000,
          completedCount: 1,
          unlocks: {'plant': 1234},
        ).encode();
        final store = MemoryStore()..raw = saved;
        final engine = SessionEngine(store);
        await tester.pumpWidget(
          FocusFriendApp(engine: engine, locale: const Locale('ko')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
        await tester.pumpAndSettle();
        final collection = find.byKey(const ValueKey('collection-tile'));
        await tester.ensureVisible(collection);
        await tester.pumpAndSettle();
        expect(find.text('2개의 작은 선물'), findsOneWidget);
        await tester.tap(collection);
        await tester.pumpAndSettle();

        final preview = tester.widget<DeskIllustration>(
          find.byType(DeskIllustration),
        );
        expect(preview.friend, friend);
        expect(preview.unlocked, {'plant'});
        for (final (key, icon) in [
          ('plant', Icons.check_circle),
          ('mug', Icons.lock_outline),
          ('lamp', Icons.check_circle),
        ]) {
          final row = find.byKey(ValueKey('collection-item-$key'));
          await tester.ensureVisible(row);
          expect(
            find.descendant(of: row, matching: find.byIcon(icon)),
            findsOneWidget,
          );
        }
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(DeskIllustration), findsNothing);
        expect(store.raw, saved);
        expect(store.commits, 0);
        expect(engine.state.unlocks, {'plant': 1234});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
