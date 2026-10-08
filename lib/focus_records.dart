import 'package:flutter/material.dart';
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '차곡차곡 기록',
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '함께 집중한 날을 모았어요',
                    style: TextStyle(fontSize: 15, color: deskBlue),
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
              '이번 달',
              minutes >= 60
                  ? '${minutes ~/ 60}시간 ${minutes % 60}분'
                  : '$minutes분',
            ),
            _summary(Icons.calendar_today_rounded, '집중한 날', '$focusedDays일'),
          ],
        ),
        const Divider(height: 20),
        Row(
          children: [
            IconButton(
              key: const ValueKey('previous-month'),
              tooltip: '이전 달',
              onPressed: () => moveMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${month.year}년 ${month.month}월',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('next-month'),
              tooltip: '다음 달',
              onPressed: () => moveMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final label in ['일', '월', '화', '수', '목', '금', '토'])
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
            final height = MediaQuery.textScalerOf(context).scale(13) > 18
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
                  label:
                      '${month.month}월 $number일${completed ? ', 집중 완료' : ''}${current ? ', 오늘' : ''}',
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
                              color: date.isAfter(today) ? deskMuted : deskInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completed ? ticketGold : null,
                              border: completed
                                  ? null
                                  : Border.all(color: const Color(0xFFE6E6ED)),
                            ),
                            child: completed
                                ? const CompanionImage(size: 28)
                                : null,
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
              '${selected.month}월 ${selected.day}일 ${['월', '화', '수', '목', '금', '토', '일'][selected.weekday - 1]}요일',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            if (DateUtils.isSameDay(selected, today)) ...[
              const Text('오늘', style: TextStyle(color: deskBlue, fontSize: 15)),
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
                  '${day.milliseconds ~/ 60000}분 집중',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${day.count}회 완료',
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
                  ? '이날의 합계와 스탬프를 보관하고 있어요.\n상세 내역은 최근 100회까지 볼 수 있어요.'
                  : selected.isAfter(today)
                  ? '앞으로 함께 채워갈 하루예요.'
                  : '아직 기록이 없어요.\n25분부터 함께 시작해 볼까요?',
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
                  : Icons.pause_circle_outline,
              color: session.status == SessionStatus.completed
                  ? deskGreen
                  : deskMuted,
            ),
            title: Text(
              '${session.actualMs ~/ 60000}분 ${session.status == SessionStatus.completed ? '집중 완료' : '중도 종료'}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            trailing: Text(
              _time(session.startedAt),
              style: const TextStyle(color: deskMuted),
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }

  String _time(int value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value);
    return '${date.hour < 12 ? '오전' : '오후'} ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _summary(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: deskGreen),
      const SizedBox(width: 6),
      Text('$label ', style: const TextStyle(fontSize: 13)),
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ],
  );
}
