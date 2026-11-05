import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_props.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

void main() {
  test('default lamp leaves old unlock timestamps and saves intact', () {
    for (final unlocks in <Map<String, int>>[
      {},
      {'plant': 1, 'mug': 2},
      {'plant': 1, 'mug': 2, 'lamp': 3},
    ]) {
      final raw = FocusState(unlocks: unlocks).encode();
      final restored = FocusState.decode(raw);
      final available = deskProps
          .where((prop) => prop.isAvailable(restored.unlocks.keys))
          .map((prop) => prop.key);
      expect(available, contains('lamp'));
      expect(available.length, unlocks.isEmpty ? 1 : 3);
      expect(restored.encode(), raw);
    }
  });

  for (final existingUser in [false, true]) {
    testWidgets(
      '${existingUser ? 'existing' : 'new'} user sees a default lamp in the room and collection',
      (tester) async {
        await loadAppFont();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final raw = FocusState(
          completedMs: existingUser ? 75 * 60000 : 0,
          completedCount: existingUser ? 3 : 0,
          unlocks: existingUser ? {'plant': 1, 'mug': 2} : {},
        ).encode();
        final store = MemoryStore()..raw = raw;
        await tester.pumpWidget(
          FocusFriendApp(
            engine: SessionEngine(store),
            locale: const Locale('ko'),
          ),
        );
        await tester.pumpAndSettle();
        final lamp = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/immersive/reward-lamp.png',
        );
        expect(lamp, findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('모은 소품'));
        expect(find.text('${existingUser ? 3 : 1}개의 작은 선물'), findsOneWidget);
        await tester.tap(find.text('모은 소품'));
        await tester.pumpAndSettle();
        final lampRow = find.byKey(const ValueKey('collection-item-lamp'));
        await tester.ensureVisible(lampRow);
        expect(
          find.descendant(of: lampRow, matching: find.text('기본 제공')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: lampRow,
            matching: find.byIcon(Icons.check_circle),
          ),
          findsOneWidget,
        );
        expect(find.text('정상 완료 누적 120분'), findsNothing);
        expect(store.raw, raw);
        expect(store.commits, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
