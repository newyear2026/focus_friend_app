import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_style.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/our_apps_screen.dart';
import 'package:focus_friend_app/session_engine.dart';

import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  for (final (name, size, scale, language) in [
    ('collection', const Size(390, 844), 1.0, 'ko'),
    ('collection-compact', const Size(320, 568), 1.0, 'ko'),
    ('collection-large-text', const Size(360, 740), 1.6, 'ko'),
    ('collection-landscape', const Size(740, 360), 1.0, 'ko'),
    ('collection-en', const Size(390, 844), 1.0, 'en'),
    ('settings-entry', const Size(390, 844), 1.0, 'ko'),
  ]) {
    testWidgets('capture $name', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final (family, path) in [
        ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(path))).load();
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: name == 'settings-entry'
              ? FocusFriendApp(
                  engine: SessionEngine(MemoryStore()),
                  locale: const Locale('ko'),
                )
              : MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildDeskTheme(ThemeData(useMaterial3: true)),
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: OurAppsScreen(openListing: (_) async => true),
                ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final name in ['loopet', 'sobrita', 'randomfocus', 'multical']) {
          await precacheImage(AssetImage('assets/apps/$name.png'), context);
        }
      });
      if (name == 'settings-entry') {
        await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
        await tester.pumpAndSettle();
        final target = find.byKey(const ValueKey('open-our-apps'));
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final out = Directory('docs/design/recommended-apps-v1')
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
