import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'session_engine.dart';
export 'study_scene.dart' show DeskIllustration;
export 'desk_style.dart';
import 'desk_style.dart';
import 'desk_components.dart';
import 'l10n/app_localizations.dart';
import 'localized_names.dart';

// Keep the small desk label legible over the warmly lit notebook pages.
const _deskLabelShadows = [
  Shadow(color: Color(0xE6171B32), blurRadius: 3, offset: Offset(0, 1)),
  Shadow(color: Color(0x99171B32), blurRadius: 8),
];

int todayFocusMinutes(FocusState state, DateTime now) =>
    (state.dailyFocus[calendarKey(now)]?.milliseconds ?? 0) ~/ 60000;

/// The room is a persistent scene behind this live, accessible UI.
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
    this.systemBottomInset = 0,
  });
  final FocusState state;
  final DateTime now;
  final int minutes;
  final bool enabled, foreground;
  final ValueChanged<int> onSelectMinutes;
  final VoidCallback onRandomMinutes, onStart, onPauseResume, onStop;
  final VoidCallback onDismiss, onRest, onNext;
  final VoidCallback? onSound, onGoal;
  final double systemBottomInset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = state.active;
    final completed = active?.status == SessionStatus.completed;
    final paused = active?.status == SessionStatus.paused;
    final rest = active?.mode == SessionMode.rest;
    final demo = active?.mode == SessionMode.demo;
    final seconds = active == null
        ? minutes * 60
        : ((active.remaining(now.millisecondsSinceEpoch) + 999) ~/ 1000);
    final caption = active == null
        ? l10n.captionReady
        : completed
        ? (demo
              ? l10n.captionDemoDone
              : rest
              ? l10n.captionRestDone
              : l10n.captionFocusDone)
        : paused
        ? l10n.captionPaused
        : demo
        ? l10n.captionDemo
        : rest
        ? l10n.captionRest
        : l10n.captionFocusing(active.durationMs ~/ 60000);
    final value = completed
        ? l10n.minutesShort(active!.durationMs ~/ 60000)
        : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final message = active == null
        ? null
        : completed
        ? (active.rewards.contains('plant')
              ? l10n.messageFirstPlant
              : active.rewards.isNotEmpty
              ? l10n.messageNewProps(
                  active.rewards.map((key) => propName(l10n, key)).join(' · '),
                )
              : demo
              ? l10n.messageDemoDone
              : rest
              ? l10n.messageRestDone
              : l10n.messageFocusDone)
        : paused
        ? l10n.messagePaused
        : rest
        ? l10n.messageRest
        : l10n.messageFocus;
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: 'Pretendard', color: deskInk),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final height = math.max(
            constraints.maxHeight,
            700 + math.max(0.0, scale - 1) * 300,
          );
          final bottomReserve =
              DeskNavigation.contentHeight + systemBottomInset + 24;
          return SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('random-focus'),
                          tooltip: l10n.randomTooltip,
                          onPressed: enabled && active == null
                              ? onRandomMinutes
                              : null,
                          icon: const Icon(Icons.shuffle_rounded, size: 20),
                          color: deskInk.withValues(alpha: .75),
                          disabledColor: Colors.transparent,
                        ),
                        Expanded(
                          child: Text(
                            l10n.deskTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('open-sound'),
                          tooltip: l10n.focusSound,
                          onPressed: enabled ? onSound : null,
                          color: deskInk,
                          icon: Icon(
                            state.sound.enabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 27,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * .04),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Color(0x990C1227), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 92 * math.min(scale, 1.2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          key: ValueKey(
                            active == null ? 'ready-timer' : 'timer',
                          ),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            height: 1.06,
                            letterSpacing: -2,
                            fontFeatures: [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(color: Color(0x550C1227), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (message != null)
                      Container(
                        margin: const EdgeInsets.only(top: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB3292630),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: deskInk,
                          ),
                        ),
                      ),
                    if (state.goal case final goal? when goal.showOnHome)
                      Center(
                        child: TextButton.icon(
                          key: const ValueKey('home-goal'),
                          onPressed: enabled ? onGoal : null,
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: Text(
                            '${goal.countdown(now)} · ${goal.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(foregroundColor: deskInk),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: scale > 1.2
                          ? const EdgeInsets.all(12)
                          : EdgeInsets.zero,
                      decoration: scale > 1.2
                          ? BoxDecoration(
                              color: const Color(0xED292630),
                              borderRadius: BorderRadius.circular(18),
                            )
                          : null,
                      child: Column(
                        children: [
                          if (active == null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${l10n.todayFocus} ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    shadows: _deskLabelShadows,
                                  ),
                                ),
                                Text(
                                  l10n.minutesShort(
                                    todayFocusMinutes(state, now),
                                  ),
                                  key: const ValueKey('today-focus'),
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    shadows: _deskLabelShadows,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: scale > 1.2 ? 0 : 16,
                              ),
                              child: Row(
                                children: [
                                  for (final value in [25, 50]) ...[
                                    if (value == 50) const SizedBox(width: 12),
                                    Expanded(
                                      child: _DurationChoice(
                                        minutes: value,
                                        selected: minutes == value,
                                        onPressed: enabled
                                            ? () => onSelectMinutes(value)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 13),
                            _primary(
                              l10n.startFocus,
                              Icons.play_arrow_rounded,
                              onStart,
                              key: const ValueKey('start-focus'),
                            ),
                          ] else if (completed) ...[
                            _primary(
                              l10n.confirm,
                              Icons.check_rounded,
                              onDismiss,
                            ),
                            const SizedBox(height: 8),
                            if (!demo && !rest)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: enabled ? onRest : null,
                                      style: _secondaryStyle,
                                      child: Text(l10n.startRest),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: enabled ? onNext : null,
                                      style: _secondaryStyle,
                                      child: Text(l10n.nextFocus),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(height: 48),
                          ] else ...[
                            _primary(
                              paused
                                  ? (rest ? l10n.resumeRest : l10n.resumeFocus)
                                  : l10n.pause,
                              paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              onPauseResume,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: enabled ? onStop : null,
                              style: _secondaryStyle,
                              child: Text(l10n.endThisSession),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: bottomReserve),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ButtonStyle get _secondaryStyle => TextButton.styleFrom(
    foregroundColor: deskInk,
    minimumSize: const Size(48, 48),
    textStyle: const TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 16,
      fontWeight: FontWeight.w600,
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
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 42),
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: selected ? deskAccent : const Color(0x77413944),
        foregroundColor: selected ? deskInkShadow : deskInk,
        side: BorderSide(
          color: selected ? deskAccent : const Color(0xFFC1ADB5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      // Longer translations ("25 min") shrink instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).minutesShort(minutes),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_rounded, size: 20),
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
    this.immersive = false,
  });
  static const contentHeight = 108.0;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool immersive;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Daylight can brighten the floor behind every tab. Keep the controls
    // readable as the authored room light changes through the day.
    final muted = immersive ? deskInk.withValues(alpha: .9) : deskMuted;
    return Material(
      color: immersive ? deskInkShadow.withValues(alpha: .5) : deskPaper,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: contentHeight,
          child: Row(
            children: [
              for (final (index, label, asset) in [
                (0, l10n.navDesk, 'nav-desk'),
                (1, l10n.navFriends, 'friends'),
                (2, l10n.navRecords, 'nav-records'),
                (3, l10n.navSettings, 'nav-settings'),
              ])
                Expanded(
                  child: Semantics(
                    selected: selectedIndex == index,
                    button: true,
                    child: InkWell(
                      key: ValueKey('desk-navigation-$index'),
                      onTap: () => onSelected(index),
                      child: SizedBox(
                        height: contentHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: index == 1
                                    ? Icon(
                                        Icons.pets_outlined,
                                        size: 34,
                                        color: selectedIndex == index
                                            ? deskAccent
                                            : muted,
                                      )
                                    : Image.asset(
                                        'assets/images/immersive/$asset.png',
                                        width: index == 3 ? 40 : 48,
                                        height: index == 3 ? 40 : 48,
                                        fit: BoxFit.contain,
                                        color: selectedIndex == index
                                            ? deskAccent
                                            : muted,
                                        colorBlendMode: BlendMode.srcIn,
                                        filterQuality: FilterQuality.medium,
                                        excludeFromSemantics: true,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: selectedIndex == index
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selectedIndex == index
                                      ? deskAccent
                                      : muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                color: selectedIndex == index
                                    ? deskAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
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
}
