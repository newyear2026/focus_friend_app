import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ads.dart';
import 'android_bridge.dart';
import 'session_engine.dart';
import 'room_ambience.dart';
import 'desk_components.dart';
import 'desk_home.dart';
import 'desk_props.dart';
import 'focus_records.dart';
import 'goal_editor.dart';
import 'l10n/app_localizations.dart';
import 'language_sheet.dart';
import 'localized_names.dart';
import 'sound_sheet.dart';
import 'session_stop_sheet.dart';
import 'friend_picker.dart';

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
      screen: ScreenAwake(),
      language: AppLanguageStore(),
      ads: AdsConsent(),
    ),
  );
}

class FocusFriendApp extends StatefulWidget {
  const FocusFriendApp({
    super.key,
    required this.engine,
    this.alerts,
    this.sounds,
    this.screen,
    this.language,
    this.locale,
    this.ads,
  });
  final SessionEngine engine;
  final LocalAlerts? alerts;
  final FocusSoundPlayer? sounds;
  final ScreenAwake? screen;

  /// Keeps the Settings language choice; null keeps it for this run only.
  final AppLanguageStore? language;

  /// Null in tests: no ad consent form and no ad SDK.
  final AdsConsent? ads;

  /// Forces a language regardless of the choice. Null follows the choice, or
  /// the phone when there is none; English covers unsupported languages.
  final Locale? locale;
  @override
  State<FocusFriendApp> createState() => _FocusFriendAppState();
}

class _FocusFriendAppState extends State<FocusFriendApp>
    with WidgetsBindingObserver {
  String? chosen, system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    system = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    unawaited(_loadLanguage());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(widget.ads?.start()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Android 13+ lets people change it from system Settings while we run.
  @override
  void didChangeLocales(List<Locale>? locales) => unawaited(_loadLanguage());

  Future<void> _loadLanguage() async {
    if (widget.language == null) return;
    try {
      final saved = await widget.language!.load();
      if (mounted) {
        setState(() {
          chosen = saved.app;
          system = saved.system ?? system;
        });
      }
    } catch (_) {
      // The phone language is a safe default.
    }
  }

  Future<void> _setLanguage(String? tag) async {
    setState(() => chosen = tag);
    try {
      await widget.language?.save(tag);
    } catch (_) {
      // Still applies until the app restarts.
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    locale: widget.locale ?? (chosen == null ? null : Locale(chosen!)),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildDeskTheme(ThemeData(useMaterial3: true)),
    home: RoomScreen(
      engine: widget.engine,
      alerts: widget.alerts,
      sounds: widget.sounds,
      screen: widget.screen,
      language: chosen,
      systemLanguage: system,
      onLanguage: _setLanguage,
      ads: widget.ads,
    ),
  );
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    required this.engine,
    this.alerts,
    this.sounds,
    this.screen,
    this.language,
    this.systemLanguage,
    this.onLanguage,
    this.ads,
  });
  final SessionEngine engine;
  final LocalAlerts? alerts;
  final FocusSoundPlayer? sounds;
  final ScreenAwake? screen;

  /// The chosen language tag, or null when following the phone.
  final String? language, systemLanguage;
  final Future<void> Function(String?)? onLanguage;
  final AdsConsent? ads;
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  bool ready = false, busy = false, notifications = false;
  bool foreground = true;
  bool adPrivacy = false;
  String? error;
  String? alertError;
  String? soundError;
  int page = 0, minutes = 25;
  Timer? ticker;
  Future<void>? pendingAction;
  int? displayedMinute;
  bool? screenOn;
  SessionEngine get engine => widget.engine;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restore());
    unawaited(_loadAdPrivacy());
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

  Future<void> _loadAdPrivacy() async {
    final ads = widget.ads;
    if (ads == null) return;
    await ads.ready;
    try {
      final required = await ads.privacyOptionsRequired();
      if (mounted) setState(() => adPrivacy = required);
    } catch (_) {
      // Without a status the tile stays hidden, as outside the EEA/UK.
    }
  }

  Future<void> _restore() async {
    if (busy) return;
    final restored = await _act(() => engine.restore());
    if (mounted && restored) {
      setState(() {
        ready = true;
      });
    }
  }

  Future<bool> _act(
    Future<void> Function() action, {
    bool waitForPending = false,
  }) async {
    // Timer taps may be ignored while busy, but settings saves must wait for
    // their own write and report its result to the editor.
    while (pendingAction != null) {
      if (!waitForPending) return false;
      await pendingAction;
    }
    if (!mounted) return false;
    final finished = Completer<void>();
    pendingAction = finished.future;
    setState(() {
      busy = true;
      error = null;
    });
    final previous = engine.state.active;
    var saved = false;
    try {
      try {
        await action();
        saved = true;
      } catch (_) {
        if (mounted) {
          setState(() {
            error = AppLocalizations.of(context).errorStorage;
          });
        }
      }
      if (saved) {
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
      await _syncScreen();
      return saved;
    } finally {
      pendingAction = null;
      if (mounted) setState(() => busy = false);
      finished.complete();
    }
  }

  /// Every timer change passes through [_act], so this is the only sync point.
  Future<void> _syncScreen() async {
    final state = engine.state;
    final on =
        state.keepScreenOn && state.active?.status == SessionStatus.running;
    if (widget.screen == null || on == screenOn) return;
    screenOn = on;
    try {
      await widget.screen!.set(on);
    } catch (_) {
      // Purely a convenience; retry on the next timer change.
      screenOn = null;
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
          alertError = AppLocalizations.of(context).errorAlerts;
        });
      }
    }
  }

  Future<void> _stop(Session a) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black54,
      constraints: const BoxConstraints(maxWidth: 600),
      clipBehavior: Clip.none,
      builder: (_) => SessionStopSheet(mode: a.mode),
    );
    if (confirmed == true) await _act(() => engine.stop(a.id));
  }

  Future<void> _start(SessionMode mode, [int? selectedMinutes]) => _act(
    () =>
        engine.start(Duration(minutes: selectedMinutes ?? minutes), mode: mode),
  );
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = engine.state;
    final active = state.active;
    final homeVisible = active != null || page == 0;
    final completed = active?.status == SessionStatus.completed;
    final resting = active?.mode == SessionMode.rest;
    final paused = active?.status == SessionStatus.paused;
    return Theme(
      data: deskTheme(context),
      child: Scaffold(
        backgroundColor: deskPaper,
        // Keep the room geometry fixed as controls change between sessions.
        extendBody: homeVisible,
        body: Stack(
          children: [
            if (homeVisible)
              Positioned.fill(
                child: DeskIllustration(
                  friend: state.friend,
                  unlocked: state.unlocks.keys.toSet(),
                  ambience: RoomAmbience.at(
                    DateTime.fromMillisecondsSinceEpoch(engine.clock()),
                  ),
                  studying: active != null && !resting && !completed,
                  resting: resting,
                  paused: paused,
                  animate:
                      active != null && !completed && !paused && foreground,
                ),
              ),
            SafeArea(
              bottom: !homeVisible,
              child: Column(
                children: [
                  if (error != null)
                    MaterialBanner(
                      content: Text(error!),
                      actions: [
                        TextButton(
                          onPressed: busy ? null : _restore,
                          child: Text(l10n.retryCheck),
                        ),
                      ],
                    ),
                  if (alertError != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        alertError!,
                        style: const TextStyle(color: deskInk),
                      ),
                    ),
                  Expanded(
                    child: !ready
                        ? Center(
                            child: error == null
                                ? const CircularProgressIndicator()
                                : Text(l10n.restoringRoom),
                          )
                        : active != null || page == 0
                        ? _home(state)
                        : page == 1
                        ? FriendPicker(
                            current: state.friend,
                            unlocked: state.unlocks.keys.toSet(),
                            onApply: engine.saveFriend,
                            onApplied: () => setState(() => page = 0),
                          )
                        : page == 2
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
          ],
        ),
        bottomNavigationBar: Visibility(
          visible: active == null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: DeskNavigation(
            immersive: homeVisible,
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
      color: deskMuted,
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
          style: const TextStyle(color: deskMuted, fontSize: 13, height: 1.5),
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
    systemBottomInset: MediaQuery.viewPaddingOf(context).bottom,
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
        setState(
          () => soundError = AppLocalizations.of(context).errorSoundPlay,
        );
      }
    }
  }

  Future<void> _stopSound() async {
    try {
      await widget.sounds?.stop();
    } catch (_) {
      if (mounted) {
        setState(
          () => soundError = AppLocalizations.of(context).errorSoundStop,
        );
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
          onSave: (goal) =>
              _act(() => engine.saveGoal(goal), waitForPending: true),
        ),
      ),
    );
  }

  Future<void> _showLanguage() async {
    final picked = await showModalBottomSheet<({String? tag})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: deskPaper,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      builder: (_) =>
          LanguageSheet(value: widget.language, system: widget.systemLanguage),
    );
    if (picked == null || picked.tag == widget.language) return;
    await widget.onLanguage?.call(picked.tag);
    if (!mounted) return;
    // Announce it in the new language; this context still has the old one.
    final shown = picked.tag ?? supportedLanguage(widget.systemLanguage);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            lookupAppLocalizations(
              Locale(shown),
            ).languageChanged(nativeLanguageNames[shown]!),
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
        setState(
          () => soundError = AppLocalizations.of(context).errorSoundStatus,
        );
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
          final saved = await _act(
            () => engine.saveSound(sound),
            waitForPending: true,
          );
          if (!saved) return false;
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

  Widget _settingTile(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: deskCream,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: deskInk, size: 22),
  );

  Widget _settings(FocusState state) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.settingsSubtitle,
                    style: const TextStyle(color: deskBlue, fontSize: 16),
                  ),
                ],
              ),
            ),
            const CompanionImage(size: 72),
          ],
        ),
        const SizedBox(height: 14),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _settingTile(Icons.flag_rounded),
          title: Text(
            l10n.goalTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(switch (state.goal) {
            final goal? =>
              '${goal.countdown(DateTime.fromMillisecondsSinceEpoch(engine.clock()))} · ${goal.name}',
            null => l10n.goalEmpty,
          }),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: busy ? null : _showGoal,
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _settingTile(Icons.volume_up_rounded),
          title: Text(
            l10n.soundDefaults,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            state.sound.enabled
                ? soundTitle(l10n, state.sound.sound)
                : l10n.soundOff,
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
          leading: _settingTile(Icons.notifications_rounded),
          title: Text(
            l10n.alertsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(notifications ? l10n.alertsOn : l10n.alertsOff),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: busy || widget.alerts == null
              ? null
              : () async {
                  await widget.alerts!.request();
                  await _alerts();
                },
        ),
        const Divider(),
        SwitchListTile(
          key: const ValueKey('keep-screen-on'),
          contentPadding: EdgeInsets.zero,
          secondary: _settingTile(Icons.light_mode_rounded),
          title: Text(
            l10n.keepScreenTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            state.keepScreenOn ? l10n.keepScreenOn : l10n.keepScreenOff,
          ),
          value: state.keepScreenOn,
          onChanged: busy || error != null
              ? null
              : (value) => _act(() => engine.saveKeepScreenOn(value)),
        ),
        const Divider(),
        ListTile(
          key: const ValueKey('open-language'),
          contentPadding: EdgeInsets.zero,
          leading: _settingTile(Icons.language_rounded),
          title: Text(
            l10n.languageTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            widget.language == null
                ? '${l10n.followSystem} · ${nativeLanguageNames[supportedLanguage(widget.systemLanguage)]}'
                : nativeLanguageNames[supportedLanguage(widget.language)]!,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: widget.onLanguage == null ? null : _showLanguage,
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _settingTile(Icons.weekend_rounded),
          title: Text(
            l10n.collectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(l10n.collectionCount(state.unlocks.length)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final prop in deskProps)
                if (state.unlocks.containsKey(prop.key))
                  Image.asset(
                    prop.asset,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(l10n.collectionTitle)),
                body: _collection(state),
              ),
            ),
          ),
        ),
        const Divider(height: 36),
        Text(
          l10n.quickFocusTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final value in [5, 15]) ...[
              if (value == 15) const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.quickFocusStart(value),
                  excludeSemantics: true,
                  child: TicketPanel(
                    color: deskPaper,
                    onTap: busy || error != null
                        ? null
                        : () {
                            setState(() => page = 0);
                            _start(SessionMode.focus, value);
                          },
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.quickFocusLabel(value),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.play_arrow_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: deskBlue),
          onPressed: busy || error != null
              ? null
              : () {
                  setState(() => page = 0);
                  _start(SessionMode.demo);
                },
          child: Text(l10n.demoButton),
        ),
        const Divider(height: 28),
        if (adPrivacy)
          ListTile(
            key: const ValueKey('ad-privacy'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined, color: deskMuted),
            title: Text(l10n.adPrivacyTile),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => unawaited(widget.ads!.showPrivacyOptions()),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded, color: deskMuted),
          title: Text(l10n.soundCreditsTile),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _showSoundCredits,
        ),
      ],
    );
  }

  void _showSoundCredits() => showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.soundCreditsTitle),
        content: SingleChildScrollView(
          child: SelectableText(
            '${l10n.soundCreditsIntro}\n\n${l10n.soundRainTitle} — bastipictures\nrain against window 2\nhttps://freesound.org/s/243781/\n\n${l10n.soundForestTitle} — kyles\nforest ambience constant breeze.flac\nhttps://freesound.org/s/637559/\n\n${l10n.soundFireTitle} — jmehlferber\nfire-crackling.wav\nhttps://freesound.org/s/370938/\n\nhttps://creativecommons.org/publicdomain/zero/1.0/',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );

  Widget _collection(FocusState s) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        _heading(
          'LITTLE THINGS, EARNED SLOWLY',
          l10n.collectionHeading,
          l10n.collectionSubtitle,
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
        for (final prop in deskProps)
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: deskCream,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: s.unlocks.containsKey(prop.key) ? 1 : 0.35,
                  child: Image.asset(
                    prop.asset,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propName(l10n, prop.key),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        prop.unlockMinutes == 0
                            ? l10n.unlockFirstFocus
                            : l10n.unlockAfterMinutes(prop.unlockMinutes),
                        style: const TextStyle(fontSize: 12, color: deskMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  s.unlocks.containsKey(prop.key)
                      ? Icons.check_circle
                      : Icons.lock_outline,
                  color: sage,
                  size: 19,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.collectionFootnote,
            textAlign: TextAlign.center,
            style: const TextStyle(color: deskMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
