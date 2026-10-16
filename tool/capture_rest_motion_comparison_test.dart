import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets('fresh actual-app capture of selected current tea motions', (
    tester,
  ) async {
    const folder = String.fromEnvironment(
      'REST_COMPARISON_OUTPUT',
      defaultValue: 'docs/design/rest-motion-comparison-v1',
    );
    const cycles = int.fromEnvironment(
      'REST_COMPARISON_CYCLES',
      defaultValue: 1,
    );
    const onlyFriend = String.fromEnvironment('REST_COMPARISON_FRIEND');
    if (onlyFriend.isNotEmpty) {
      expect(['redpanda', 'squirrel', 'fennec'], contains(onlyFriend));
    }
    Directory(folder).createSync(recursive: true);
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final (font, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font)..addFont(rootBundle.load(path))).load();
    }
    final manifest = <Map<String, Object>>[];
    for (final friend in [
      FocusFriend.redpanda,
      FocusFriend.squirrel,
      FocusFriend.fennec,
    ].where((friend) => onlyFriend.isEmpty || friend.name == onlyFriend)) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final now = DateTime(2026, 10, 15, 18).millisecondsSinceEpoch;
      final engine = SessionEngine(
        MemoryStore()
          ..raw = FocusState(
            friend: friend,
            active: Session(
              id: 'comparison-fixture',
              mode: SessionMode.rest,
              status: SessionStatus.running,
              startedAt: now,
              durationMs: 300000,
              remainingMs: 300000,
              actualMs: 0,
              endAt: now + 300000,
              segmentAt: now,
            ),
          ).encode(),
        clock: () => now,
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(RoomScreen));
        final assets = friend == FocusFriend.redpanda
            ? [
                'assets/images/immersive/room-evening.png',
                RestAnimation.asset,
                RestAnimation.inbetweensAsset,
                'assets/images/rest/closed-book.png',
              ]
            : [
                friend.restRoomAsset(RoomAmbience.evening),
                '${friend.motionDirectory}/rest.png',
              ];
        for (final asset in assets) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pump();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      await tester.pump();
      await tester.pump();
      final count = (friend == FocusFriend.redpanda ? 120 : 264) * cycles;
      final frames = Directory('$folder/frames/${friend.name}')
        ..createSync(recursive: true);
      String? lastStamp, lastPath;
      final samples = <Map<String, Object>>[];
      var lastElapsed = Duration.zero;
      for (var tick = 0; tick < count; tick++) {
        final elapsed = Duration(microseconds: (tick * 1000000 / 12).ceil());
        if (tick > 0) await tester.pump(elapsed - lastElapsed);
        lastElapsed = elapsed;
        String stamp;
        int from, to;
        double blend;
        if (friend == FocusFriend.redpanda) {
          final p =
              tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(RestCompanion),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as RestCompanionPainter;
          expect(p.atlas, isNotNull);
          expect(p.inbetweens, isNotNull);
          from = to = p.frame;
          blend = 0;
          stamp = 'cel-$from';
        } else {
          final p =
              (tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('friend-motion-cels')),
                          )
                          .painter!
                      as FriendMotionScenePainter)
                  .actor
                  .pose;
          from = p.from;
          to = p.to;
          blend = p.blend;
          stamp = from == to ? 'cel-$from' : '$from-$to-$blend';
        }
        final path = '${frames.path}/${tick.toString().padLeft(4, '0')}.png';
        final state = friend == FocusFriend.redpanda
            ? <int, String>{
                0: 'start',
                30: 'blink',
                40: 'lift-start',
                48: 'lift-middle',
                60: 'sip',
                78: 'lower-middle',
                100: 'rest',
                119: 'before-wrap',
                120: 'after-wrap',
                count - 1: 'end',
              }[tick]
            : <int, String>{
                0: 'start',
                32: 'blink',
                60: 'lift-start',
                78: 'lift-middle',
                102: 'mouth-contact',
                108: 'sip',
                145: 'lower-middle',
                168: 'rest',
                263: 'before-wrap',
                264: 'after-wrap',
                count - 1: 'end',
              }[tick];
        await tester.runAsync(() async {
          if (stamp == lastStamp && state == null) {
            await File(lastPath!).copy(path);
            return;
          }
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final full = await boundary.toImage(pixelRatio: 2);
          if (state != null) {
            final bytes = await full.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$folder/${friend.name}-$state-app.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          }
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawImageRect(
            full,
            Rect.fromLTWH(
              full.width * 100 / 853,
              full.height * 600 / 1844,
              full.width * 700 / 853,
              full.height * 660 / 1844,
            ),
            const Rect.fromLTWH(0, 0, 490, 462),
            Paint()..filterQuality = FilterQuality.medium,
          );
          final picture = recorder.endRecording();
          final crop = await picture.toImage(490, 462);
          final bytes = await crop.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          full.dispose();
          crop.dispose();
          picture.dispose();
        });
        samples.add({
          'frame': tick,
          'seconds': tick / 12,
          'from': from,
          'to': to,
          'blend': blend,
        });
        lastStamp = stamp;
        lastPath = path;
      }
      manifest.add({
        'friend': friend.name,
        'frames': count,
        'fps': 12,
        'seconds': count / 12,
        'source': 'fresh actual FocusFriendApp widget capture',
        'samples': samples,
      });
      expect(engine.state.history, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    File(
      '$folder/capture-manifest.json',
    ).writeAsStringSync(jsonEncode(manifest));
  });
}
