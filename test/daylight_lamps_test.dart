import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_props.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

import 'session_engine_test.dart' show MemoryStore;
import 'widget_test.dart' show loadAppFont;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('indoor lights turn off at 05:30 and on at 17:30 local time', () {
    for (final (hour, minute, lightsOn) in [
      (5, 29, true),
      (5, 30, false),
      (7, 59, false),
      (8, 0, false),
      (12, 0, false),
      (17, 29, false),
      (17, 30, true),
      (20, 0, true),
      (23, 59, true),
    ]) {
      final ambience = RoomAmbience.at(DateTime(2026, 11, 6, hour, minute));
      expect(ambience.lampsOn, lightsOn, reason: '$hour:$minute');
      for (final prop in deskProps) {
        expect(
          prop.sceneAsset(ambience),
          prop.key == 'lamp' && !lightsOn
              ? 'assets/images/immersive/reward-lamp-unlit.png'
              : prop.asset,
        );
      }
    }
  });

  test('daylight room selection uses the corrected source plates', () {
    expect(
      FocusFriend.penguin.restRoomAsset(RoomAmbience.morning),
      'assets/images/friends/ambience/penguin/morning-unlit.png',
    );
    expect(
      FocusFriend.penguin.restRoomAsset(RoomAmbience.day),
      'assets/images/friends/ambience/penguin/day.png',
    );
    for (final period in [RoomAmbience.morning, RoomAmbience.day]) {
      expect(
        FocusFriend.otter.restRoomAsset(period),
        'assets/images/friends/ambience/otter/${period.assetName}-unlit.png',
      );
      expect(
        FocusFriend.squirrel.restRoomAsset(period),
        'assets/images/friends/motion/squirrel/rooms/${period.assetName}-unlit.png',
      );
      expect(
        FocusFriend.fennec.restRoomAsset(period),
        'assets/images/friends/motion/fennec/rooms/${period.assetName}.png',
      );
    }
    for (final friend in FocusFriend.values) {
      for (final period in [RoomAmbience.evening, RoomAmbience.night]) {
        expect(friend.restRoomAsset(period), isNot(contains('-unlit')));
      }
    }
  });

  test('every actual runtime room remains a bundled 853 by 1844 PNG', () async {
    for (final friend in FocusFriend.values) {
      for (final ambience in RoomAmbience.values) {
        final asset = friend.restRoomAsset(ambience);
        final bytes = await rootBundle.load(asset);
        expect(bytes.getUint32(0, Endian.big), 0x89504e47, reason: asset);
        expect(bytes.getUint32(16, Endian.big), 853, reason: asset);
        expect(bytes.getUint32(20, Endian.big), 1844, reason: asset);
      }
    }
  });

  for (final (hour, expected) in [
    (5, RoomAmbience.morning),
    (17, RoomAmbience.evening),
  ]) {
    testWidgets(
      'live $hour:30 boundary changes the lamp without rewriting collection data',
      (tester) async {
        await loadAppFont();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var now = DateTime(2026, 11, 6, hour, 29).millisecondsSinceEpoch;
        final saved = FocusState(
          completedMs: 60 * 60000,
          completedCount: 2,
          unlocks: {'plant': 1, 'mug': 2},
        ).encode();
        final store = MemoryStore()..raw = saved;
        final engine = SessionEngine(store, clock: () => now);
        final lamp = deskProps.singleWhere((prop) => prop.key == 'lamp');
        await tester.pumpWidget(
          FocusFriendApp(engine: engine, locale: const Locale('ko')),
        );
        await tester.pumpAndSettle();
        final before = engine.state.toJson();
        final lampLayer = find.byKey(const ValueKey('desk-prop-lamp'));
        String displayedLamp() {
          final child =
              tester.widget<AnimatedSwitcher>(lampLayer).child! as Image;
          return (child.image as AssetImage).assetName;
        }

        final originalAsset = displayedLamp();
        expect(
          originalAsset,
          lamp.sceneAsset(
            RoomAmbience.at(DateTime.fromMillisecondsSinceEpoch(now)),
          ),
        );
        expect(lamp.isAvailable(engine.state.unlocks.keys), isTrue);
        expect(engine.state.unlocks.containsKey('lamp'), isFalse);

        now += 60000;
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester
              .widget<DeskIllustration>(find.byType(DeskIllustration))
              .ambience,
          expected,
        );
        expect(displayedLamp(), lamp.sceneAsset(expected));
        expect(displayedLamp(), isNot(originalAsset));
        // Include the disposal frame after the two-second crossfade.
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: lampLayer,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName == originalAsset,
            ),
          ),
          findsNothing,
        );
        expect(engine.state.toJson(), before);
        expect(store.raw, saved);
        expect(store.commits, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
