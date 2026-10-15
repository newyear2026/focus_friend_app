import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/book_page_frame.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  for (final (name, size, scale) in [
    ('sheet', const Size(390, 844), 1.0),
    ('sheet-reference-size', const Size(426.5, 922), 1.0),
    ('sheet-compact-large-text', const Size(360, 740), 1.6),
    ('sheet-landscape', const Size(740, 360), 1.0),
  ]) {
    testWidgets('capture stop $name', (tester) async {
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
      var now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
      final store = MemoryStore()
        ..raw = FocusState(
          unlocks: {'plant': now - 1, 'mug': now - 1, 'lamp': now - 1},
        ).encode();
      final engine = SessionEngine(store, clock: () => now);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
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
        await precacheImage(
          const ExactAssetImage(
            BookPageFrame.asset,
            scale: BookPageFrame.assetScale,
          ),
          context,
        );
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('start-focus')));
      await tester.tap(find.byKey(const ValueKey('start-focus')));
      await tester.pumpAndSettle();
      now += 30000;
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.text('이번 시간 종료'));
      await tester.tap(find.text('이번 시간 종료'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/design/session-stop/book-frame')
          ..createSync(recursive: true);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        bitmap.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
