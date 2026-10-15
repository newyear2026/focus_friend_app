import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

const friends = [
  FocusFriend.penguin,
  FocusFriend.otter,
  FocusFriend.squirrel,
  FocusFriend.fennec,
];

Future<void> loadArt(WidgetTester tester, FocusFriend friend) async {
  final context = tester.element(find.byType(DeskIllustration));
  await tester.runAsync(() async {
    for (final asset in [
      for (final ambience in RoomAmbience.values)
        friend.ambienceAsset(ambience),
      if (friend.hasDeskMotion) '${friend.motionDirectory}/study.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
}

void main() {
  test(
    'all four periods of every friend are bundled full resolution PNGs',
    () async {
      for (final friend in friends) {
        for (final ambience in RoomAmbience.values) {
          final data = await rootBundle.load(friend.ambienceAsset(ambience));
          expect(data.getUint32(0, Endian.big), 0x89504e47);
          expect(data.getUint32(16, Endian.big), 853);
          expect(data.getUint32(20, Endian.big), 1844);
        }
      }
    },
  );

  for (final friend in friends) {
    testWidgets(
      '${friend.name}: idle boundary and resume change only lighting',
      (tester) async {
        await loadAppFont();
        var now = DateTime(2026, 10, 15, 19, 59).millisecondsSinceEpoch;
        final store = MemoryStore()..raw = FocusState(friend: friend).encode();
        final engine = SessionEngine(store, clock: () => now);
        await tester.pumpWidget(
          FocusFriendApp(engine: engine, locale: const Locale('ko')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await loadArt(tester, friend);
        final before = engine.state.toJson();
        DeskIllustration scene() =>
            tester.widget(find.byType(DeskIllustration));
        expect(scene().ambience, RoomAmbience.evening);

        now += 60000;
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 2100));
        expect(scene().ambience, RoomAmbience.night);
        if (friend.hasDeskMotion) {
          final painter =
              tester
                      .widget<CustomPaint>(
                        find.byKey(const ValueKey('friend-motion-cels')),
                      )
                      .painter!
                  as FriendMotionScenePainter;
          expect(painter.ambience, RoomAmbience.night);
          expect(painter.roomBlend, 1);
        } else {
          expect(
            find.byKey(ValueKey(friend.ambienceAsset(RoomAmbience.night))),
            findsOneWidget,
          );
        }
        expect(engine.state.toJson(), before);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        now = DateTime(2026, 10, 16, 7).millisecondsSinceEpoch;
        await tester.pump(const Duration(seconds: 1));
        expect(scene().ambience, RoomAmbience.night);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(scene().ambience, RoomAmbience.morning);
        expect(engine.state.toJson(), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
    testWidgets(
      '${friend.name}: a paused pose survives the two-second room fade',
      (tester) async {
        await loadAppFont();
        var ambience = RoomAmbience.evening;
        var reduced = false;
        Widget harness() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: DeskIllustration(
              friend: friend,
              unlocked: const {},
              ambience: ambience,
              studying: true,
              animate: true,
              paused: true,
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
        await tester.pumpWidget(harness());
        await loadArt(tester, friend);
        FriendMotionScenePainter painter() =>
            tester
                    .widget<CustomPaint>(
                      find.byKey(const ValueKey('friend-motion-cels')),
                    )
                    .painter!
                as FriendMotionScenePainter;
        final held = painter().actor.pose;
        final actor = (held.from, held.to, held.blend);
        ambience = RoomAmbience.night;
        await tester.pumpWidget(harness());
        await tester.pump(const Duration(seconds: 1));
        expect(painter().roomBlend, closeTo(.5, .05));
        expect((
          painter().actor.pose.from,
          painter().actor.pose.to,
          painter().actor.pose.blend,
        ), actor);
        await tester.pump(const Duration(seconds: 1));
        expect(painter().roomBlend, 1);
        reduced = true;
        ambience = RoomAmbience.morning;
        await tester.pumpWidget(harness());
        await tester.pump();
        expect(painter().ambience, RoomAmbience.morning);
        expect(painter().roomBlend, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
