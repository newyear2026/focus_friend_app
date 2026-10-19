import 'dart:convert';
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
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'capture every current friend in focus and rest',
    (tester) async {
      const output = String.fromEnvironment(
        'ALL_MOTION_OUTPUT',
        defaultValue: 'docs/design/all-character-motions-v8/capture',
      );
      const fullStudyCycle = bool.fromEnvironment('ALL_MOTION_FULL_STUDY');
      final folder = Directory(output)..createSync(recursive: true);
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (font, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(font)..addFont(rootBundle.load(path))).load();
      }
      final manifest = <Map<String, Object>>[];
      for (final friend in FocusFriend.values) {
        for (final resting in [false, true]) {
          final staticScene = !resting && friend.hasWindowTeaMotion;
          final mode = resting ? SessionMode.rest : SessionMode.focus;
          final stem = '${friend.name}-${resting ? 'rest' : 'study'}';
          final fps = FriendMotionClock.framesPerSecond;
          final cycle = resting
              ? (friend == FocusFriend.redpanda
                    ? Duration(
                        microseconds:
                            RestAnimation.cycleTicks *
                            1000000 ~/
                            RestAnimation.framesPerSecond,
                      )
                    : FriendMotionClock.restDurationFor(friend))
              : (friend == FocusFriend.redpanda
                    ? Duration(
                        microseconds:
                            ReferenceStudyAnimation.cycleTicks *
                            1000000 ~/
                            ReferenceStudyAnimation.fps,
                      )
                    : FriendMotionClock.studyDuration);
          final start = resting || staticScene || fullStudyCycle
              ? Duration.zero
              : const Duration(milliseconds: 32400);
          final duration = staticScene
              ? Duration.zero
              : resting || fullStudyCycle
              ? cycle
              : cycle + const Duration(milliseconds: 3600) - start;
          final variants = resting && friend != FocusFriend.redpanda
              ? FriendMotionClock.restVariantsFor(friend)
              : <FriendRestVariant>[];
          // A non-integral supercycle (penguin: 268/12 seconds) rounds up
          // to microseconds in Duration. Do not ceil that into an extra tick.
          final count = staticScene
              ? 1
              : resting || fullStudyCycle
              ? (duration.inMicroseconds * fps / 1000000).round()
              : (duration.inMicroseconds * fps / 1000000).ceil();
          if (variants.isNotEmpty) {
            expect(
              count,
              variants.fold<int>(0, (sum, v) => sum + v.timeline.length),
              reason: 'capture the entire rest supercycle',
            );
          }
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          final now = DateTime(2026, 10, 15, 18).millisecondsSinceEpoch;
          final sessionMs = (resting ? 5 : 25) * 60000;
          final engine = SessionEngine(
            MemoryStore()
              ..raw = FocusState(
                friend: friend,
                active: Session(
                  id: 'all-friends-motion-fixture',
                  mode: mode,
                  status: SessionStatus.running,
                  startedAt: now,
                  durationMs: sessionMs,
                  remainingMs: sessionMs,
                  actualMs: 0,
                  endAt: now + sessionMs,
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
                    RoomAmbience.evening.asset,
                    if (resting) ...[
                      RestAnimation.asset,
                      RestAnimation.inbetweensAsset,
                      'assets/images/rest/closed-book.png',
                    ] else ...[
                      ReferenceStudyAnimation.bodyAsset,
                      ReferenceStudyAnimation.notebookAsset,
                    ],
                  ]
                : staticScene
                ? [friend.ambienceAsset(RoomAmbience.evening)]
                : [
                    friend.restRoomAsset(RoomAmbience.evening),
                    if (friend.hasDeskMotion)
                      '${friend.motionDirectory}/study.png',
                    if (resting) '${friend.motionDirectory}/rest.png',
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
          if (start > Duration.zero) await tester.pump(start);
          final frames = Directory('${folder.path}/frames/$stem')
            ..createSync(recursive: true);
          final samples = <Map<String, Object>>[];
          final seenPhases = <String>{};
          final stamps = <String>{};
          String? lastStamp, lastPath;
          var previousElapsed = Duration.zero;
          for (var tick = 0; tick < count; tick++) {
            final relative = Duration(
              microseconds: (tick * 1000000 / fps).ceil(),
            );
            if (tick > 0) await tester.pump(relative - previousElapsed);
            previousElapsed = relative;
            var phase = 'static';
            var stamp = 'static';
            final sample = <String, Object>{
              'frame': tick,
              'clipSeconds': tick / fps,
              'appSeconds': (start + relative).inMicroseconds / 1000000,
            };
            if (!staticScene) {
              if (friend == FocusFriend.redpanda && !resting) {
                final p =
                    tester
                            .widget<CustomPaint>(
                              find.byKey(
                                const ValueKey('reference-companion-cels'),
                              ),
                            )
                            .painter!
                        as ReferenceCompanionPainter;
                phase = p.turningPage ? 'pageTurn' : 'writing';
                stamp = '${p.frame}-${p.inkProgress}-$phase';
                sample.addAll({'cel': p.frame, 'ink': p.inkProgress});
              } else if (friend == FocusFriend.redpanda) {
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
                phase = 'tea';
                stamp = 'cel-${p.frame}';
                sample['cel'] = p.frame;
              } else {
                final p =
                    (tester
                                .widget<CustomPaint>(
                                  find.byKey(
                                    const ValueKey('friend-motion-cels'),
                                  ),
                                )
                                .painter!
                            as FriendMotionScenePainter)
                        .actor
                        .pose;
                phase = p.phase.name;
                stamp = '${p.from}-${p.to}-${p.blend}';
                sample.addAll({'from': p.from, 'to': p.to, 'blend': p.blend});
              }
            }
            if (variants.isNotEmpty) {
              var offset = 0;
              for (var i = 0; i < variants.length; i++) {
                final variant = variants[i];
                if (tick < offset + variant.timeline.length) {
                  sample['variant'] = i;
                  sample['action'] =
                      tick >= offset + variant.actionStartTick &&
                      tick < offset + variant.actionEndTick;
                  break;
                }
                offset += variant.timeline.length;
              }
            }
            sample['phase'] = phase;
            final firstPhase = seenPhases.add(phase);
            stamps.add(stamp);
            final path =
                '${frames.path}/${tick.toString().padLeft(4, '0')}.png';
            await tester.runAsync(() async {
              if (stamp == lastStamp && !firstPhase) {
                await File(lastPath!).copy(path);
                return;
              }
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final full = await boundary.toImage(pixelRatio: 2);
              if (tick == 0 || firstPhase) {
                final bytes = await full.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '${folder.path}/$stem-$phase-app.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
              }
              final recorder = ui.PictureRecorder();
              Canvas(recorder).drawImageRect(
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
              final bytes = await crop.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(path).writeAsBytes(bytes!.buffer.asUint8List());
              if (tick == 0) {
                await File(
                  '${folder.path}/$stem-poster.png',
                ).writeAsBytes(bytes.buffer.asUint8List());
              }
              full.dispose();
              crop.dispose();
              picture.dispose();
            });
            samples.add(sample);
            lastStamp = stamp;
            lastPath = path;
          }
          if (!resting && !staticScene) {
            expect(seenPhases, containsAll(['writing', 'pageTurn']));
            expect(stamps.length, greaterThan(2));
          } else if (!staticScene) {
            expect(stamps.length, greaterThan(2));
          }
          expect(tester.takeException(), isNull);
          expect(engine.state.history, isEmpty);
          manifest.add({
            'friend': friend.name,
            'mode': resting ? 'rest' : 'study',
            'static': staticScene,
            'fps': fps,
            'frames': count,
            'clipSeconds': count / fps,
            'appStartSeconds': start.inMicroseconds / 1000000,
            'cycleSeconds': cycle.inMicroseconds / 1000000,
            'phases': seenPhases.toList(),
            'source': 'fresh current FocusFriendApp widget capture',
            'fullStudyCycle': fullStudyCycle && !resting && !staticScene,
            if (variants.isNotEmpty)
              'variants': [
                for (final variant in variants)
                  {
                    'ticks': variant.timeline.length,
                    'actionStartTick': variant.actionStartTick,
                    'actionEndTick': variant.actionEndTick,
                  },
              ],
            'samples': samples,
          });
          File(
            '${folder.path}/manifest.json',
          ).writeAsStringSync(jsonEncode(manifest));
          debugPrint('Captured $stem: $count frames at $fps fps');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
