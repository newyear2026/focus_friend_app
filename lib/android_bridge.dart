import 'package:flutter/services.dart';
import 'session_engine.dart';

class AndroidStore implements StateStore {
  static const channel = MethodChannel('focus_friend/local');
  @override
  Future<FocusState> load() async {
    final raw = await channel.invokeMethod<String>('load');
    return raw == null ? FocusState() : FocusState.decode(raw);
  }

  @override
  Future<void> commit(FocusState next, int expectedRevision) =>
      channel.invokeMethod<void>('commit', {
        'json': next.encode(),
        'expected': expectedRevision,
        'revision': next.revision,
      });
}

class LocalAlerts {
  Future<bool> enabled() async =>
      await AndroidStore.channel.invokeMethod<bool>('alertsEnabled') ?? false;
  Future<void> request() =>
      AndroidStore.channel.invokeMethod<void>('requestAlerts');
  Future<void> sync() => AndroidStore.channel.invokeMethod<void>('syncAlerts');
}

class ScreenAwake {
  Future<void> set(bool on) =>
      AndroidStore.channel.invokeMethod<void>('keepScreenOn', {'on': on});
}

/// The language chosen in Settings, kept by Android rather than the snapshot
/// so notifications and system Settings > Apps > Language see it too.
class AppLanguageStore {
  /// [app] is null when the app follows the phone; [system] is the phone's.
  Future<({String? app, String? system})> load() async {
    final value = await AndroidStore.channel
        .invokeMethod<Map<Object?, Object?>>('getLanguage');
    return (app: value?['app'] as String?, system: value?['system'] as String?);
  }

  Future<void> save(String? tag) =>
      AndroidStore.channel.invokeMethod<void>('setLanguage', {'tag': tag});
}

class FocusSoundPlayer {
  static const channel = MethodChannel('focus_friend/sound');
  Future<void> preview(SoundPreferences sound, {Session? session}) =>
      channel.invokeMethod<void>('configure', {
        ...sound.toJson(),
        'command': sound.enabled ? 'play' : 'stop',
        'preview': true,
        'activate': true,
        'session': session?.id,
        'endAt':
            sound.stopAtEnd &&
                session?.status == SessionStatus.running &&
                session?.mode != SessionMode.rest
            ? session?.endAt
            : null,
      });
  Future<void> sync(FocusState state, {bool activate = false}) {
    final a = state.active;
    final mustStop =
        !state.sound.enabled ||
        a?.status == SessionStatus.paused ||
        a?.mode == SessionMode.rest ||
        (a?.status == SessionStatus.completed && state.sound.stopAtEnd);
    final running =
        a?.status == SessionStatus.running && a?.mode != SessionMode.rest;
    return channel.invokeMethod<void>('configure', {
      ...state.sound.toJson(),
      'command': mustStop
          ? 'stop'
          : running || activate
          ? 'play'
          : 'update',
      'session': a?.id,
      'endAt': running && state.sound.stopAtEnd ? a?.endAt : null,
      'activate': activate,
      'preview': false,
    });
  }

  Future<void> stop() =>
      channel.invokeMethod<void>('configure', {'command': 'stop'});
  Future<Map<Object?, Object?>> status() async =>
      await channel.invokeMethod<Map<Object?, Object?>>('status') ?? {};
}
