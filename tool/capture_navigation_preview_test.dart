import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_home.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

// Capture the real navigation in an isolated store, without opening or changing
// the installed app's session, records or preferences.
void main() {
  testWidgets('capture illustrated navigation and its three destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1572);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final engine = SessionEngine(
      MemoryStore(),
      clock: () => DateTime(2026, 10, 8, 12).millisecondsSinceEpoch,
    );
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: FocusFriendApp(engine: engine),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DeskNavigation));
    await tester.runAsync(() async {
      for (final path in [
        'assets/images/storybook/room-day.png',
        'assets/images/redpanda-study-animation.png',
        'assets/images/navigation/desk.png',
        'assets/images/navigation/records.png',
        'assets/images/navigation/settings.png',
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('docs/design/navigation-implemented');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final (index, name, heading) in [
      (0, 'home', '나의 책상'),
      (2, 'records', '차곡차곡 기록'),
      (3, 'settings', '설정'),
    ]) {
      await tester.tap(find.byKey(ValueKey('desk-navigation-$index')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DeskNavigation>(find.byType(DeskNavigation))
            .selectedIndex,
        index,
      );
      expect(find.text(heading), findsWidgets);
      expect(tester.takeException(), isNull);
      await capture(name);
    }
    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(640, 1280);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await capture('compact-large-text');
    expect(tester.takeException(), isNull);
    for (var index = 0; index < 4; index++) {
      final rect = tester.getRect(
        find.byKey(ValueKey('desk-navigation-$index')),
      );
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(640));
    }
    expect(engine.state.active, isNull);
    expect(engine.state.history, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
