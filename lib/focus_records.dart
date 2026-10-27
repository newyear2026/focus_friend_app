import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'focus_stats.dart';
import 'localized_names.dart';
import 'room_ambience.dart';
import 'session_engine.dart';
import 'desk_style.dart';
import 'desk_components.dart';

enum _RecordsView { calendar, week, month }

class FocusRecords extends StatefulWidget {
  const FocusRecords({super.key, required this.state, required this.now});
  final FocusState state;
  final DateTime now;
  @override
  State<FocusRecords> createState() => _FocusRecordsState();
}

class _FocusRecordsState extends State<FocusRecords> {
  var view = _RecordsView.calendar;
  late DateTime month = DateTime(widget.now.year, widget.now.month);
  late DateTime selected = DateUtils.dateOnly(widget.now);
  late DateTime week = weekStart(widget.now);
  void moveMonth(int delta) {
    setState(() {
      month = DateTime(month.year, month.month + delta);
      selected =
          month.year == widget.now.year && month.month == widget.now.month
          ? DateUtils.dateOnly(widget.now)
          : month;
    });
  }

  void moveWeek(int delta) => setState(
    () => week = DateTime(week.year, week.month, week.day + 7 * delta),
  );

  void showThisMonth() => setState(() {
    month = DateTime(widget.now.year, widget.now.month);
    selected = DateUtils.dateOnly(widget.now);
  });

  void showThisWeek() => setState(() => week = weekStart(widget.now));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListView(
      key: const PageStorageKey('focus-records'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recordsTitle,
                    style: const TextStyle(
                      fontSize: 31,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.recordsSubtitle,
                    style: const TextStyle(fontSize: 15, color: deskBlue),
                  ),
                ],
              ),
            ),
            const CompanionImage(size: 72),
          ],
        ),
        const SizedBox(height: 12),
        _ViewTabs(
          value: view,
          labels: {
            _RecordsView.calendar: l10n.recordsTabCalendar,
            _RecordsView.week: l10n.recordsTabWeek,
            _RecordsView.month: l10n.recordsTabMonth,
          },
          onChanged: (next) => setState(() => view = next),
        ),
        const SizedBox(height: 12),
        ...switch (view) {
          _RecordsView.calendar => _calendar(l10n, locale),
          _RecordsView.week => _week(l10n, locale),
          _RecordsView.month => _month(l10n, locale),
        },
      ],
    );
  }

  String _duration(AppLocalizations l10n, int ms) {
    final minutes = ms ~/ 60000;
    return minutes >= 60
        ? l10n.hoursMinutes(minutes ~/ 60, minutes % 60)
        : l10n.minutesShort(minutes);
  }

  /// Whole-minute difference against the same stretch of the previous period.
  String? _comparison(
    AppLocalizations l10n,
    int current,
    int compared, {
    required bool week,
  }) {
    if (current == 0 && compared == 0) return null;
    final minutes = current ~/ 60000 - compared ~/ 60000;
    if (minutes == 0) {
      return week ? l10n.statsSameAsLastWeek : l10n.statsSameAsLastMonth;
    }
    final amount = _duration(l10n, minutes.abs() * 60000);
    if (minutes > 0) {
      return week
          ? l10n.statsMoreThanLastWeek(amount)
          : l10n.statsMoreThanLastMonth(amount);
    }
    return week
        ? l10n.statsLessThanLastWeek(amount)
        : l10n.statsLessThanLastMonth(amount);
  }

  Widget _periodHeader({
    required String title,
    required String previousLabel,
    required String nextLabel,
    required Key previousKey,
    required Key nextKey,
    required VoidCallback onPrevious,
    // Null dims the arrow: weeks and months ahead have nothing to show yet.
    required VoidCallback? onNext,
  }) => Row(
    children: [
      IconButton(
        key: previousKey,
        tooltip: previousLabel,
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        key: nextKey,
        tooltip: nextLabel,
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );

  /// One tap back from any past week or month, however far away it is.
  Widget _backToCurrent(String label, Key key, VoidCallback onPressed) =>
      Center(
        child: TextButton.icon(
          key: key,
          onPressed: onPressed,
          icon: const Icon(Icons.undo_rounded, size: 17),
          // Style the Text itself: a button textStyle would drop the app font.
          label: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            backgroundColor: deskInk,
            foregroundColor: deskPaper,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 36),
            shape: const StadiumBorder(),
          ),
        ),
      );

  List<Widget> _total(String total, String? comparison) => [
    Text(
      total,
      style: const TextStyle(
        fontSize: 34,
        height: 1.2,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
    ),
    if (comparison != null) ...[
      const SizedBox(height: 4),
      Text(comparison, style: const TextStyle(fontSize: 15, color: deskBlue)),
    ],
    const SizedBox(height: 18),
  ];

  List<Widget> _week(AppLocalizations l10n, String locale) {
    final today = DateUtils.dateOnly(widget.now);
    final stats = weekStats(widget.state, week, widget.now);
    final end = DateTime(week.year, week.month, week.day + 6);
    final current = weekStart(today) == stats.start;
    final best = stats.bestDay;
    final top = stats.topBand;
    final maxBand = stats.bandMs.values.fold(0, math.max);
    return [
      _periodHeader(
        title:
            '${DateFormat.MMMd(locale).format(week)} – '
            '${DateFormat.MMMd(locale).format(end)}',
        previousLabel: l10n.previousWeek,
        nextLabel: l10n.nextWeek,
        previousKey: const ValueKey('previous-week'),
        nextKey: const ValueKey('next-week'),
        onPrevious: () => moveWeek(-1),
        onNext: stats.start.isBefore(weekStart(today))
            ? () => moveWeek(1)
            : null,
      ),
      if (!current)
        _backToCurrent(
          l10n.backToThisWeek,
          const ValueKey('this-week'),
          showThisWeek,
        ),
      const SizedBox(height: 6),
      ..._total(
        _duration(l10n, stats.totalMs),
        // A week that has not started yet has nothing to compare.
        stats.start.isAfter(today)
            ? null
            : _comparison(l10n, stats.totalMs, stats.comparedMs, week: true),
      ),
      _Bars(
        key: const ValueKey('week-bars'),
        values: stats.dayMs,
        // narrowWeekdays is Sunday-first, like weekStart.
        labels: MaterialLocalizations.of(context).narrowWeekdays,
        valueLabels: [
          for (final ms in stats.dayMs)
            ms == 0 ? '' : l10n.minutesShort(ms ~/ 60000),
        ],
        highlight: best,
        current: current ? today.weekday % 7 : null,
      ),
      const SizedBox(height: 14),
      if (best != null)
        Text(
          l10n.statsBestDay(
            DateFormat.EEEE(
              locale,
            ).format(DateTime(week.year, week.month, week.day + best)),
            _duration(l10n, stats.dayMs[best]),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      if (top == null && stats.totalMs == 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.statsEmptyWeek,
            textAlign: TextAlign.center,
            style: const TextStyle(color: deskMuted, height: 1.6),
          ),
        ),
      if (top != null) ...[
        const SizedBox(height: 14),
        TicketPanel(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsTimeOfDay,
                  style: const TextStyle(fontSize: 13, color: deskMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.statsTopBand(ambienceName(l10n, top)),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                for (final band in RoomAmbience.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(ambienceName(l10n, band))),
                              Text(
                                _duration(l10n, stats.bandMs[band] ?? 0),
                                style: const TextStyle(color: deskMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (stats.bandMs[band] ?? 0) / maxBand,
                              minHeight: 8,
                              color: band == top ? deskAccent : _barColor,
                              backgroundColor: deskPaper,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _month(AppLocalizations l10n, String locale) {
    final stats = monthStats(widget.state, month, widget.now);
    final thisMonth = DateTime(widget.now.year, widget.now.month);
    final hours = NumberFormat('0.#', locale);
    final best = stats.bestDay;
    return [
      _periodHeader(
        title: DateFormat.yMMMM(locale).format(month),
        previousLabel: l10n.previousMonth,
        nextLabel: l10n.nextMonth,
        previousKey: const ValueKey('previous-month'),
        nextKey: const ValueKey('next-month'),
        onPrevious: () => moveMonth(-1),
        onNext: month.isBefore(thisMonth) ? () => moveMonth(1) : null,
      ),
      if (month != thisMonth)
        _backToCurrent(
          l10n.backToThisMonth,
          const ValueKey('this-month'),
          showThisMonth,
        ),
      const SizedBox(height: 6),
      ..._total(
        _duration(l10n, stats.totalMs),
        // A month that has not started yet has nothing to compare.
        stats.month.isAfter(widget.now)
            ? null
            : _comparison(l10n, stats.totalMs, stats.comparedMs, week: false),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in [
            (l10n.focusedDays, l10n.dayCount(stats.focusedDays)),
            (l10n.statsAverage, _duration(l10n, stats.averageMs)),
            (l10n.statsStreak, l10n.dayCount(stats.longestStreak)),
          ]) ...[
            Expanded(
              child: TicketPanel(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: deskMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (label != l10n.statsStreak) const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 20),
      Text(
        l10n.statsRecentMonths,
        style: const TextStyle(fontSize: 13, color: deskMuted),
      ),
      const SizedBox(height: 10),
      _Bars(
        key: const ValueKey('month-bars'),
        values: stats.recentMonthsMs,
        labels: [
          for (var i = 5; i >= 0; i--)
            DateFormat.MMM(
              locale,
            ).format(DateTime(month.year, month.month - i)),
        ],
        valueLabels: [
          for (final ms in stats.recentMonthsMs)
            ms == 0 ? '' : l10n.hoursShort(hours.format(ms / 3600000)),
        ],
        highlight: 5,
        current: 5,
      ),
      const SizedBox(height: 14),
      if (best != null)
        Text(
          l10n.statsBestDay(
            DateFormat.MMMd(locale).format(best),
            _duration(l10n, stats.bestDayMs),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.statsEmptyMonth,
            textAlign: TextAlign.center,
            style: const TextStyle(color: deskMuted, height: 1.6),
          ),
        ),
    ];
  }

  List<Widget> _calendar(AppLocalizations l10n, String locale) {
    final prefix = calendarKey(month).substring(0, 7);
    final totals = widget.state.dailyFocus.entries.where(
      (entry) => entry.key.startsWith(prefix),
    );
    final minutes =
        totals.fold<int>(0, (sum, entry) => sum + entry.value.milliseconds) ~/
        60000;
    final focusedDays = totals.where((entry) => entry.value.count > 0).length;
    final day =
        widget.state.dailyFocus[calendarKey(selected)] ?? const DailyFocus();
    final sessions = widget.state.history
        .where(
          (s) =>
              s.finishedAt != null &&
              calendarKey(DateTime.fromMillisecondsSinceEpoch(s.finishedAt!)) ==
                  calendarKey(selected),
        )
        .toList();
    final firstOffset = month.weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = ((firstOffset + days) / 7).ceil() * 7;
    final today = DateUtils.dateOnly(widget.now);
    return [
      Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _summary(
            Icons.date_range_rounded,
            l10n.thisWeek,
            _duration(l10n, weekStats(widget.state, today, today).totalMs),
          ),
          _summary(
            Icons.schedule_rounded,
            l10n.thisMonth,
            _duration(l10n, minutes * 60000),
          ),
          _summary(
            Icons.calendar_today_rounded,
            l10n.focusedDays,
            l10n.dayCount(focusedDays),
          ),
        ],
      ),
      const Divider(height: 20),
      _periodHeader(
        title: DateFormat.yMMMM(locale).format(month),
        previousLabel: l10n.previousMonth,
        nextLabel: l10n.nextMonth,
        previousKey: const ValueKey('previous-month'),
        nextKey: const ValueKey('next-month'),
        onPrevious: () => moveMonth(-1),
        onNext: () => moveMonth(1),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          // The grid starts on Sunday; narrowWeekdays is Sunday-first too.
          for (final label in MaterialLocalizations.of(context).narrowWeekdays)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(color: deskMuted, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 7),
      LayoutBuilder(
        builder: (context, constraints) {
          // A 52pt cell fits the day number up to about 1.2x text; past
          // that the number's line height pushes the stamp out.
          // Japanese glyphs fall back to a taller font, so grow with the text.
          final scaled = MediaQuery.textScalerOf(context).scale(13);
          final height = scaled > 16 ? math.max(70.0, 44 + scaled * 2) : 52.0;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: height,
            ),
            itemBuilder: (context, index) {
              final number = index - firstOffset + 1;
              if (number < 1 || number > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, number);
              final chosen = DateUtils.isSameDay(date, selected);
              final current = DateUtils.isSameDay(date, today);
              final completed =
                  (widget.state.dailyFocus[calendarKey(date)]?.count ?? 0) > 0;
              return Semantics(
                label: [
                  DateFormat.MMMd(locale).format(date),
                  if (completed) l10n.dayFocusDone,
                  if (current) l10n.today,
                ].join(', '),
                selected: chosen,
                button: true,
                child: InkWell(
                  key: ValueKey('day-${calendarKey(date)}'),
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => setState(() => selected = date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: chosen
                          ? Border.all(color: deskInk, width: 1.4)
                          : null,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: current
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: date.isAfter(today)
                                ? const Color(0xFFB9BCCB)
                                : deskInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        completed
                            ? Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ticketGold,
                                ),
                                child: const CompanionImage(size: 28),
                              )
                            : CustomPaint(
                                size: const Size.square(28),
                                painter: _DayRingPainter(
                                  upcoming: date.isAfter(today),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      const Divider(height: 18),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          Text(
            DateFormat.MMMMEEEEd(locale).format(selected),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          if (DateUtils.isSameDay(selected, today)) ...[
            Text(
              l10n.today,
              style: const TextStyle(color: deskBlue, fontSize: 15),
            ),
          ],
        ],
      ),
      const SizedBox(height: 10),
      TicketPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                l10n.dayFocusMinutes(day.milliseconds ~/ 60000),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.daySessions(day.count),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      if (sessions.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Text(
            day.count > 0
                ? l10n.recordsArchived
                : selected.isAfter(today)
                ? l10n.recordsFuture
                : l10n.recordsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: deskMuted, height: 1.6),
          ),
        ),
      for (final session in sessions) ...[
        ListTile(
          minTileHeight: 48,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            session.status == SessionStatus.completed
                ? Icons.check_circle_rounded
                : Icons.stop_circle_outlined,
            color: session.status == SessionStatus.completed
                ? deskGreen
                : const Color(0xFFA9ADC0),
          ),
          title: Text(
            session.status == SessionStatus.completed
                ? l10n.sessionCompleted(session.actualMs ~/ 60000)
                : session.actualMs < 60000
                ? l10n.sessionStoppedShort
                : l10n.sessionStopped(session.actualMs ~/ 60000),
            style: session.status == SessionStatus.completed
                ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
                : const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: deskMuted,
                  ),
          ),
          trailing: Text(
            DateFormat.jm(
              locale,
            ).format(DateTime.fromMillisecondsSinceEpoch(session.startedAt)),
            style: const TextStyle(color: deskMuted),
          ),
        ),
        const Divider(height: 1),
      ],
    ];
  }

  // One wrapping run of text so large type moves to the next line instead of
  // overflowing.
  Widget _summary(IconData icon, String label, String value) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(icon, size: 20, color: deskInk),
          ),
        ),
        TextSpan(text: '$label ', style: const TextStyle(fontSize: 13)),
        TextSpan(
          text: value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

const _barColor = Color(0xFF8D8498);

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final _RecordsView value;
  final Map<_RecordsView, String> labels;
  final ValueChanged<_RecordsView> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: deskCream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final entry in labels.entries)
          Expanded(
            child: Semantics(
              selected: entry.key == value,
              button: true,
              child: Material(
                color: entry.key == value ? deskInk : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  key: ValueKey('records-tab-${entry.key.name}'),
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(entry.key),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Center(
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: entry.key == value
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: entry.key == value ? deskPaper : deskMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Vertical bars with a value above and a label below each one.
class _Bars extends StatelessWidget {
  const _Bars({
    super.key,
    required this.values,
    required this.labels,
    required this.valueLabels,
    this.highlight,
    this.current,
  });
  final List<int> values;
  final List<String> labels, valueLabels;
  final int? highlight, current;

  @override
  Widget build(BuildContext context) {
    final top = values.fold(0, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Semantics(
              container: true,
              label: '${labels[i]} ${valueLabels[i]}',
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueLabels[i],
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11, color: deskMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: top == 0 ? 4 : math.max(4, 110 * values[i] / top),
                    decoration: BoxDecoration(
                      color: values[i] == 0
                          ? deskDivider
                          : i == highlight
                          ? deskAccent
                          : _barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == current
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i == current ? deskInk : deskMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty day marker: a solid ring for past days, a faint dashed ring for days
/// that have not come yet.
class _DayRingPainter extends CustomPainter {
  const _DayRingPainter({required this.upcoming});
  final bool upcoming;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = upcoming ? const Color(0xFFE2DFD6) : const Color(0xFFD5D2C8);
    final rect = (Offset.zero & size).deflate(1);
    if (!upcoming) {
      canvas.drawOval(rect, paint);
      return;
    }
    const dashes = 16;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * .55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DayRingPainter oldDelegate) =>
      oldDelegate.upcoming != upcoming;
}
