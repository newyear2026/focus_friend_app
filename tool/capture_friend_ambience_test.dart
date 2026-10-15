import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'capture all sixteen rooms and night focus/rest in the actual app',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (font, asset) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(font)..addFont(rootBundle.load(asset))).load();
      }
      final output = Directory('docs/design/friend-time-of-day-implementation')
        ..createSync(recursive: true);
      final hours = {
        RoomAmbience.morning: 7,
        RoomAmbience.day: 12,
        RoomAmbience.evening: 18,
        RoomAmbience.night: 22,
      };
      Future<void> save(RenderRepaintBoundary boundary, String name) async {
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${output.path}/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final friend in FocusFriend.values.where(
        (f) => f != FocusFriend.redpanda,
      )) {
        for (final ambience in RoomAmbience.values) {
          final now = DateTime(
            2026,
            10,
            15,
            hours[ambience]!,
          ).millisecondsSinceEpoch;
          final engine = SessionEngine(
            MemoryStore()..raw = FocusState(friend: friend).encode(),
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
            final context = tester.element(find.byType(DeskIllustration));
            for (final asset in [
              friend.ambienceAsset(ambience),
              if (friend.hasDeskMotion) '${friend.motionDirectory}/study.png',
            ]) {
              await precacheImage(AssetImage(asset), context);
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 2100));
          expect(tester.takeException(), isNull);
          await save(
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary,
            '${friend.name}-${ambience.assetName}-app',
          );
          await save(
            tester.renderObject(find.byKey(const ValueKey('study-scene'))),
            '${friend.name}-${ambience.assetName}-scene',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
        if (friend.hasDeskMotion) {
          for (final mode in [SessionMode.focus, SessionMode.rest]) {
            final now = DateTime(2026, 10, 15, 22).millisecondsSinceEpoch;
            final duration = (mode == SessionMode.focus ? 25 : 5) * 60000;
            final engine = SessionEngine(
              MemoryStore()
                ..raw = FocusState(
                  friend: friend,
                  active: Session(
                    id: 'ambience-capture',
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
                child: FocusFriendApp(
                  engine: engine,
                  locale: const Locale('ko'),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            await tester.runAsync(() async {
              final context = tester.element(find.byType(DeskIllustration));
              for (final asset in [
                friend.ambienceAsset(RoomAmbience.night),
                '${friend.motionDirectory}/study.png',
                '${friend.motionDirectory}/rest.png',
              ]) {
                await precacheImage(AssetImage(asset), context);
              }
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
            await save(
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary,
              '${friend.name}-night-${mode.name}-app',
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    },
  );
}
