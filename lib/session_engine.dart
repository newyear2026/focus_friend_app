import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'desk_props.dart';
import 'focus_preferences.dart';
import 'focus_friend.dart';
export 'focus_preferences.dart';

enum SessionMode { focus, demo, rest }

enum SessionStatus { running, paused, completed, stopped }

class Session {
  Session({
    required this.id,
    required this.mode,
    required this.status,
    required this.startedAt,
    required this.durationMs,
    required this.remainingMs,
    required this.actualMs,
    this.endAt,
    this.segmentAt,
    this.finishedAt,
    this.rewards = const [],
  });
  final String id;
  final SessionMode mode;
  SessionStatus status;
  final int startedAt;
  final int durationMs;
  int remainingMs;
  int actualMs;
  int? endAt;
  int? segmentAt;
  int? finishedAt;
  List<String> rewards;
  bool get live =>
      status == SessionStatus.running || status == SessionStatus.paused;

  int remaining(int now) => status == SessionStatus.running
      ? (endAt! - now).clamp(0, remainingMs)
      : remainingMs;
  int actual(int now) => status == SessionStatus.running
      ? (actualMs + (remainingMs - remaining(now))).clamp(0, durationMs)
      : actualMs;
  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.name,
    'status': status.name,
    'startedAt': startedAt,
    'durationMs': durationMs,
    'remainingMs': remainingMs,
    'actualMs': actualMs,
    'endAt': endAt,
    'segmentAt': segmentAt,
    'finishedAt': finishedAt,
    'rewards': rewards,
  };
  factory Session.fromJson(Map<String, dynamic> j) => Session(
    id: j['id'] as String,
    mode: SessionMode.values.byName(j['mode'] as String),
    status: SessionStatus.values.byName(j['status'] as String),
    startedAt: j['startedAt'] as int,
    durationMs: j['durationMs'] as int,
    remainingMs: j['remainingMs'] as int,
    actualMs: j['actualMs'] as int,
    endAt: j['endAt'] as int?,
    segmentAt: j['segmentAt'] as int?,
    finishedAt: j['finishedAt'] as int?,
    rewards: List<String>.from(j['rewards'] as List),
  );
}

class FocusState {
  FocusState({
    this.revision = 0,
    this.active,
    this.completedMs = 0,
    this.completedCount = 0,
    Map<String, int>? unlocks,
    List<Session>? history,
    Map<String, DailyFocus>? dailyFocus,
    this.goal,
    this.sound = const SoundPreferences(),
    this.keepScreenOn = false,
    this.friend = FocusFriend.redpanda,
  }) : dailyFocus = dailyFocus ?? _migrateDaily(history ?? []),
       unlocks = unlocks ?? {},
       history = history ?? [];
  int revision;
  Session? active;
  int completedMs;
  int completedCount;
  final Map<String, int> unlocks;
  final List<Session> history;
  final Map<String, DailyFocus> dailyFocus;
  FocusGoal? goal;
  SoundPreferences sound;
  // Holds the screen awake while a focus, demo or rest timer runs.
  bool keepScreenOn;
  FocusFriend friend;
  static Map<String, DailyFocus> _migrateDaily(List<Session> sessions) {
    final result = <String, DailyFocus>{};
    for (final session in sessions) {
      if (session.mode != SessionMode.focus ||
          session.status != SessionStatus.completed ||
          session.finishedAt == null) {
        continue;
      }
      final key = calendarKey(
        DateTime.fromMillisecondsSinceEpoch(session.finishedAt!),
      );
      result[key] = (result[key] ?? const DailyFocus()).add(session.actualMs);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'revision': revision,
    'active': active?.toJson(),
    'completedMs': completedMs,
    'completedCount': completedCount,
    'unlocks': unlocks,
    'history': history.map((s) => s.toJson()).toList(),
    'dailyFocus': dailyFocus.map((key, value) => MapEntry(key, value.toJson())),
    'goal': goal?.toJson(),
    'sound': sound.toJson(),
    'keepScreenOn': keepScreenOn,
    'friendId': friend.name,
  };
  String encode() => jsonEncode(toJson());
  FocusState copy() => FocusState.decode(encode());
  factory FocusState.decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['schema'] != 1) {
      throw const FormatException('Unsupported save version');
    }
    return FocusState(
      revision: j['revision'] as int,
      active: j['active'] == null
          ? null
          : Session.fromJson(j['active'] as Map<String, dynamic>),
      completedMs: j['completedMs'] as int,
      completedCount: j['completedCount'] as int,
      unlocks: Map<String, int>.from(j['unlocks'] as Map),
      dailyFocus: j['dailyFocus'] == null
          ? null
          : (j['dailyFocus'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                DailyFocus.fromJson(value as Map<String, dynamic>),
              ),
            ),
      goal: j['goal'] == null
          ? null
          : FocusGoal.fromJson(j['goal'] as Map<String, dynamic>),
      sound: j['sound'] == null
          ? const SoundPreferences()
          : SoundPreferences.fromJson(j['sound'] as Map<String, dynamic>),
      keepScreenOn: j['keepScreenOn'] as bool? ?? false,
      friend: FocusFriend.fromId(j['friendId'] as String?),
      history: (j['history'] as List)
          .map((x) => Session.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// commit must atomically compare the revision and replace the complete state.
/// Android uses one SQLite transaction; a rejected commit must never mutate UI state.
abstract interface class StateStore {
  Future<FocusState> load();
  Future<void> commit(FocusState next, int expectedRevision);
}

class SessionEngine {
  SessionEngine(
    this.store, {
    int Function()? clock,
    String Function()? idFactory,
  }) : clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       idFactory =
           idFactory ??
           (() {
             final random = Random.secure();
             return List.generate(
               16,
               (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
             ).join();
           });
  final StateStore store;
  final int Function() clock;
  final String Function() idFactory;
  FocusState _current = FocusState();
  FocusState? _snapshot;
  FocusState get _state => _current;
  set _state(FocusState value) {
    _current = value;
    _snapshot = null;
  }

  /// A read-only view shared by every reader until the saved state changes.
  /// The UI reads this several times a second, so it must never be mutated:
  /// all changes go through the engine's methods.
  FocusState get state => _snapshot ??= _state.copy();
  Future<void> _tail = Future.value();
  bool _loaded = false;
  bool _uncertain = false;

  Future<void> _serial(Future<void> Function() action) {
    final future = _tail.then((_) => action());
    _tail = future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return future;
  }

  Future<void> restore() => _serial(() async {
    _state = await store.load();
    _loaded = true;
    _uncertain = false;
    final next = _state.copy();
    if (_completeIfDue(next, clock())) await _save(next);
  });

  Future<void> _save(FocusState next) async {
    next.revision = _state.revision + 1;
    try {
      await store.commit(next, _state.revision);
      _state = next;
    } catch (_) {
      // A channel reply can be lost after COMMIT. Reload before another action.
      _uncertain = true;
      rethrow;
    }
  }

  Future<void> _change(bool Function(FocusState next, int now) change) =>
      _serial(() async {
        assert(
          _snapshot == null || _snapshot!.encode() == _state.encode(),
          'SessionEngine.state was modified outside the engine.',
        );
        if (!_loaded || _uncertain) {
          _state = await store.load();
          _loaded = true;
          _uncertain = false;
        }
        final next = _state.copy();
        if (change(next, clock())) await _save(next);
      });

  Future<void> saveGoal(FocusGoal? goal) => _change((s, now) {
    s.goal = goal;
    return true;
  });

  Future<void> saveSound(SoundPreferences sound) => _change((s, now) {
    s.sound = sound;
    return true;
  });

  Future<void> saveKeepScreenOn(bool keepScreenOn) => _change((s, now) {
    s.keepScreenOn = keepScreenOn;
    return true;
  });

  Future<void> saveFriend(FocusFriend friend) => _change((s, now) {
    if (s.active != null) throw StateError('Finish the session first');
    if (s.friend == friend) return false;
    s.friend = friend;
    return true;
  });

  Future<void> start(
    Duration duration, {
    SessionMode mode = SessionMode.focus,
  }) => _change((s, now) {
    if (s.active != null) return false;
    if (duration.inMilliseconds <= 0) {
      throw ArgumentError('Positive duration required');
    }
    // Demo has a fixed independent one-minute duration.
    final ms = mode == SessionMode.demo ? 60000 : duration.inMilliseconds;
    s.active = Session(
      id: idFactory(),
      mode: mode,
      status: SessionStatus.running,
      startedAt: now,
      durationMs: ms,
      remainingMs: ms,
      actualMs: 0,
      endAt: now + ms,
      segmentAt: now,
    );
    return true;
  });

  Future<void> pause(String id) => _change((s, now) {
    final a = s.active;
    if (a == null || a.id != id || a.status != SessionStatus.running) {
      return false;
    }
    if (_completeIfDue(s, now)) return true;
    a.actualMs = a.actual(now);
    a.remainingMs = a.remaining(now);
    a.endAt = null;
    a.segmentAt = null;
    a.status = SessionStatus.paused;
    return true;
  });

  Future<void> resume(String id) => _change((s, now) {
    final a = s.active;
    if (a == null || a.id != id || a.status != SessionStatus.paused) {
      return false;
    }
    a.status = SessionStatus.running;
    a.segmentAt = now;
    a.endAt = now + a.remainingMs;
    return true;
  });

  Future<void> stop(String id) => _change((s, now) {
    final a = s.active;
    if (a == null || a.id != id || !a.live) return false;
    // At/after the deadline, normal completion wins even if Stop is tapped.
    if (_completeIfDue(s, now)) return true;
    a.actualMs = a.actual(now);
    a.remainingMs = a.remaining(now);
    a.status = SessionStatus.stopped;
    a.finishedAt = now;
    a.endAt = null;
    a.segmentAt = null;
    if (a.mode == SessionMode.focus) _record(s, a);
    s.active = null;
    return true;
  });

  Future<void> complete(String id) => _change((s, now) {
    if (s.active?.id != id) return false;
    return _completeIfDue(s, now);
  });

  Future<void> dismiss(String id) => _change((s, now) {
    if (s.active?.id != id || s.active?.status != SessionStatus.completed) {
      return false;
    }
    s.active = null;
    return true;
  });

  bool _completeIfDue(FocusState s, int now) {
    final a = s.active;
    if (a == null || a.status != SessionStatus.running || now < a.endAt!) {
      return false;
    }
    a.finishedAt = a.endAt;
    a.actualMs = a.durationMs;
    a.remainingMs = 0;
    a.status = SessionStatus.completed;
    a.segmentAt = null;
    if (a.mode == SessionMode.focus) {
      s.completedMs += a.actualMs;
      s.completedCount++;
      for (final prop in deskProps) {
        if (!prop.availableByDefault &&
            s.completedMs >= prop.unlockMs &&
            !s.unlocks.containsKey(prop.key)) {
          s.unlocks[prop.key] = a.finishedAt!;
          a.rewards = [...a.rewards, prop.key];
        }
      }
      _record(s, a);
    }
    return true;
  }

  void _record(FocusState s, Session a) {
    if (a.status == SessionStatus.completed && a.mode == SessionMode.focus) {
      final key = calendarKey(
        DateTime.fromMillisecondsSinceEpoch(a.finishedAt!),
      );
      s.dailyFocus[key] = (s.dailyFocus[key] ?? const DailyFocus()).add(
        a.actualMs,
      );
    }
    s.history.insert(0, Session.fromJson(a.toJson()));
    if (s.history.length > 100) s.history.removeRange(100, s.history.length);
    // Lifetime counters and unlock ledger are never derived from this bounded list.
  }
}
