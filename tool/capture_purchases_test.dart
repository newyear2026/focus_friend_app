import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/friend_picker.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/purchase_sheet.dart';
import 'package:focus_friend_app/session_engine.dart';

import '../test/purchases_test.dart' show FakePurchases;
import '../test/session_engine_test.dart' show MemoryStore;

// Renders the purchase screens with made-up prices; no Google Play involved.
// flutter test tool/capture_purchases_test.dart
void main() {
  const outputPath = String.fromEnvironment(
    'PURCHASE_CAPTURE_OUTPUT',
    defaultValue: 'docs/design/purchases-v1',
  );
  const language = String.fromEnvironment(
    'PURCHASE_CAPTURE_LANGUAGE',
    defaultValue: 'ko',
  );
  testWidgets('capture friend picker, locked preview, bundle and settings', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final (font, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font)..addFont(rootBundle.load(path))).load();
    }
    final appKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: appKey,
        child: FocusFriendApp(
          engine: SessionEngine(MemoryStore()),
          purchases: FakePurchases(),
          locale: const Locale(language),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    final assets = RegExp(r'^\s+- (assets/images/\S+\.png)$', multiLine: true)
        .allMatches(File('pubspec.yaml').readAsStringSync())
        .map((m) => m.group(1)!);
    await tester.runAsync(() async {
      for (final asset in assets) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    final output = Directory(outputPath)..createSync(recursive: true);
    Future<void> settle() async {
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shot(String name) async {
      await settle();
      expect(tester.takeException(), isNull);
      final boundary =
          appKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/$language-$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
    await shot('1-friends');
    await tester.tap(find.byKey(const ValueKey('friend-card-otter')));
    await tester.tap(find.byKey(const ValueKey('friend-preview')));
    await shot('2-locked-preview');
    await tester.tap(find.byKey(const ValueKey('friend-open-bundle')));
    await shot('3-bundle');
    Navigator.of(tester.element(find.byType(BundleSheet))).pop();
    await settle();
    Navigator.of(tester.element(find.byType(FriendPreview))).pop();
    await settle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await settle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restore-purchases')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await shot('4-settings');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
