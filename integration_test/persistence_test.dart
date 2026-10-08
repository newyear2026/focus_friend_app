import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'package:focus_friend_app/session_engine.dart';

class VerificationStore implements StateStore {
  bool fail = false;
  @override
  Future<FocusState> load() async {
    final raw = await AndroidStore.channel.invokeMethod<String>('load', {
      'scope': 'verification',
    });
    return raw == null ? FocusState() : FocusState.decode(raw);
  }

  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    final inject = fail;
    fail = false;
    await AndroidStore.channel.invokeMethod<void>('commit', {
      'scope': 'verification',
      'json': next.encode(),
      'expected': expectedRevision,
      'revision': next.revision,
      'fail': inject,
    });
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android SQLite rollback, reopen, CAS and overdue completion',
    (_) async {
      final store = VerificationStore();
      final old = await store.load();
      final blank = FocusState(revision: old.revision + 1);
      await store.commit(blank, old.revision);
      var now = DateTime.now().millisecondsSinceEpoch;
      SessionEngine engine() => SessionEngine(store, clock: () => now);
      var e = engine();
      await e.restore();
      await e.start(const Duration(minutes: 5));
      final session = e.state.active!.id;
      now += 13000;
      await e.pause(session);
      e = engine();
      await e.restore();
      expect(e.state.active!.actualMs, 13000);
      now += 300000;
      expect(e.state.active!.remaining(now), 287000);
      await e.resume(session);
      now += 287000;
      store.fail = true;
      await expectLater(e.complete(session), throwsA(anything));
      var disk = await store.load();
      expect(disk.completedCount, 0);
      expect(disk.unlocks, isEmpty);
      e = engine();
      await e.restore();
      disk = await store.load();
      expect(disk.completedCount, 1);
      expect(disk.completedMs, 300000);
      expect(disk.unlocks.keys, contains('plant'));
      await Future.wait(List.generate(10, (_) => e.complete(session)));
      e = engine();
      await e.restore();
      expect(e.state.completedCount, 1);
      expect(e.state.history.length, 1);
      final stale = disk.copy()..revision = disk.revision + 1;
      await store.commit(stale, disk.revision);
      await expectLater(store.commit(stale, disk.revision), throwsA(anything));
      expect((await store.load()).completedCount, 1);
    },
  );
}
