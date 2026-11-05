import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_style.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/update_news_sheet.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  Locale locale = const Locale('ko'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await (FontLoader(
    'Pretendard',
  )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDeskTheme(ThemeData(useMaterial3: true)),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showUpdateNewsSheet(context),
            child: const Text('Open news'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open news'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('both close actions dismiss the modal and return to the app', (
    tester,
  ) async {
    await _openSheet(tester);
    expect(find.text('작은 방이\n새로워졌어요'), findsOneWidget);
    expect(find.text('더 자연스러운 친구의 움직임'), findsOneWidget);
    expect(find.text('한눈에 보는 집중 기록'), findsOneWidget);
    expect(find.text('작은 오류를 고쳤어요'), findsOneWidget);
    expect(find.byTooltip('닫기'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('update-news-close')));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsNothing);
    expect(find.text('Open news').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Open news'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('update-news-done')));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsNothing);
    expect(find.text('Open news').hitTestable(), findsOneWidget);
  });

  testWidgets('outside tap and system back dismiss the announcement', (
    tester,
  ) async {
    await _openSheet(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsNothing);
    await tester.tap(find.text('Open news'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsNothing);
  });

  for (final locale in ['ko', 'en', 'ja', 'es']) {
    testWidgets('$locale remains usable on compact screens with large text', (
      tester,
    ) async {
      await _openSheet(
        tester,
        locale: Locale(locale),
        size: const Size(320, 568),
        textScale: 2,
      );
      final done = find.byKey(const ValueKey('update-news-done'));
      expect(done.hitTestable(), findsOneWidget);
      expect(tester.getRect(done).bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(UpdateNewsSheet)),
      );
      await tester.scrollUntilVisible(
        find.text(l10n.updateNewsFixesBody),
        150,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('update-news-content')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(l10n.updateNewsFixesBody).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.byType(UpdateNewsSheet), findsNothing);
    });
  }

  testWidgets('landscape keeps the action available while content scrolls', (
    tester,
  ) async {
    await _openSheet(tester, size: const Size(740, 360));
    expect(tester.takeException(), isNull);
    final done = find.byKey(const ValueKey('update-news-done'));
    expect(done.hitTestable(), findsOneWidget);
    expect(tester.getRect(done).bottom, lessThanOrEqualTo(360));
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsNothing);
  });
}
