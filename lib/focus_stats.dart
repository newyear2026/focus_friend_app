import 'room_ambience.dart';
import 'session_engine.dart';

/// Read-only summaries of the saved focus totals for the records tabs.
///
/// Day totals come from [FocusState.dailyFocus], which keeps every completed
/// focus session by local finish date. Time-of-day splits need start times,
/// so they come from the bounded recent history instead.

int _dayMs(FocusState state, DateTime day) =>
    state.dailyFocus[calendarKey(day)]?.milliseconds ?? 0;

/// Weeks start on Sunday to match the records calendar grid.
DateTime weekStart(DateTime day) =>
    DateTime(day.year, day.month, day.day - day.weekday % 7);

class WeekStats {
  const WeekStats({
    required this.start,
    required this.dayMs,
    required this.comparedMs,
    required this.bandMs,
  });

  /// The Sunday this week starts on.
  final DateTime start;

  /// Focus time for each day, Sunday first.
  final List<int> dayMs;

  /// The previous week up to the same weekday, so a week in progress is
  /// compared fairly.
  final int comparedMs;

  /// Completed focus time by the room period the session started in.
  final Map<RoomAmbience, int> bandMs;

  int get totalMs => dayMs.fold(0, (sum, ms) => sum + ms);

  /// The busiest day, or null for an empty week. Ties keep the earlier day.
  int? get bestDay {
    int? best;
    for (var i = 0; i < dayMs.length; i++) {
      if (dayMs[i] > 0 && (best == null || dayMs[i] > dayMs[best])) best = i;
    }
    return best;
  }

  RoomAmbience? get topBand {
    RoomAmbience? top;
    for (final band in RoomAmbience.values) {
      final ms = bandMs[band] ?? 0;
      if (ms > 0 && (top == null || ms > bandMs[top]!)) top = band;
    }
    return top;
  }
}

WeekStats weekStats(FocusState state, DateTime anyDay, DateTime today) {
  final start = weekStart(anyDay);
  final days = [
    for (var i = 0; i < 7; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
  final current = weekStart(today) == start;
  final lastIndex = current ? today.weekday % 7 : 6;
  var compared = 0;
  for (var i = 0; i <= lastIndex; i++) {
    compared += _dayMs(
      state,
      DateTime(start.year, start.month, start.day + i - 7),
    );
  }
  final keys = {for (final day in days) calendarKey(day)};
  final bands = <RoomAmbience, int>{};
  for (final session in state.history) {
    if (session.mode != SessionMode.focus ||
        session.status != SessionStatus.completed ||
        session.finishedAt == null) {
      continue;
    }
    final finished = DateTime.fromMillisecondsSinceEpoch(session.finishedAt!);
    if (!keys.contains(calendarKey(finished))) continue;
    final band = RoomAmbience.at(
      DateTime.fromMillisecondsSinceEpoch(session.startedAt),
    );
    bands[band] = (bands[band] ?? 0) + session.actualMs;
  }
  return WeekStats(
    start: start,
    dayMs: [for (final day in days) _dayMs(state, day)],
    comparedMs: compared,
    bandMs: bands,
  );
}

class MonthStats {
  const MonthStats({
    required this.month,
    required this.totalMs,
    required this.focusedDays,
    required this.longestStreak,
    required this.bestDay,
    required this.bestDayMs,
    required this.comparedMs,
    required this.recentMonthsMs,
  });

  /// The first day of the month.
  final DateTime month;
  final int totalMs;
  final int focusedDays;

  /// Longest run of consecutive focus days inside this month.
  final int longestStreak;
  final DateTime? bestDay;
  final int bestDayMs;

  /// The previous month up to the same day of the month.
  final int comparedMs;

  /// Totals for the six months ending with [month], oldest first.
  final List<int> recentMonthsMs;

  int get averageMs => focusedDays == 0 ? 0 : totalMs ~/ focusedDays;
}

int _monthMs(FocusState state, DateTime month, {int lastDay = 31}) {
  final prefix = calendarKey(month).substring(0, 8);
  var total = 0;
  for (final entry in state.dailyFocus.entries) {
    if (entry.key.startsWith(prefix) &&
        int.parse(entry.key.substring(8)) <= lastDay) {
      total += entry.value.milliseconds;
    }
  }
  return total;
}

MonthStats monthStats(FocusState state, DateTime anyDay, DateTime today) {
  final month = DateTime(anyDay.year, anyDay.month);
  final length = DateTime(month.year, month.month + 1, 0).day;
  var total = 0, focused = 0, streak = 0, longest = 0, bestMs = 0;
  DateTime? best;
  for (var d = 1; d <= length; d++) {
    final day = DateTime(month.year, month.month, d);
    final focus = state.dailyFocus[calendarKey(day)];
    if (focus == null || focus.count == 0) {
      streak = 0;
      continue;
    }
    total += focus.milliseconds;
    focused++;
    streak++;
    if (streak > longest) longest = streak;
    if (focus.milliseconds > bestMs) {
      bestMs = focus.milliseconds;
      best = day;
    }
  }
  final current = month.year == today.year && month.month == today.month;
  return MonthStats(
    month: month,
    totalMs: total,
    focusedDays: focused,
    longestStreak: longest,
    bestDay: best,
    bestDayMs: bestMs,
    comparedMs: _monthMs(
      state,
      DateTime(month.year, month.month - 1),
      lastDay: current ? today.day : 31,
    ),
    recentMonthsMs: [
      for (var i = 5; i >= 0; i--)
        _monthMs(state, DateTime(month.year, month.month - i)),
    ],
  );
}
