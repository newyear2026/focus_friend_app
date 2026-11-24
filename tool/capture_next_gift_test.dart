import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/session_engine.dart';

import '../test/session_engine_test.dart' show MemoryStore;

// Uses the real app and artwork, with isolated in-memory focus data.
// flutter test --no-pub tool/capture_next_gift_test.dart
const _minute = 60000;

void main() {
  final now = DateTime(2026, 11, 19, 18).millisecondsSinceEpoch;
  FocusState afterFirst({Session? active}) => FocusState(
    completedMs: 25 * _minute,
    completedCount: 1,
    unlocks: {'plant': now},
    active: active,
  );
  final completed = Session(
    id: 'done',
    mode: SessionMode.focus,
    status: SessionStatus.completed,
    startedAt: now - 25 * _minute,
    durationMs: 25 * _minute,
    remainingMs: 0,
    actualMs: 25 * _minute,
    finishedAt: now,
    rewards: const ['plant'],
  );
  for (final (name, state, locale, size, scale, collection) in [
    ('home-new', FocusState(), 'ko', const Size(390, 844), 1.0, false),
    ('home-25', afterFirst(), 'ko', const Size(390, 844), 1.0, false),
    (
      'completed',
      afterFirst(active: completed),
      'ko',
      const Size(390, 844),
      1.0,
      false,
    ),
    ('collection', afterFirst(), 'ko', const Size(390, 844), 1.0, true),
    (
      'home-compact-large-text',
      afterFirst(),
      'ko',
      const Size(360, 740),
      1.6,
      false,
    ),
    (
      'home-compact-large-text-scrolled',
      afterFirst(),
      'ko',
      const Size(360, 740),
      1.6,
      false,
    ),
    ('home-en', afterFirst(), 'en', const Size(390, 844), 1.0, false),
    ('home-es', afterFirst(), 'es', const Size(360, 740), 1.0, false),
    ('home-ja', afterFirst(), 'ja', const Size(390, 844), 1.0, false),
  ]) {
    testWidgets('capture next gift $name', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (family, asset) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      }
      final store = MemoryStore()..raw = state.encode();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(
            engine: SessionEngine(store, clock: () => now),
            locale: Locale(locale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (collection) {
        await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('모은 소품'));
        await tester.tap(find.text('모은 소품'));
        await tester.pumpAndSettle();
      }
      if (name == 'home-compact-large-text-scrolled') {
        await tester.ensureVisible(find.byKey(const ValueKey('start-focus')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('start-focus')).hitTestable(),
          findsOneWidget,
        );
      }
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final asset in [
          'assets/images/immersive/room-evening.png',
          for (final item in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$item.png',
          ReferenceCompanion.asset,
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('docs/design/next-gift-progress-v1')
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
