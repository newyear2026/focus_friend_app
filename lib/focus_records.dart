import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'session_engine.dart';
import 'desk_style.dart';
import 'desk_components.dart';

class FocusRecords extends StatefulWidget {
  const FocusRecords({super.key, required this.state, required this.now});
  final FocusState state;
  final DateTime now;
  @override
  State<FocusRecords> createState() => _FocusRecordsState();
}

class _FocusRecordsState extends State<FocusRecords> {
  late DateTime month = DateTime(widget.now.year, widget.now.month);
  late DateTime selected = DateUtils.dateOnly(widget.now);
  void moveMonth(int delta) {
    setState(() {
      month = DateTime(month.year, month.month + delta);
      selected =
          month.year == widget.now.year && month.month == widget.now.month
          ? DateUtils.dateOnly(widget.now)
          : month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
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
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _summary(
              Icons.schedule_rounded,
              l10n.thisMonth,
              minutes >= 60
                  ? l10n.hoursMinutes(minutes ~/ 60, minutes % 60)
                  : l10n.minutesShort(minutes),
            ),
            _summary(
              Icons.calendar_today_rounded,
              l10n.focusedDays,
              l10n.dayCount(focusedDays),
            ),
          ],
        ),
        const Divider(height: 20),
        Row(
          children: [
            IconButton(
              key: const ValueKey('previous-month'),
              tooltip: l10n.previousMonth,
              onPressed: () => moveMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('next-month'),
              tooltip: l10n.nextMonth,
              onPressed: () => moveMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // The grid starts on Sunday; narrowWeekdays is Sunday-first too.
            for (final label in MaterialLocalizations.of(
              context,
            ).narrowWeekdays)
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
            final height = MediaQuery.textScalerOf(context).scale(13) > 16
                ? 70.0
                : 52.0;
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
                    (widget.state.dailyFocus[calendarKey(date)]?.count ?? 0) >
                    0;
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
      ],
    );
  }

  Widget _summary(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: deskInk),
      const SizedBox(width: 6),
      Text('$label ', style: const TextStyle(fontSize: 13)),
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ],
  );
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
