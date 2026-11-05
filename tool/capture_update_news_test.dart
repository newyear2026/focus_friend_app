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
import 'package:focus_friend_app/update_news_sheet.dart';

import '../test/session_engine_test.dart' show MemoryStore;

// Uses the real app and artwork, with isolated in-memory focus data.
// flutter test --no-pub tool/capture_update_news_test.dart
void main() {
  for (final (name, size, scale) in [
    ('sheet-reference-size', const Size(390, 800), 1.0),
    ('sheet', const Size(390, 844), 1.0),
    ('sheet-compact-large-text', const Size(360, 740), 1.6),
    ('sheet-landscape', const Size(740, 360), 1.0),
  ]) {
    testWidgets('capture update news $name', (tester) async {
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
      final now = DateTime(2026, 11, 5, 18).millisecondsSinceEpoch;
      final store = MemoryStore()
        ..raw = FocusState(
          unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
        ).encode();
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
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final asset in [
          'assets/images/immersive/room-evening.png',
          for (final item in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$item.png',
          ReferenceCompanion.asset,
          ReferenceStudyAnimation.bodyAsset,
          ReferenceStudyAnimation.notebookAsset,
          'assets/images/companion-portrait.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      showUpdateNewsSheet(context);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('update-news-done')).hitTestable(),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('docs/design/update-news-v1')
          ..createSync(recursive: true);
        await File(
          '${out.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
      await tester.tap(find.byKey(const ValueKey('update-news-done')));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateNewsSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
