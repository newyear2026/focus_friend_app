import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

const output = 'docs/design/fennec-squirrel-window-tea-v1';
Future<ui.Image> decode(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return image;
}

Future<void> save(ui.Image image, String path) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$output/$path.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
}

void main() {
  testWidgets(
    'capture window tea in the actual Flutter app for all four periods',
    (tester) async {
      Directory(output).createSync(recursive: true);
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final (font, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(font)..addFont(rootBundle.load(path))).load();
      }
      for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
        for (final (period, hour) in [
          (RoomAmbience.morning, 7),
          (RoomAmbience.day, 12),
          (RoomAmbience.evening, 18),
          (RoomAmbience.night, 22),
        ]) {
          final now = DateTime(2026, 10, 15, hour).millisecondsSinceEpoch;
          final engine = SessionEngine(
            MemoryStore()
              ..raw = FocusState(
                friend: friend,
                active: Session(
                  id: 'window-tea-capture',
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
            for (final asset in [
              friend.restRoomAsset(period),
              '${friend.motionDirectory}/rest.png',
            ]) {
              await precacheImage(AssetImage(asset), context);
            }
          });
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          Future<void> capture(String name) async {
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await save(await boundary.toImage(pixelRatio: 2), name);
            });
          }

          await capture('${friend.name}-${period.assetName}-app');
          if (period ==
              (friend == FocusFriend.fennec
                  ? RoomAmbience.evening
                  : RoomAmbience.day)) {
            await tester.pump(const Duration(milliseconds: 11500));
            await capture('${friend.name}-sip-app');
            await tester.tap(find.text('잠시 멈추기'));
            await tester.pump(const Duration(milliseconds: 200));
            await capture('${friend.name}-paused-app');
          }
          expect(engine.state.history, isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
  testWidgets(
    'render a complete 22 second window tea loop with production painters',
    (tester) async {
      await tester.runAsync(() async {
        for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
          final ambience = friend == FocusFriend.fennec
              ? RoomAmbience.evening
              : RoomAmbience.day;
          final room = await decode(friend.restRoomAsset(ambience));
          final rest = await decode('${friend.motionDirectory}/rest.png');
          Future<void> render(
            String name,
            Duration elapsed, {
            bool crop = false,
          }) async {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            if (crop) {
              canvas.scale(.7);
              canvas.translate(-100, -600);
            }
            FriendMotionScenePainter(
              room: room,
              ambience: ambience,
              actor: FriendMotionPainter(
                friend: friend,
                study: null,
                rest: rest,
                pose: FriendMotionClock.sample(
                  elapsed,
                  resting: true,
                  friend: friend,
                ),
              ),
            ).paint(canvas, const Size(853, 1844));
            final picture = recorder.endRecording();
            await save(
              await picture.toImage(crop ? 490 : 853, crop ? 462 : 1844),
              name,
            );
            picture.dispose();
          }

          for (final second in [0, 6, 9, 10, 11, 12, 13, 14, 15, 16, 21]) {
            await render(
              '${friend.name}-pose-$second',
              Duration(seconds: second),
              crop: true,
            );
          }
          if (Platform.environment['WINDOW_TEA_VIDEO'] == '1') {
            for (var frame = 0; frame < 264; frame++) {
              await render(
                'frames/${friend.name}/${frame.toString().padLeft(4, '0')}',
                Duration(microseconds: (frame * 1000000 / 12).round()),
                crop: true,
              );
            }
          }
          room.dispose();
          rest.dispose();
        }
      });
    },
  );
}
