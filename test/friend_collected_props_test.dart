import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

import 'session_engine_test.dart' show MemoryStore;

Future<void> _loadScene(WidgetTester tester, FocusFriend friend) async {
  final context = tester.element(find.byType(DeskIllustration));
  await tester.runAsync(() async {
    for (final asset in [
      friend.restRoomAsset(RoomAmbience.day),
      '${friend.motionDirectory}/study.png',
      '${friend.motionDirectory}/rest.png',
      'assets/images/immersive/reward-plant.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

void main() {
  for (final friend in FocusFriend.values.where(
    (friend) => friend != FocusFriend.redpanda,
  )) {
    testWidgets(
      '${friend.name}: earned props appear immediately without restarting study motion',
      (tester) async {
        Set<String> unlocked = {};
        var resting = false;
        Widget harness() => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DeskIllustration(
            friend: friend,
            unlocked: unlocked,
            ambience: RoomAmbience.day,
            animate: true,
            studying: !resting,
            resting: resting,
          ),
        );
        await tester.pumpWidget(harness());
        await _loadScene(tester, friend);
        FriendMotionScenePainter painter() =>
            tester
                    .widget<CustomPaint>(
                      find.byKey(const ValueKey('friend-motion-cels')),
                    )
                    .painter!
                as FriendMotionScenePainter;
        (int, int, double, FriendMotionPhase) stamp() {
          final pose = painter().actor.pose;
          return (pose.from, pose.to, pose.blend, pose.phase);
        }

        expect(find.byKey(const ValueKey('desk-prop-plant')), findsNothing);
        expect(painter().showDeskMug, isFalse);
        await tester.pump(const Duration(milliseconds: 800));
        final moving = stamp();
        expect(moving.$1, isNot(0));

        unlocked = {'plant'};
        await tester.pumpWidget(harness());
        expect(find.byKey(const ValueKey('desk-prop-plant')), findsOneWidget);
        expect(painter().showDeskMug, isFalse);
        expect(stamp(), moving);

        unlocked = {'plant', 'mug'};
        await tester.pumpWidget(harness());
        expect(find.byKey(const ValueKey('desk-prop-plant')), findsOneWidget);
        expect(painter().showDeskMug, isTrue);
        expect(stamp(), moving);
        await tester.pump(const Duration(milliseconds: 500));
        expect(stamp(), isNot(moving));

        resting = true;
        await tester.pumpWidget(harness());
        await _loadScene(tester, friend);
        expect(painter().actor.pose.phase, FriendMotionPhase.tea);
        expect(find.byKey(const ValueKey('desk-prop-plant')), findsOneWidget);
        // The earned desk mug must never remove the cup held during a break.
        await tester.runAsync(() async {
          final scene = painter();
          Future<List<int>> render(
            bool earnedMug, {
            required bool resting,
          }) async {
            final recorder = ui.PictureRecorder();
            FriendMotionScenePainter(
              room: scene.room,
              ambience: scene.ambience,
              showDeskMug: earnedMug,
              actor: FriendMotionPainter(
                friend: friend,
                study: scene.actor.study,
                rest: scene.actor.rest,
                pose: FriendMotionClock.sample(
                  const Duration(seconds: 4),
                  resting: resting,
                  friend: friend,
                ),
              ),
            ).paint(Canvas(recorder), const Size(427, 922));
            final picture = recorder.endRecording();
            final image = await picture.toImage(427, 922);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final pixels = List<int>.from(bytes!.buffer.asUint8List());
            image.dispose();
            picture.dispose();
            return pixels;
          }

          expect(
            listEquals(
              await render(false, resting: false),
              await render(true, resting: false),
            ),
            isFalse,
            reason: 'Earning the mug must visibly change the study scene',
          );
          expect(
            listEquals(
              await render(false, resting: true),
              await render(true, resting: true),
            ),
            isTrue,
            reason: 'Tea animation must be unchanged by desk mug ownership',
          );
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'switching and restoring every friend retains one shared collection',
    () async {
      final store = MemoryStore()
        ..raw = FocusState(
          completedMs: 60 * 60000,
          completedCount: 3,
          unlocks: {'plant': 1234, 'mug': 5678},
        ).encode();
      final engine = SessionEngine(store);
      await engine.restore();
      final savedCollection = engine.state.toJson()
        ..remove('friendId')
        ..remove('revision');
      for (final friend in FocusFriend.values) {
        await engine.saveFriend(friend);
        final restored = SessionEngine(store);
        await restored.restore();
        expect(restored.state.friend, friend);
        expect(
          restored.state.toJson()
            ..remove('friendId')
            ..remove('revision'),
          savedCollection,
        );
      }
    },
  );
}
