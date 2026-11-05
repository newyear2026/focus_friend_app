import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/update_news.dart';

class MemoryUpdateNewsStore implements UpdateNewsStore {
  MemoryUpdateNewsStore({this.build = 6, this.previous, this.updated = false});

  int build;
  int? previous;
  bool updated;
  bool failLoad = false;
  bool failSave = false;
  int loads = 0;
  final acknowledgements = <int>[];
  Completer<void>? loadGate;

  @override
  Future<UpdateNewsState> load() async {
    loads++;
    await loadGate?.future;
    if (failLoad) throw StateError('read failed');
    return UpdateNewsState(
      currentBuild: build,
      lastAcknowledgedBuild: previous,
      wasUpdated: updated,
    );
  }

  @override
  Future<void> acknowledge(int build) async {
    acknowledgements.add(build);
    if (failSave) throw StateError('write failed');
    if (previous == null || build > previous!) previous = build;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first installation is silent and its later upgrade is shown', () async {
    final store = MemoryUpdateNewsStore();
    final first = UpdateNews(store);
    await first.prepare();
    expect(first.pending, isFalse);
    expect(store.previous, 6);
    expect(store.acknowledgements, [6]);

    final sameBuild = UpdateNews(store);
    await sameBuild.prepare();
    expect(sameBuild.pending, isFalse);
    expect(store.acknowledgements, [6]);

    store.build = 7;
    store.updated = true;
    final upgraded = UpdateNews(store);
    await upgraded.prepare();
    expect(upgraded.pending, isTrue);
    expect(store.previous, 6);
    await upgraded.acknowledge();
    expect(upgraded.pending, isFalse);
    expect(store.previous, 7);

    final relaunch = UpdateNews(store);
    await relaunch.prepare();
    expect(relaunch.pending, isFalse);
  });

  test('upgrade from an app without tracking is shown once', () async {
    final store = MemoryUpdateNewsStore(updated: true);
    final news = UpdateNews(store);
    await news.prepare();
    expect(news.pending, isTrue);
    expect(store.acknowledgements, isEmpty);
    await news.acknowledge();
    await news.acknowledge();
    expect(store.acknowledgements, [6]);
    final relaunch = UpdateNews(store);
    await relaunch.prepare();
    expect(relaunch.pending, isFalse);
  });

  test(
    'skipped builds show current news; downgrades preserve watermark',
    () async {
      final store = MemoryUpdateNewsStore(
        build: 10,
        previous: 6,
        updated: true,
      );
      final upgraded = UpdateNews(store);
      await upgraded.prepare();
      expect(upgraded.pending, isTrue);
      await upgraded.acknowledge();
      expect(store.previous, 10);

      store.build = 8;
      final downgraded = UpdateNews(store);
      await downgraded.prepare();
      expect(downgraded.pending, isFalse);
      await downgraded.acknowledge();
      expect(store.previous, 10);
      expect(store.acknowledgements, [10]);
    },
  );

  test(
    'save failure suppresses this visit but retries after relaunch',
    () async {
      final store = MemoryUpdateNewsStore(previous: 5, updated: true)
        ..failSave = true;
      final news = UpdateNews(store);
      await news.prepare();
      final save = news.acknowledge();
      expect(news.pending, isFalse);
      await expectLater(save, throwsStateError);
      await news.prepare();
      expect(news.pending, isFalse);
      expect(store.previous, 5);

      final relaunch = UpdateNews(store);
      await relaunch.prepare();
      expect(relaunch.pending, isTrue);
      store.failSave = false;
      await relaunch.acknowledge();
      expect(store.previous, 6);
    },
  );

  test(
    'read and baseline failures can be retried without an announcement',
    () async {
      final store = MemoryUpdateNewsStore()..failLoad = true;
      final news = UpdateNews(store);
      await expectLater(news.prepare(), throwsStateError);
      expect(news.pending, isFalse);
      store.failLoad = false;
      store.failSave = true;
      await expectLater(news.prepare(), throwsStateError);
      expect(news.pending, isFalse);
      store.failSave = false;
      await news.prepare();
      expect(news.pending, isFalse);
      expect(store.previous, 6);
    },
  );

  test('concurrent preparation shares one read and baseline', () async {
    final gate = Completer<void>();
    final store = MemoryUpdateNewsStore()..loadGate = gate;
    final news = UpdateNews(store);
    final prepared = Future.wait([
      news.prepare(),
      news.prepare(),
      news.prepare(),
    ]);
    expect(store.loads, 1);
    gate.complete();
    await prepared;
    expect(store.acknowledgements, [6]);
    await news.prepare();
    expect(store.loads, 1);
  });

  test('manual acknowledgement waits for an in-flight startup read', () async {
    final gate = Completer<void>();
    final store = MemoryUpdateNewsStore(previous: 5, updated: true)
      ..loadGate = gate;
    final news = UpdateNews(store);
    final preparation = news.prepare();
    final acknowledgement = news.acknowledge();
    expect(store.loads, 1);
    expect(store.acknowledgements, isEmpty);
    gate.complete();
    await Future.wait([preparation, acknowledgement]);
    expect(news.pending, isFalse);
    expect(store.previous, 6);
    expect(store.acknowledgements, [6]);
  });

  test('manual acknowledgement can prepare before startup does', () async {
    final store = MemoryUpdateNewsStore(previous: 5, updated: true);
    final news = UpdateNews(store);
    await news.acknowledge();
    expect(news.pending, isFalse);
    expect(store.previous, 6);
    expect(store.loads, 1);
  });

  group('Android bridge', () {
    const channel = MethodChannel('focus_friend/local');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test(
      'reads installed build data and writes the acknowledged build',
      () async {
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getUpdateNews') {
            return {
              'currentBuild': 8,
              'lastAcknowledgedBuild': 6,
              'wasUpdated': true,
            };
          }
          return null;
        });
        final store = AndroidUpdateNewsStore();
        final state = await store.load();
        expect(state.currentBuild, 8);
        expect(state.lastAcknowledgedBuild, 6);
        expect(state.wasUpdated, isTrue);
        expect(state.shouldShow, isTrue);
        await store.acknowledge(state.currentBuild);
        expect(calls.last.method, 'acknowledgeUpdateNews');
        expect(calls.last.arguments, {'build': 8});
      },
    );

    test(
      'rejects malformed metadata instead of guessing update state',
      () async {
        for (final raw in [
          null,
          {'currentBuild': 0, 'wasUpdated': true},
          {'currentBuild': 6, 'wasUpdated': 'true'},
          {'currentBuild': 6, 'wasUpdated': false, 'lastAcknowledgedBuild': -1},
        ]) {
          messenger.setMockMethodCallHandler(channel, (_) async => raw);
          await expectLater(
            AndroidUpdateNewsStore().load(),
            throwsFormatException,
          );
        }
      },
    );
  });
}
