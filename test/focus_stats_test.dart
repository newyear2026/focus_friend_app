import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_stats.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';

const minute = 60000;

Session done(
  DateTime start,
  int minutes, {
  SessionMode mode = SessionMode.focus,
}) {
  final ms = minutes * minute;
  return Session(
    id: '${start.millisecondsSinceEpoch}',
    mode: mode,
    status: SessionStatus.completed,
    startedAt: start.millisecondsSinceEpoch,
    durationMs: ms,
    remainingMs: 0,
    actualMs: ms,
    finishedAt: start.millisecondsSinceEpoch + ms,
  );
}

FocusState withDays(Map<String, int> minutesByDay, {List<Session>? history}) =>
    FocusState(
      history: history,
      dailyFocus: {
        for (final entry in minutesByDay.entries)
          entry.key: DailyFocus(
            milliseconds: entry.value * minute,
            count: entry.value ~/ 25 == 0 ? 1 : entry.value ~/ 25,
          ),
      },
    );

void main() {
  // Thursday, mid October 2026.
  final today = DateTime(2026, 10, 15, 21);

  test('weeks start on Sunday like the calendar grid', () {
    expect(weekStart(today), DateTime(2026, 10, 11));
    expect(weekStart(DateTime(2026, 10, 11, 8)), DateTime(2026, 10, 11));
    expect(weekStart(DateTime(2026, 10, 17)), DateTime(2026, 10, 11));
    // Crosses a month boundary.
    expect(weekStart(DateTime(2026, 11, 2)), DateTime(2026, 11, 1));
    expect(weekStart(DateTime(2026, 10, 1)), DateTime(2026, 9, 27));
  });

  test('week totals, best day and same-period comparison', () {
    final state = withDays({
      // Previous week: Sun 4 .. Sat 10.
      '2026-10-05': 30, '2026-10-06': 25, '2026-10-09': 125, '2026-10-10': 50,
      // This week: Sun 11 .. today Thu 15.
      '2026-10-12': 45, '2026-10-13': 80, '2026-10-15': 75,
    });
    final week = weekStats(state, today, today);
    expect(week.start, DateTime(2026, 10, 11));
    expect(week.dayMs.map((ms) => ms ~/ minute), [0, 45, 80, 0, 75, 0, 0]);
    expect(week.totalMs, 200 * minute);
    expect(week.bestDay, 2);
    // Only Sun 4 .. Thu 8 of last week: Friday's 125 min is not counted yet.
    expect(week.comparedMs, 55 * minute);
    // A finished week compares against the whole previous week.
    final last = weekStats(state, DateTime(2026, 10, 7), today);
    expect(last.totalMs, 230 * minute);
    expect(last.bestDay, 5);
  });

  test('time of day uses completed focus sessions that finished this week', () {
    final state = withDays(
      {},
      history: [
        done(DateTime(2026, 10, 15, 21, 0), 50), // night
        done(DateTime(2026, 10, 14, 20, 30), 25), // night
        done(DateTime(2026, 10, 13, 18, 0), 25), // evening
        done(DateTime(2026, 10, 12, 6, 0), 25), // morning
        done(DateTime(2026, 10, 12, 9, 0), 1, mode: SessionMode.demo),
        done(DateTime(2026, 10, 9, 14, 0), 50), // last week
        Session(
          id: 'stopped',
          mode: SessionMode.focus,
          status: SessionStatus.stopped,
          startedAt: DateTime(2026, 10, 13, 10).millisecondsSinceEpoch,
          durationMs: 25 * minute,
          remainingMs: 10 * minute,
          actualMs: 15 * minute,
          finishedAt: DateTime(2026, 10, 13, 10, 15).millisecondsSinceEpoch,
        ),
      ],
    );
    final week = weekStats(state, today, today);
    expect(week.bandMs, {
      RoomAmbience.night: 75 * minute,
      RoomAmbience.evening: 25 * minute,
      RoomAmbience.morning: 25 * minute,
    });
    expect(week.topBand, RoomAmbience.night);
    expect(weekStats(withDays({}), today, today).topBand, isNull);
    expect(weekStats(withDays({}), today, today).bestDay, isNull);
  });

  test('month totals, streak, best day and six-month history', () {
    final state = withDays({
      for (final d in [1, 2, 3, 4, 5, 6, 8, 9, 12, 13, 15])
        '2026-10-${d.toString().padLeft(2, '0')}': d == 9 ? 125 : 50,
      '2026-09-01': 40, '2026-09-14': 60, '2026-09-20': 300,
      '2026-05-31': 240,
      '2026-04-30': 999, // older than six months
    });
    final month = monthStats(state, today, today);
    expect(month.month, DateTime(2026, 10));
    expect(month.focusedDays, 11);
    expect(month.totalMs, (10 * 50 + 125) * minute);
    expect(month.averageMs, (625 * minute) ~/ 11);
    expect(month.longestStreak, 6);
    expect(month.bestDay, DateTime(2026, 10, 9));
    expect(month.bestDayMs, 125 * minute);
    // September up to the 15th only.
    expect(month.comparedMs, 100 * minute);
    expect(month.recentMonthsMs.map((ms) => ms ~/ minute), [
      240,
      0,
      0,
      0,
      400,
      625,
    ]);
    // A past month compares against the whole month before it.
    expect(
      monthStats(state, DateTime(2026, 11, 3), today).comparedMs,
      625 * minute,
    );
    final empty = monthStats(state, DateTime(2026, 7), today);
    expect(empty.focusedDays, 0);
    expect(empty.averageMs, 0);
    expect(empty.bestDay, isNull);
    expect(empty.longestStreak, 0);
  });
}
