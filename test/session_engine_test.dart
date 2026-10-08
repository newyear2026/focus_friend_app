import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/session_engine.dart';

class MemoryStore implements StateStore {
  String? raw;
  bool failBefore = false, loseReply = false;
  int commits = 0;
  @override
  Future<FocusState> load() async =>
      raw == null ? FocusState() : FocusState.decode(raw!);
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (failBefore) {
      failBefore = false;
      throw StateError('disk full');
    }
    if ((await load()).revision != expectedRevision) {
      throw StateError('CAS conflict');
    }
    raw = next.encode();
    commits++;
    if (loseReply) {
      loseReply = false;
      throw StateError('reply lost after COMMIT');
    }
  }
}

void main() {
  late int now, ids;
  late MemoryStore store;
  late SessionEngine engine;
  SessionEngine make() => SessionEngine(
    store,
    clock: () => now,
    idFactory: () => 'session-${++ids}',
  );
  Future<void> start([int seconds = 60]) =>
      engine.start(Duration(seconds: seconds));
  String id() => engine.state.active!.id;
  setUp(() async {
    now = 1000000;
    ids = 0;
    store = MemoryStore();
    engine = make();
    await engine.restore();
  });

  test(
    'restart preserves ID, deadline and active time before deadline',
    () async {
      await start();
      final before = engine.state.active!;
      now += 23000;
      engine = make();
      await engine.restore();
      expect(id(), before.id);
      expect(engine.state.active!.endAt, before.endAt);
      expect(engine.state.active!.remaining(now), 37000);
      expect(engine.state.active!.actual(now), 23000);
    },
  );
  test(
    'overdue restart commits completion, lifetime total and first plant together',
    () async {
      await start();
      final end = engine.state.active!.endAt!;
      now += 600000;
      engine = make();
      await engine.restore();
      final s = engine.state;
      expect(s.active!.status, SessionStatus.completed);
      expect(s.active!.finishedAt, end);
      expect(s.completedMs, 60000);
      expect(s.history.single.actualMs, 60000);
      expect(s.unlocks, {'plant': end});
      expect(s.active!.rewards, ['plant']);
      engine = make();
      await engine.restore();
      expect(engine.state.completedCount, 1);
      expect(engine.state.active!.status, SessionStatus.completed);
    },
  );
  test(
    'pause/restart/wait/resume excludes paused time and retains same session',
    () async {
      await start();
      final session = id();
      now += 12500;
      await engine.pause(session);
      expect(engine.state.active!.endAt, isNull);
      expect(engine.state.active!.actualMs, 12500);
      now += 500000;
      engine = make();
      await engine.restore();
      expect(engine.state.active!.remaining(now), 47500);
      await engine.resume(session);
      expect(engine.state.active!.endAt, now + 47500);
      now += 47500;
      await engine.complete(session);
      expect(engine.state.completedMs, 60000);
    },
  );
  test(
    'stopped time is retained but never rewards, including paused stop',
    () async {
      await start();
      now += 9000;
      await engine.pause(id());
      now += 80000;
      await engine.stop(id());
      expect(engine.state.active, isNull);
      expect(engine.state.history.single.actualMs, 9000);
      expect(engine.state.history.single.status, SessionStatus.stopped);
      expect(engine.state.completedMs, 0);
      expect(engine.state.unlocks, isEmpty);
    },
  );
  test('95 percent is not completion', () async {
    await start(100);
    now += 95000;
    await engine.complete(id());
    expect(engine.state.active!.status, SessionStatus.running);
    await engine.stop(id());
    expect(engine.state.completedCount, 0);
  });
  test('at deadline Stop performs normal completion', () async {
    await start();
    now += 60000;
    await engine.stop(id());
    expect(engine.state.completedCount, 1);
  });
  test(
    'rapid start, pause, resume and complete are serialized and idempotent',
    () async {
      await Future.wait(List.generate(20, (_) => start()));
      final session = id();
      expect(ids, 1);
      now += 10000;
      await Future.wait(List.generate(20, (_) => engine.pause(session)));
      expect(engine.state.active!.actualMs, 10000);
      now += 100000;
      await Future.wait(List.generate(20, (_) => engine.resume(session)));
      expect(engine.state.active!.endAt, now + 50000);
      now += 50000;
      await Future.wait(List.generate(30, (_) => engine.complete(session)));
      expect(engine.state.completedCount, 1);
      expect(engine.state.history.length, 1);
    },
  );
  test(
    'stale callbacks cannot complete, stop or dismiss a newer session',
    () async {
      await start();
      final stale = id();
      await engine.stop(stale);
      await start();
      final newer = id();
      now += 60000;
      await engine.complete(stale);
      await engine.stop(stale);
      await engine.dismiss(stale);
      expect(id(), newer);
      expect(engine.state.completedCount, 0);
      await engine.complete(newer);
      expect(engine.state.completedCount, 1);
    },
  );
  test(
    'failed completion write leaves all state unchanged, then retries once',
    () async {
      await start();
      final before = store.raw;
      now += 60000;
      store.failBefore = true;
      await expectLater(engine.complete(id()), throwsStateError);
      expect(store.raw, before);
      expect(engine.state.completedCount, 0);
      expect(engine.state.unlocks, isEmpty);
      await engine.complete(id());
      expect(engine.state.completedCount, 1);
    },
  );
  test(
    'lost commit reply reloads durable state without duplicate reward',
    () async {
      await start();
      final session = id();
      now += 60000;
      store.loseReply = true;
      await expectLater(engine.complete(session), throwsStateError);
      expect(engine.state.completedCount, 0);
      await engine.complete(session);
      expect(engine.state.completedCount, 1);
      expect(engine.state.history.length, 1);
      expect(store.commits, 2);
    },
  );
  test(
    'failed start and pause are recoverable without UI-only progress',
    () async {
      store.failBefore = true;
      await expectLater(start(), throwsStateError);
      expect(engine.state.active, isNull);
      await start();
      now += 10000;
      store.failBefore = true;
      await expectLater(engine.pause(id()), throwsStateError);
      expect(engine.state.active!.status, SessionStatus.running);
      engine = make();
      await engine.restore();
      expect(engine.state.active!.remaining(now), 50000);
    },
  );
  test(
    'two writers conflict instead of overwriting committed rewards',
    () async {
      await start();
      final other = make();
      await other.restore();
      now += 60000;
      await engine.complete(id());
      await expectLater(other.complete(id()), throwsStateError);
      await other.restore();
      expect(other.state.completedCount, 1);
    },
  );
  test(
    'demo completion and cancellation leave real history/counters/unlocks unchanged',
    () async {
      await start();
      now += 60000;
      await engine.complete(id());
      await engine.dismiss(id());
      final old = engine.state;
      await engine.start(const Duration(seconds: 5), mode: SessionMode.demo);
      expect(engine.state.active!.durationMs, 60000);
      now += 60000;
      engine = make();
      await engine.restore();
      await engine.dismiss(id());
      await engine.start(const Duration(minutes: 1), mode: SessionMode.demo);
      now += 10000;
      await engine.stop(id());
      expect(engine.state.completedMs, old.completedMs);
      expect(engine.state.completedCount, old.completedCount);
      expect(engine.state.unlocks, old.unlocks);
      expect(
        engine.state.history.map((e) => e.toJson()),
        old.history.map((e) => e.toJson()),
      );
    },
  );
  test(
    'rest is explicit and isolated; normal completion never auto-starts rest',
    () async {
      await start();
      now += 60000;
      await engine.complete(id());
      now += 999999;
      engine = make();
      await engine.restore();
      expect(engine.state.active!.status, SessionStatus.completed);
      await engine.dismiss(id());
      await engine.start(const Duration(minutes: 5), mode: SessionMode.rest);
      now += 300000;
      await engine.complete(id());
      expect(engine.state.completedCount, 1);
    },
  );
  test(
    'history cap cannot reduce totals or revoke objects; first reward appears once',
    () async {
      for (var i = 0; i < 105; i++) {
        await start(60);
        now += 60000;
        await engine.complete(id());
        expect(engine.state.active!.rewards.contains('plant'), i == 0);
        await engine.dismiss(id());
      }
      expect(engine.state.history.length, 100);
      expect(engine.state.completedCount, 105);
      expect(engine.state.completedMs, 105 * 60000);
      expect(engine.state.unlocks.keys, containsAll(['plant', 'mug']));
      await start(15 * 60);
      now += 15 * 60000;
      await engine.complete(id());
      expect(engine.state.unlocks.keys, contains('lamp'));
    },
  );
  test('corrupt save fails visibly instead of wiping data', () async {
    store.raw = 'invalid';
    await expectLater(make().restore(), throwsFormatException);
    expect(store.raw, 'invalid');
  });
  test('clock rollback cannot create negative actual time', () async {
    await start();
    now -= 1000;
    await engine.pause(id());
    expect(engine.state.active!.actualMs, 0);
    expect(engine.state.active!.remainingMs, 60000);
  });
}
