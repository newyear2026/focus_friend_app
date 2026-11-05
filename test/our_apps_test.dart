import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_style.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/our_apps_screen.dart';
import 'package:focus_friend_app/session_engine.dart';

import 'session_engine_test.dart' show MemoryStore;

const _packages = [
  'com.dayround.app',
  'com.sobra.app.sobra_app',
  'com.randomfocus.app',
  'com.casewen.multi_calc',
];

Future<void> _configure(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  for (final (family, asset) in [
    ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

Future<void> _show(
  WidgetTester tester, {
  required Future<bool> Function(String) opener,
  String language = 'ko',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDeskTheme(ThemeData(useMaterial3: true)),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OurAppsScreen(openListing: opener),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Finder> _button(WidgetTester tester, String package) async {
  final target = find.byKey(ValueKey('our-app-open-$package'));
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  return target;
}

void main() {
  testWidgets('settings opens the collection and back preserves focus data', (
    tester,
  ) async {
    await _configure(tester);
    final store = MemoryStore();
    await tester.pumpWidget(
      FocusFriendApp(engine: SessionEngine(store), locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('open-our-apps'));
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(entry), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(OurAppsScreen), findsOneWidget);
    expect(find.text('LOOPET'), findsOneWidget);
    expect(find.text('Sobrita'), findsOneWidget);
    expect(find.text('RandomFocus'), findsOneWidget);
    expect(find.text('MultiCal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desk-navigation-3')).hitTestable(),
      findsNothing,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(OurAppsScreen), findsNothing);
    expect(entry.hitTestable(), findsOneWidget);
    expect(store.commits, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every store button opens its own exact package once', (
    tester,
  ) async {
    await _configure(tester);
    final semantics = tester.ensureSemantics();
    try {
      final opened = <String>[];
      await _show(
        tester,
        opener: (package) async {
          opened.add(package);
          return true;
        },
      );
      final left = tester.getTopLeft(
        find.byKey(ValueKey('our-app-card-${_packages[0]}')),
      );
      final right = tester.getTopLeft(
        find.byKey(ValueKey('our-app-card-${_packages[1]}')),
      );
      expect(left.dy, closeTo(right.dy, .1));
      expect(right.dx, greaterThan(left.dx));
      for (final package in _packages) {
        final target = await _button(tester, package);
        final name = [
          'LOOPET',
          'Sobrita',
          'RandomFocus',
          'MultiCal',
        ][_packages.indexOf(package)];
        expect(tester.getSemantics(target).label, contains(name));
        await tester.tap(target);
        await tester.pumpAndSettle();
      }
      expect(opened, _packages);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('an unavailable store reports failure and can retry', (
    tester,
  ) async {
    await _configure(tester);
    final pending = Completer<bool>();
    var calls = 0;
    await _show(
      tester,
      opener: (_) {
        calls++;
        return calls == 1 ? pending.future : Future.value(true);
      },
    );
    final button = await _button(tester, _packages.first);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a store request after leaving the page is safe', (
    tester,
  ) async {
    await _configure(tester);
    final pending = Completer<bool>();
    await _show(tester, opener: (_) => pending.future);
    await tester.tap(await _button(tester, _packages.first));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ko', 'en', 'ja', 'es']) {
    testWidgets('$language supports compact screens with doubled text', (
      tester,
    ) async {
      await _configure(tester, size: const Size(320, 568), scale: 2);
      final opened = <String>[];
      await _show(
        tester,
        language: language,
        opener: (package) async {
          opened.add(package);
          return true;
        },
      );
      for (final package in _packages) {
        await tester.tap(await _button(tester, package));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language $package');
      }
      expect(opened, _packages);
    });
  }
}
