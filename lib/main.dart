import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'android_bridge.dart';
import 'session_engine.dart';
import 'room_ambience.dart';
import 'desk_home.dart';
import 'focus_records.dart';
import 'goal_editor.dart';
import 'sound_sheet.dart';

const ink = Color(0xFF50473D);
const sage = Color(0xFF78856B);
const paper = Color(0xFFF7F3EA);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FocusFriendApp(
      engine: SessionEngine(AndroidStore()),
      alerts: LocalAlerts(),
      sounds: FocusSoundPlayer(),
    ),
  );
}

class FocusFriendApp extends StatelessWidget {
  const FocusFriendApp({
    super.key,
    required this.engine,
    this.alerts,
    this.sounds,
  });
  final SessionEngine engine;
  final LocalAlerts? alerts;
  final FocusSoundPlayer? sounds;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '작은 집중방',
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: sage, surface: paper),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -1.1,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: ink,
          letterSpacing: -.6,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sage,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE3DDCF)),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: paper,
        indicatorColor: Color(0xFFE5E8DC),
        height: 68,
      ),
    ),
    home: RoomScreen(engine: engine, alerts: alerts, sounds: sounds),
  );
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.engine, this.alerts, this.sounds});
  final SessionEngine engine;
  final LocalAlerts? alerts;
  final FocusSoundPlayer? sounds;
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  bool ready = false, busy = false, notifications = false;
  bool foreground = true;
  String? error;
  String? alertError;
  String? soundError;
  int page = 0, minutes = 25;
  Timer? ticker;
  int? displayedMinute;
  SessionEngine get engine => widget.engine;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restore());
    ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!ready || busy || !mounted || !foreground || error != null) return;
      final a = engine.state.active;
      final minute = engine.clock() ~/ 60000;
      final changedMinute = displayedMinute != minute;
      displayedMinute = minute;
      if (a?.status == SessionStatus.running &&
          a!.remaining(engine.clock()) == 0) {
        unawaited(_act(() => engine.complete(a.id)));
      } else if (a?.status == SessionStatus.running || changedMinute) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => foreground = state == AppLifecycleState.resumed);
    if (foreground) unawaited(_restore());
  }

  Future<void> _restore() async {
    if (busy) return;
    await _act(() => engine.restore());
    if (mounted && error == null) {
      setState(() {
        ready = true;
      });
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final previous = engine.state.active;
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          error = '저장 상태를 확인할 수 없어요. 다시 확인하면 안전하게 이어집니다.';
        });
      }
    }
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
    if (error == null) {
      await _alerts();
      if (previous?.live == true && engine.state.active == null) {
        await _stopSound();
      } else {
        await _syncSound(
          activate:
              previous?.status != SessionStatus.running &&
              engine.state.active?.status == SessionStatus.running,
        );
      }
    }
  }

  Future<void> _alerts() async {
    if (widget.alerts == null) return;
    try {
      await widget.alerts!.sync();
      final enabled = await widget.alerts!.enabled();
      if (mounted) {
        setState(() {
          notifications = enabled;
          alertError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          alertError = '알림을 예약하지 못했어요. 앱에 돌아오면 타이머는 복구됩니다.';
        });
      }
    }
  }

  Future<void> _stop(Session a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이번 집중을 마칠까요?'),
        content: Text(
          a.mode == SessionMode.focus
              ? '지금까지의 시간은 중도 종료 기록으로 남아요. 소품 해금 시간에는 더하지 않아요.'
              : '체험과 휴식은 집중 기록에 남지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료하기'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _act(() => engine.stop(a.id));
  }

  Future<void> _start(SessionMode mode, [int? selectedMinutes]) => _act(
    () =>
        engine.start(Duration(minutes: selectedMinutes ?? minutes), mode: mode),
  );
  @override
  Widget build(BuildContext context) {
    final state = engine.state;
    final active = state.active;
    return Theme(
      data: deskTheme(context),
      child: Scaffold(
        backgroundColor: deskPaper,
        body: SafeArea(
          child: Column(
            children: [
              if (error != null)
                MaterialBanner(
                  content: Text(error!),
                  actions: [
                    TextButton(
                      onPressed: busy ? null : _restore,
                      child: const Text('다시 확인'),
                    ),
                  ],
                ),
              if (alertError != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    alertError!,
                    style: const TextStyle(color: Colors.brown),
                  ),
                ),
              Expanded(
                child: !ready
                    ? Center(
                        child: error == null
                            ? const CircularProgressIndicator()
                            : const Text('저장된 방을 확인하고 있어요.'),
                      )
                    : active != null || page == 0
                    ? _home(state)
                    : page == 1
                    ? FocusRecords(
                        state: state,
                        now: DateTime.fromMillisecondsSinceEpoch(
                          engine.clock(),
                        ),
                      )
                    : _settings(state),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Visibility(
          visible: active == null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: DeskNavigation(
            selectedIndex: page,
            onSelected: (index) => setState(() => page = index),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 2,
      color: Color(0xFF8A8C78),
      fontWeight: FontWeight.w700,
    ),
  );
  Widget _heading(String eyebrow, String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(eyebrow),
        const SizedBox(height: 9),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8F8779),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
  Widget _home(FocusState s) => DeskHome(
    state: s,
    now: DateTime.fromMillisecondsSinceEpoch(engine.clock()),
    minutes: minutes,
    enabled: !busy && error == null,
    onSelectMinutes: (value) => setState(() => minutes = value),
    onRandomMinutes: () {
      final chosen = math.Random().nextBool() ? 25 : 50;
      setState(() => minutes = chosen);
    },
    onStart: () => _start(SessionMode.focus),
    foreground: foreground,
    onSound: _showSound,
    onGoal: _showGoal,
    onPauseResume: () {
      final a = engine.state.active!;
      _act(
        () => a.status == SessionStatus.paused
            ? engine.resume(a.id)
            : engine.pause(a.id),
      );
    },
    onStop: () => _stop(engine.state.active!),
    onDismiss: () => _act(() async {
      await engine.dismiss(engine.state.active!.id);
      page = 0;
    }),
    onRest: () => _nextSession(SessionMode.rest),
    onNext: () => _nextSession(SessionMode.focus),
  );

  Future<void> _nextSession(SessionMode mode) => _act(() async {
    await engine.dismiss(engine.state.active!.id);
    await engine.start(
      Duration(minutes: mode == SessionMode.rest ? 5 : minutes),
      mode: mode,
    );
  });

  Future<void> _syncSound({bool activate = false}) async {
    if (widget.sounds == null) return;
    try {
      await widget.sounds!.sync(engine.state, activate: activate);
      if (mounted) setState(() => soundError = null);
    } catch (_) {
      if (mounted) {
        setState(() => soundError = '소리를 재생하지 못했어요. 사운드 설정에서 다시 선택해 주세요.');
      }
    }
  }

  Future<void> _stopSound() async {
    try {
      await widget.sounds?.stop();
    } catch (_) {
      if (mounted) {
        setState(() => soundError = '소리를 끄지 못했어요. 사운드 설정에서 다시 시도해 주세요.');
      }
    }
  }

  Future<void> _showGoal() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalEditor(
          goal: engine.state.goal,
          now: DateTime.fromMillisecondsSinceEpoch(engine.clock()),
          onSave: (goal) async {
            await _act(() => engine.saveGoal(goal));
            return error == null;
          },
        ),
      ),
    );
  }

  Future<void> _showSound() async {
    var wasPlaying = false;
    try {
      wasPlaying = (await widget.sounds?.status())?['playing'] == true;
    } catch (_) {
      if (mounted) {
        setState(() => soundError = '사운드 상태를 확인하지 못했어요. 다시 선택해 주세요.');
      }
    }
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: deskPaper,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      builder: (_) => SoundSheet(
        value: engine.state.sound,
        onPreview: (sound) async {
          await widget.sounds?.preview(sound, session: engine.state.active);
          if (widget.sounds != null && sound.enabled) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            final status = await widget.sounds!.status();
            if (status['error'] != null) {
              throw StateError('Audio playback unavailable');
            }
          }
        },
        onSave: (sound) async {
          await _act(() => engine.saveSound(sound));
          if (error != null) return false;
          await _syncSound(activate: sound.enabled);
          return true;
        },
      ),
    );
    if (saved != true) {
      if (wasPlaying) {
        await _syncSound(activate: true);
      } else {
        await _stopSound();
      }
    }
  }

  Widget _settings(FocusState state) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
    children: [
      const Text(
        '설정',
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        '내게 맞는 집중 시간을 만들어요',
        style: TextStyle(color: deskBlue, fontSize: 16),
      ),
      const SizedBox(height: 24),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.flag_outlined, color: deskBlue),
        title: const Text(
          '목표와 다짐',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(state.goal?.name ?? '목표와 D-day를 정해 보세요'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: busy ? null : _showGoal,
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.volume_up_outlined, color: deskBlue),
        title: const Text(
          '소리 기본 설정',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          state.sound.enabled
              ? soundChoices.firstWhere((s) => s.$1 == state.sound.sound).$2
              : '현재 소리 꺼짐',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: busy ? null : _showSound,
      ),
      if (soundError != null)
        Text(
          soundError!,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.notifications_none_rounded, color: deskBlue),
        title: const Text(
          '집중 완료 알림',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(notifications ? '알림이 켜져 있어요' : '완료 시간을 알려드려요'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: busy || widget.alerts == null
            ? null
            : () async {
                await widget.alerts!.request();
                await _alerts();
              },
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.chair_outlined, color: deskBlue),
        title: const Text(
          '모은 소품',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${state.unlocks.length}개의 작은 선물'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('모은 소품')),
              body: _collection(state),
            ),
          ),
        ),
      ),
      const Divider(height: 36),
      const Text(
        '짧게 집중하기',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final value in [5, 15])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: busy || error != null
                      ? null
                      : () {
                          setState(() => page = 0);
                          _start(SessionMode.focus, value);
                        },
                  child: Text('$value분 집중 시작'),
                ),
              ),
            ),
        ],
      ),
      TextButton(
        onPressed: busy || error != null
            ? null
            : () {
                setState(() => page = 0);
                _start(SessionMode.demo);
              },
        child: const Text('1분 체험 · 기록과 보상 없이 둘러보기'),
      ),
      const Divider(height: 28),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.info_outline_rounded, color: deskMuted),
        title: const Text('사운드 출처와 라이선스'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _showSoundCredits,
      ),
    ],
  );

  void _showSoundCredits() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('사운드 출처'),
      content: const SingleChildScrollView(
        child: SelectableText(
          '세 음원은 CC0 1.0으로 공개되었습니다. 앱에 포함되어 오프라인에서도 재생돼요.\n\n창밖의 비 — bastipictures\nrain against window 2\nhttps://freesound.org/s/243781/\n\n숲의 바람 — kyles\nforest ambience constant breeze.flac\nhttps://freesound.org/s/637559/\n\n따뜻한 장작 — jmehlferber\nfire-crackling.wav\nhttps://freesound.org/s/370938/\n\nhttps://creativecommons.org/publicdomain/zero/1.0/',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );

  String _propName(String key) => switch (key) {
    'plant' => '작은 화분',
    'mug' => '따뜻한 머그컵',
    _ => '포근한 조명',
  };
  Widget _collection(FocusState s) => ListView(
    children: [
      _heading(
        'LITTLE THINGS, EARNED SLOWLY',
        '방을 채우는 시간',
        '정해진 세 자리에, 나의 집중이 남아요.',
      ),
      SizedBox(
        height: 255,
        child: DeskIllustration(
          unlocked: s.unlocks.keys.toSet(),
          ambience: RoomAmbience.at(
            DateTime.fromMillisecondsSinceEpoch(engine.clock()),
          ),
        ),
      ),
      for (final e in {
        'plant': '첫 정상 집중 완료',
        'mug': '정상 완료 누적 60분',
        'lamp': '정상 완료 누적 120분',
      }.entries)
        Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBE1),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              Icon(
                e.key == 'plant'
                    ? Icons.spa_outlined
                    : e.key == 'mug'
                    ? Icons.coffee_outlined
                    : Icons.light_outlined,
                color: s.unlocks.containsKey(e.key)
                    ? sage
                    : const Color(0xFFB5ADA0),
                size: 29,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _propName(e.key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF938B7E),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                s.unlocks.containsKey(e.key)
                    ? Icons.check_circle
                    : Icons.lock_outline,
                color: sage,
                size: 19,
              ),
            ],
          ),
        ),
      const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '소품은 자동으로 자리에 놓여요.\n중도 종료·1분 체험·휴식은 해금에 포함되지 않아요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF928A7E), fontSize: 12),
        ),
      ),
    ],
  );
}
