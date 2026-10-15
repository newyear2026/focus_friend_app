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
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'capture active focus, page turn, pause and tea in the actual app',
    (tester) async {
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
      final now = DateTime(2026, 10, 15, 18).millisecondsSinceEpoch;
      for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
        for (final mode in [SessionMode.focus, SessionMode.rest]) {
          final duration = (mode == SessionMode.rest ? 5 : 25) * 60000;
          final engine = SessionEngine(
            MemoryStore()
              ..raw = FocusState(
                friend: friend,
                active: Session(
                  id: 'motion-capture',
                  mode: mode,
                  status: SessionStatus.running,
                  startedAt: now,
                  durationMs: duration,
                  remainingMs: duration,
                  actualMs: 0,
                  endAt: now + duration,
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
          await tester.pump(const Duration(milliseconds: 200));
          await tester.runAsync(() async {
            final context = tester.element(find.byType(RoomScreen));
            for (final name in [
              'room',
              'study',
              if (mode == SessionMode.rest) 'rest',
            ]) {
              await precacheImage(
                AssetImage('${friend.motionDirectory}/$name.png'),
                context,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();
          FriendMotionPose pose() =>
              (tester
                          .widget<CustomPaint>(
                            find.byKey(const ValueKey('friend-motion-cels')),
                          )
                          .painter!
                      as FriendMotionScenePainter)
                  .actor
                  .pose;
          Future<void> capture(String action) async {
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'docs/design/penguin-otter-motion-v1/${friend.name}-$action-app.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await tester.pump(const Duration(milliseconds: 1800));
          await capture(mode == SessionMode.focus ? 'focus' : 'rest');
          if (mode == SessionMode.focus) {
            await tester.pump(const Duration(milliseconds: 37700));
            expect(pose().phase, FriendMotionPhase.pageTurn);
            await capture('page');
            await tester.tap(find.text('잠시 멈추기'));
            await tester.pump(const Duration(milliseconds: 100));
            final held = (pose().from, pose().to, pose().blend);
            await tester.pump(const Duration(seconds: 2));
            expect((pose().from, pose().to, pose().blend), held);
            await capture('paused');
          } else {
            await tester.pump(const Duration(milliseconds: 5700));
            expect(pose().phase, FriendMotionPhase.tea);
            await capture('sip');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
