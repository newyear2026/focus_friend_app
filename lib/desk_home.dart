import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'session_engine.dart';
import 'room_ambience.dart';
import 'study_scene.dart';
export 'study_scene.dart' show DeskIllustration;

export 'desk_style.dart';
import 'desk_style.dart';
import 'desk_components.dart';

int todayFocusMinutes(FocusState state, DateTime now) =>
    (state.dailyFocus[calendarKey(now)]?.milliseconds ?? 0) ~/ 60000;

class DeskHome extends StatelessWidget {
  const DeskHome({
    super.key,
    required this.state,
    required this.now,
    required this.minutes,
    required this.enabled,
    required this.onSelectMinutes,
    required this.onRandomMinutes,
    required this.onStart,
    required this.onPauseResume,
    required this.onStop,
    required this.onDismiss,
    required this.onRest,
    required this.onNext,
    this.foreground = true,
    this.onSound,
    this.onGoal,
  });

  final FocusState state;
  final DateTime now;
  final int minutes;
  final bool enabled, foreground;
  final ValueChanged<int> onSelectMinutes;
  final VoidCallback onRandomMinutes, onStart, onPauseResume, onStop;
  final VoidCallback onDismiss, onRest, onNext;
  final VoidCallback? onSound, onGoal;

  @override
  Widget build(BuildContext context) {
    final active = state.active;
    final completed = active?.status == SessionStatus.completed;
    final paused = active?.status == SessionStatus.paused;
    final rest = active?.mode == SessionMode.rest;
    final demo = active?.mode == SessionMode.demo;
    final studying = active != null && !rest && !completed;
    final ambience = RoomAmbience.at(now);
    final seconds =
        ((active?.remaining(now.millisecondsSinceEpoch) ?? 0) + 999) ~/ 1000;
    final subtitle = active == null
        ? '오늘도 같이 시작해요'
        : completed
        ? (active.rewards.contains('plant')
              ? '첫 집중의 선물, 작은 화분을 놓았어요.'
              : active.rewards.isNotEmpty
              ? '새 소품: ${active.rewards.map((key) => key == 'mug' ? '따뜻한 머그컵' : '포근한 조명').join(' · ')}'
              : demo
              ? '체험을 마쳤어요. 함께해 줘서 고마워요'
              : rest
              ? '잘 쉬었어요. 다시 천천히 시작해요'
              : '잘했어요. 책상에 집중이 쌓였어요')
        : paused
        ? '잠시 쉬어가도 괜찮아요'
        : rest
        ? '같은 자리에서 잠깐 쉬어가요'
        : '차근차근, 함께 써 내려가요';
    final caption = active == null
        ? '오늘의 집중'
        : completed
        ? (demo
              ? '체험 완료'
              : rest
              ? '휴식 완료'
              : '집중 완료')
        : paused
        ? '일시정지'
        : demo
        ? '1분 체험 · 기록 없이'
        : rest
        ? '쉬어가는 시간'
        : '${active.durationMs ~/ 60000}분 집중 중';
    final value = active == null
        ? '${todayFocusMinutes(state, now)}분'
        : completed
        ? '${active.durationMs ~/ 60000}분'
        : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Theme(
      data: deskTheme(context),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Pretendard', color: deskInk),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final minHeight = 570.0 + math.max(0.0, textScale - 1) * 360;
            final height = math.max(constraints.maxHeight, minHeight);
            return SingleChildScrollView(
              child: SizedBox(
                height: height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '나의 책상',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                    letterSpacing: -1.4,
                                  ),
                                ),
                              ),
                              if (onSound != null)
                                IconButton(
                                  key: const ValueKey('open-sound'),
                                  tooltip: '집중 사운드',
                                  onPressed: enabled ? onSound : null,
                                  icon: Icon(
                                    state.sound.enabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: deskBlue,
                                    size: 23,
                                  ),
                                ),
                              Semantics(
                                label: '현재 시간대 ${ambience.label}',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ambience == RoomAmbience.night
                                          ? Icons.nightlight_round
                                          : ambience == RoomAmbience.evening
                                          ? Icons.wb_twilight_rounded
                                          : Icons.wb_sunny_outlined,
                                      size: 17,
                                      color: deskBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ambience.label,
                                      key: const ValueKey('room-period'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: deskBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: completed ? 16 : 20,
                              fontWeight: FontWeight.w500,
                              color: deskBlue,
                              height: 1.2,
                              letterSpacing: -.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.goal case final goal? when goal.showOnHome)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: InkWell(
                          key: const ValueKey('home-goal'),
                          onTap: enabled ? onGoal : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text(
                                  goal.countdown(now),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: deskBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: deskMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DeskIllustration(
                          unlocked: state.unlocks.keys.toSet(),
                          ambience: ambience,
                          studying: studying,
                          animate: studying && !paused && foreground,
                          paused: paused,
                        ),
                      ),
                    ),
                    Semantics(
                      label: '$caption $value',
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 52 * textScale,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                '$caption · ',
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: active == null ? 18 : 15,
                                  color: deskBlue,
                                ),
                              ),
                            ),
                            Text(
                              value,
                              key: ValueKey(
                                active == null ? 'today-focus' : 'timer',
                              ),
                              style: TextStyle(
                                fontSize: active == null ? 28 : 38,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 7),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 156),
                        child: active == null
                            ? _idleControls()
                            : completed
                            ? _completeControls(demo: demo, rest: rest)
                            : _activeControls(paused: paused, rest: rest),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _idleControls() => Column(
    children: [
      Row(
        children: [
          for (final value in [25, 50]) ...[
            if (value == 50) const SizedBox(width: 12),
            Expanded(
              child: _DurationChoice(
                minutes: value,
                selected: minutes == value,
                onPressed: enabled ? () => onSelectMinutes(value) : null,
              ),
            ),
          ],
        ],
      ),
      TextButton.icon(
        onPressed: enabled ? onRandomMinutes : null,
        style: _secondaryStyle,
        icon: const Icon(Icons.shuffle_rounded, size: 23),
        label: const Text('랫서팬더가 골라주기'),
      ),
      _primary(
        '집중 시작',
        Icons.play_arrow_rounded,
        onStart,
        key: const ValueKey('start-focus'),
      ),
    ],
  );

  Widget _activeControls({required bool paused, required bool rest}) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        height: 46,
        child: Center(
          child: Text(
            paused
                ? '준비되면 여기서 이어가요'
                : rest
                ? '숨을 고르고, 어깨도 편하게'
                : '천천히, 한 줄씩 써봐요',
            style: const TextStyle(fontSize: 18, color: deskBlue),
          ),
        ),
      ),
      _primary(
        paused ? (rest ? '이어서 쉬기' : '이어서 집중') : '잠시 멈추기',
        paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        onPauseResume,
      ),
      TextButton(
        onPressed: enabled ? onStop : null,
        style: _secondaryStyle,
        child: const Text('이번 시간 종료'),
      ),
    ],
  );

  Widget _completeControls({required bool demo, required bool rest}) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      const SizedBox(
        height: 46,
        child: Icon(
          Icons.check_circle_outline_rounded,
          color: deskGreen,
          size: 30,
        ),
      ),
      _primary('확인', Icons.check_rounded, onDismiss),
      if (!demo && !rest)
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: enabled ? onRest : null,
                style: _secondaryStyle,
                child: const Text('5분 휴식 시작'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: enabled ? onNext : null,
                style: _secondaryStyle,
                child: const Text('다음 집중 시작'),
              ),
            ),
          ],
        )
      else
        const SizedBox(height: 48),
    ],
  );

  ButtonStyle get _secondaryStyle => TextButton.styleFrom(
    foregroundColor: deskBlue,
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    textStyle: const TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _primary(
    String label,
    IconData icon,
    VoidCallback action, {
    Key? key,
  }) => DeskPrimaryButton(
    key: key,
    label: label,
    icon: icon,
    onPressed: enabled ? action : null,
  );
}

class _DurationChoice extends StatelessWidget {
  const _DurationChoice({
    required this.minutes,
    required this.selected,
    this.onPressed,
  });
  final int minutes;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: TicketPanel(
      color: selected ? ticketGold : deskPaper,
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes분',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            if (selected) ...[
              const SizedBox(width: 9),
              const Icon(Icons.check_rounded, size: 19),
            ],
          ],
        ),
      ),
    ),
  );
}

class DeskNavigation extends StatelessWidget {
  const DeskNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: deskPaper,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFECECE6))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final (index, label, icon) in [
              (0, '책상', Icons.home_rounded),
              (1, '기록', Icons.bar_chart_rounded),
              (2, '설정', Icons.settings_rounded),
            ])
              Expanded(
                child: Semantics(
                  selected: selectedIndex == index,
                  button: true,
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 29,
                            color: selectedIndex == index
                                ? const Color(0xFF168053)
                                : deskMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: selectedIndex == index
                                  ? const Color(0xFF168053)
                                  : deskBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
