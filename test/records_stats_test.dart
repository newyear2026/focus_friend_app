import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_records.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/session_engine.dart';

const minute = 60000;

Session done(DateTime start, int minutes) => Session(
  id: '${start.millisecondsSinceEpoch}',
  mode: SessionMode.focus,
  status: SessionStatus.completed,
  startedAt: start.millisecondsSinceEpoch,
  durationMs: minutes * minute,
  remainingMs: 0,
  actualMs: minutes * minute,
  finishedAt: start.millisecondsSinceEpoch + minutes * minute,
);

// Thursday 15 October 2026: this week has Mon 45, Tue 80 and Thu 75 minutes.
final today = DateTime(2026, 10, 15, 22);
FocusState sample() => FocusState(
  history: [
    done(DateTime(2026, 10, 15, 20, 0), 50),
    done(DateTime(2026, 10, 15, 21, 0), 25),
    done(DateTime(2026, 10, 13, 20, 30), 80),
    done(DateTime(2026, 10, 12, 18, 0), 45),
  ],
  dailyFocus: {
    for (final d in [1, 2, 3, 4, 5, 6, 8, 9])
      '2026-10-0$d': DailyFocus(
        milliseconds: (d == 9 ? 125 : 50) * minute,
        count: 2,
      ),
    '2026-10-12': const DailyFocus(milliseconds: 45 * minute, count: 1),
    '2026-10-13': const DailyFocus(milliseconds: 80 * minute, count: 2),
    '2026-10-15': const DailyFocus(milliseconds: 75 * minute, count: 2),
    '2026-09-14': const DailyFocus(milliseconds: 60 * minute, count: 2),
  },
);

Widget harness(FocusState state, {Locale locale = const Locale('ko')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FocusRecords(state: state, now: today),
      ),
    );

bool nextEnabled(WidgetTester tester, String key) =>
    tester.widget<IconButton>(find.byKey(ValueKey(key))).onPressed != null;

void main() {
  testWidgets('calendar tab adds this week next to the month totals', (
    tester,
  ) async {
    await tester.pumpWidget(harness(sample()));
    await tester.pumpAndSettle();
    expect(find.textContaining('이번 주 3시간 20분'), findsOneWidget);
    expect(find.textContaining('이번 달 11시간 15분'), findsOneWidget);
    expect(find.text('2026년 10월'), findsOneWidget);
  });

  testWidgets('week tab shows bars, comparison, best day and time of day', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // Tall enough that the lazy list builds every row.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(sample()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('records-tab-week')));
    await tester.pumpAndSettle();
    expect(find.text('10월 11일 – 10월 17일'), findsOneWidget);
    expect(find.text('3시간 20분'), findsOneWidget);
    // Last week up to Thursday: 50 x 4 (Sun 4 .. Thu 8, no focus on Wed 7).
    expect(find.text('지난주와 같아요'), findsOneWidget);
    expect(find.byKey(const ValueKey('week-bars')), findsOneWidget);
    expect(find.bySemanticsLabel('화 80분'), findsOneWidget);
    expect(find.text('가장 많이 한 날 · 화요일 1시간 20분'), findsOneWidget);
    expect(find.text('밤에 가장 오래 집중해요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('previous-week')));
    await tester.pumpAndSettle();
    expect(find.text('10월 4일 – 10월 10일'), findsOneWidget);
    expect(find.text('5시간 25분'), findsOneWidget);
    expect(find.text('지난주보다 5시간 25분 더'), findsNothing);

    expect(find.byKey(const ValueKey('this-week')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-week')));
    await tester.pumpAndSettle();
    expect(find.text('10월 11일 – 10월 17일'), findsOneWidget);
    expect(find.byKey(const ValueKey('this-week')), findsNothing);
    // This week is the last one: the next arrow is dimmed and does nothing.
    expect(nextEnabled(tester, 'next-week'), isFalse);
    await tester.tap(find.byKey(const ValueKey('next-week')));
    await tester.pumpAndSettle();
    expect(find.text('10월 11일 – 10월 17일'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('previous-week')));
    }
    await tester.pumpAndSettle();
    expect(find.text('9월 20일 – 9월 26일'), findsOneWidget);
    expect(find.text('이 주에는 아직 집중 기록이 없어요.'), findsOneWidget);
    // One tap back from three weeks ago.
    await tester.tap(find.byKey(const ValueKey('this-week')));
    await tester.pumpAndSettle();
    expect(find.text('10월 11일 – 10월 17일'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('month tab shows totals, streak and six months', (tester) async {
    final semantics = tester.ensureSemantics();
    // Tall enough that the lazy list builds every row.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(sample()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('records-tab-month')));
    await tester.pumpAndSettle();
    // 7 x 50 + 125 + 45 + 80 + 75 = 675 minutes on 11 days.
    expect(find.text('11시간 15분'), findsOneWidget);
    expect(find.text('지난달보다 10시간 15분 더'), findsOneWidget);
    expect(find.text('11일'), findsOneWidget);
    expect(find.text('6일'), findsOneWidget);
    expect(find.text('1시간 1분'), findsOneWidget);
    expect(find.bySemanticsLabel('9월 1시간'), findsOneWidget);
    expect(find.text('가장 많이 한 날 · 10월 9일 2시간 5분'), findsOneWidget);

    expect(find.byKey(const ValueKey('this-month')), findsNothing);
    // This month is the last one: the next arrow is dimmed and does nothing.
    expect(nextEnabled(tester, 'next-month'), isFalse);
    await tester.tap(find.byKey(const ValueKey('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026년 10월'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('previous-month')));
    await tester.tap(find.byKey(const ValueKey('previous-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월'), findsOneWidget);
    expect(find.text('이 달에는 아직 집중 기록이 없어요.'), findsOneWidget);
    expect(nextEnabled(tester, 'next-month'), isTrue);
    await tester.tap(find.byKey(const ValueKey('this-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026년 10월'), findsOneWidget);
    expect(find.byKey(const ValueKey('this-month')), findsNothing);

    // The calendar shares the month and can still look ahead. The month tab
    // then offers the way back and does not compare November with October.
    await tester.tap(find.byKey(const ValueKey('records-tab-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026년 11월'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('records-tab-month')));
    await tester.pumpAndSettle();
    expect(find.text('이 달에는 아직 집중 기록이 없어요.'), findsOneWidget);
    expect(find.textContaining('지난달'), findsNothing);
    expect(find.byKey(const ValueKey('this-month')), findsOneWidget);
    semantics.dispose();
  });

  for (final locale in const [Locale('en'), Locale('es'), Locale('ja')]) {
    testWidgets('$locale tabs fit a small phone with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(harness(sample(), locale: locale));
      await tester.pumpAndSettle();
      for (final tab in ['week', 'month', 'calendar']) {
        await tester.tap(find.byKey(ValueKey('records-tab-$tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale $tab');
      }
    });
  }
}
