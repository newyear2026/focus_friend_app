import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/android_bridge.dart';
import 'persistence_test.dart' show VerificationStore;

class FeatureFixture implements StateStore {
  FeatureFixture(this.value);
  FocusState value;
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (value.revision != expectedRevision) throw StateError('revision');
    value = next.copy();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'feature navigation, real persistence, offline audio and rendered screens',
    (tester) async {
      final now = DateTime(2026, 10, 7, 15);
      final store = FeatureFixture(
        FocusState(
          completedMs: 400 * 60000,
          completedCount: 16,
          unlocks: {'plant': 1},
          goal: const FocusGoal(
            name: '자격증 시험',
            date: '2026-11-06',
            message: '오늘도 한 걸음씩',
          ),
          dailyFocus: {
            for (final d in [1, 2, 4, 5, 6, 7])
              '2026-10-${d.toString().padLeft(2, '0')}': DailyFocus(
                milliseconds: (d == 7 ? 50 : 70) * 60000,
                count: d == 7 ? 2 : 3,
              ),
          },
          history: [
            for (final minute in [30, 0])
              Session(
                id: 'fixture-$minute',
                mode: SessionMode.focus,
                status: SessionStatus.completed,
                startedAt: DateTime(
                  2026,
                  10,
                  7,
                  14,
                  minute,
                ).millisecondsSinceEpoch,
                durationMs: 25 * 60000,
                remainingMs: 0,
                actualMs: 25 * 60000,
                finishedAt: DateTime(
                  2026,
                  10,
                  7,
                  14,
                  minute + 25,
                ).millisecondsSinceEpoch,
              ),
          ],
        ),
      );
      final engine = SessionEngine(
        store,
        clock: () => now.millisecondsSinceEpoch,
      );
      final folder = Directory('${Directory.systemTemp.path}/feature-preview');
      await folder.create(recursive: true);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: FocusFriendApp(engine: engine),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.pump();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${folder.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      await capture('home');
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      await capture('records');
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await capture('settings');
      await tester.tap(find.text('목표와 다짐'));
      await tester.pumpAndSettle();
      await capture('goal');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-goal')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-goal')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('책상'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('open-sound')));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('sound-rain')));
      await tester.pump(const Duration(milliseconds: 300));
      await capture('sound');
      await tester.ensureVisible(find.byKey(const ValueKey('save-sound')));
      await tester.tap(find.byKey(const ValueKey('save-sound')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(engine.state.sound.enabled, true);
      await tester.pumpWidget(const SizedBox.shrink());

      final disk = VerificationStore();
      final old = await disk.load();
      final blank = FocusState(revision: old.revision + 1);
      await disk.commit(blank, old.revision);
      var persistent = SessionEngine(disk);
      await persistent.restore();
      await persistent.saveGoal(
        const FocusGoal(name: '저장 확인', date: '2026-11-07', message: '한 걸음씩'),
      );
      await persistent.saveSound(
        const SoundPreferences(
          sound: 'forest',
          volume: .65,
          enabled: true,
          stopAtEnd: false,
        ),
      );
      persistent = SessionEngine(VerificationStore());
      await persistent.restore();
      expect(persistent.state.goal!.name, '저장 확인');
      expect(persistent.state.sound.sound, 'forest');
      expect(persistent.state.sound.volume, .65);
      expect(persistent.state.sound.stopAtEnd, false);

      final sound = FocusSoundPlayer();
      for (final id in ['rain', 'forest', 'fire']) {
        await sound.preview(SoundPreferences(sound: id, enabled: true));
        await Future<void>.delayed(const Duration(seconds: 1));
        final status = await sound.status();
        expect(status['playing'], true, reason: '$id: $status');
        expect(status['error'], isNull);
      }
      // The host wrapper backgrounds the actual Android activity for 3 seconds.
      await File('${folder.path}/background-ready').writeAsString('ready');
      await Future<void>.delayed(const Duration(seconds: 9));
      expect((await sound.status())['playing'], true);
      final deadline = DateTime.now()
          .add(const Duration(seconds: 2))
          .millisecondsSinceEpoch;
      await FocusSoundPlayer.channel.invokeMethod<void>('configure', {
        'command': 'play',
        'sound': 'fire',
        'volume': .4,
        'endAt': deadline,
        'activate': true,
        'session': 'deadline-test',
      });
      await Future<void>.delayed(const Duration(seconds: 3));
      expect((await sound.status())['playing'], false);
      await sound.stop();
      await File('${folder.path}/results.json').writeAsString(
        jsonEncode({
          'navigation': 'passed',
          'nativePersistence': 'passed',
          'threeSounds': 'passed',
          'backgroundPlayback': 'passed',
          'autoStop': 'passed',
        }),
      );
      await File('${folder.path}/complete').writeAsString('ready');
      await Future<void>.delayed(const Duration(seconds: 15));
    },
  );
}
