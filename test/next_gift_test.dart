import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_props.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

const _minute = 60000;

void main() {
  group('nextDeskGift', () {
    test('a new user is pointed at the first-focus plant', () {
      final gift = nextDeskGift(const [], 0)!;
      expect(gift.prop.key, 'plant');
      expect(gift.needsFirstFocus, isTrue);
      expect(gift.progress, 0);
    });

    test('after the plant, the mug counts lifetime finished minutes', () {
      final gift = nextDeskGift(const ['plant'], 25 * _minute)!;
      expect(gift.prop.key, 'mug');
      expect(gift.needsFirstFocus, isFalse);
      expect(gift.remainingMinutes, 35);
      expect(gift.doneMinutes, 25);
      expect(gift.progress, closeTo(25 / 60, 1e-9));
    });

    test('partial minutes round up so the line never says 0', () {
      final gift = nextDeskGift(const ['plant'], 59 * _minute + 30000)!;
      expect(gift.remainingMinutes, 1);
      expect(gift.doneMinutes, 59);
    });

    test(
      'default props are never the next gift and none is left at the end',
      () {
        expect(nextDeskGift(const ['plant', 'mug'], 75 * _minute), isNull);
        // The default lamp is skipped even when it has no unlock timestamp.
        expect(
          nextDeskGift(const ['plant'], 0)!.prop.availableByDefault,
          isFalse,
        );
      },
    );
  });

  Future<MemoryStore> pumpApp(WidgetTester tester, FocusState state) async {
    await loadAppFont();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore()..raw = state.encode();
    await tester.pumpWidget(
      FocusFriendApp(engine: SessionEngine(store), locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
    'home shows the next gift and the collection shows its progress',
    (tester) async {
      final store = await pumpApp(
        tester,
        FocusState(
          completedMs: 25 * _minute,
          completedCount: 1,
          unlocks: {'plant': 1},
        ),
      );
      final line = find.byKey(const ValueKey('next-gift-mug'));
      expect(line, findsOneWidget);
      expect(
        find.descendant(of: line, matching: find.text('따뜻한 머그컵까지 35분')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('모은 소품'));
      await tester.tap(find.text('모은 소품'));
      await tester.pumpAndSettle();
      final progress = find.byKey(const ValueKey('collection-progress-mug'));
      await tester.ensureVisible(progress);
      expect(
        find.descendant(of: progress, matching: find.text('25/60분')),
        findsOneWidget,
      );
      // Unlocked and default props show no progress bar.
      expect(
        find.byKey(const ValueKey('collection-progress-plant')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('collection-progress-lamp')),
        findsNothing,
      );
      expect(store.commits, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a new user sees the first-focus plant without a bar', (
    tester,
  ) async {
    await pumpApp(tester, FocusState());
    final line = find.byKey(const ValueKey('next-gift-plant'));
    expect(line, findsOneWidget);
    expect(
      find.descendant(of: line, matching: find.text('첫 집중을 마치면 작은 화분')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: line, matching: find.byType(LinearProgressIndicator)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the line disappears once every prop is earned', (tester) async {
    await pumpApp(
      tester,
      FocusState(
        completedMs: 90 * _minute,
        completedCount: 4,
        unlocks: {'plant': 1, 'mug': 2},
      ),
    );
    expect(find.byKey(const ValueKey('next-gift-mug')), findsNothing);
    expect(find.byKey(const ValueKey('next-gift-plant')), findsNothing);
    expect(find.byKey(const ValueKey('today-focus')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final mode in SessionMode.values) {
    testWidgets(
      'completed ${mode.name} ${mode == SessionMode.focus ? 'shows' : 'hides'} the next gift',
      (tester) async {
        final now = DateTime(2026, 11, 19, 15).millisecondsSinceEpoch;
        final duration = mode == SessionMode.focus ? 25 * _minute : _minute;
        await pumpApp(
          tester,
          FocusState(
            completedMs: 25 * _minute,
            completedCount: 1,
            unlocks: {'plant': now},
            active: Session(
              id: 'done',
              mode: mode,
              status: SessionStatus.completed,
              startedAt: now - duration,
              durationMs: duration,
              remainingMs: 0,
              actualMs: duration,
              finishedAt: now,
              rewards: mode == SessionMode.focus ? const ['plant'] : const [],
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('next-gift-mug')),
          mode == SessionMode.focus ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
