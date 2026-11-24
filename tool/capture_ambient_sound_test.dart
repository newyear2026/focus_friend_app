import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_preferences.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/session_engine.dart';

import '../test/session_engine_test.dart' show MemoryStore;

// Base screens for the ambient sound mockup (docs/design/ambient-sound-v1).
// Real app and artwork at 22:00, isolated in-memory focus data.
// flutter test --no-pub tool/capture_ambient_sound_test.dart
const _minute = 60000;

void main() {
  final now = DateTime(2026, 11, 23, 22).millisecondsSinceEpoch;
  FocusState state({Session? active}) => FocusState(
    completedMs: 95 * _minute,
    completedCount: 4,
    unlocks: {'plant': now - 3, 'mug': now - 2, 'lamp': now - 1},
    sound: const SoundPreferences(enabled: true),
    active: active,
  );
  final running = Session(
    id: 'ambient-capture',
    mode: SessionMode.focus,
    status: SessionStatus.running,
    startedAt: now - 7 * _minute,
    durationMs: 25 * _minute,
    remainingMs: 18 * _minute,
    actualMs: 7 * _minute,
    endAt: now + 18 * _minute,
    segmentAt: now,
  );
  for (final (name, focusState, openSound) in [
    ('night-home', state(), false),
    ('night-focus', state(active: running), false),
    ('night-sound-sheet', state(), true),
  ]) {
    testWidgets('capture ambient sound $name', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (family, asset) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      }
      final store = MemoryStore()..raw = focusState.encode();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(
            engine: SessionEngine(store, clock: () => now),
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final asset in [
          'assets/images/immersive/room-night.png',
          for (final item in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$item.png',
          for (final id in ['rain', 'forest', 'fire'])
            'assets/images/sound-$id.png',
          ReferenceCompanion.asset,
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));
      if (openSound) {
        await tester.tap(find.byKey(const ValueKey('open-sound')));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('docs/design/ambient-sound-v1/base')
          ..createSync(recursive: true);
        await File(
          '${out.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
