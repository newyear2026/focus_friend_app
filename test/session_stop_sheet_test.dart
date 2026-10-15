import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/book_page_frame.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/session_stop_sheet.dart';
import 'session_engine_test.dart' show MemoryStore;

Future<SessionEngine> showStopSheet(
  WidgetTester tester, {
  SessionMode mode = SessionMode.focus,
  Locale locale = const Locale('ko'),
  double textScale = 1,
  int Function()? clock,
  Size size = const Size(360, 740),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await (FontLoader(
    'Pretendard',
  )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
  final engine = SessionEngine(
    MemoryStore(),
    clock: clock ?? () => DateTime(2026, 10, 14, 18).millisecondsSinceEpoch,
  );
  await engine.restore();
  await engine.start(const Duration(minutes: 25), mode: mode);
  await tester.pumpWidget(FocusFriendApp(engine: engine, locale: locale));
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => precacheImage(
      const ExactAssetImage(
        BookPageFrame.asset,
        scale: BookPageFrame.assetScale,
      ),
      tester.element(find.byType(Scaffold).first),
    ),
  );
  final l10n = AppLocalizations.of(tester.element(find.byType(RoomScreen)));
  await tester.ensureVisible(find.text(l10n.endThisSession));
  await tester.tap(find.text(l10n.endThisSession));
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('landscape keeps both actions fully visible inside the frame', (
    tester,
  ) async {
    final engine = await showStopSheet(tester, size: const Size(740, 360));
    for (final key in ['continue-session', 'confirm-stop-session']) {
      final finder = find.byKey(ValueKey(key));
      final bounds = tester.getRect(finder);
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThanOrEqualTo(360));
      expect(finder.hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('confirm-stop-session')));
    await tester.pumpAndSettle();
    expect(engine.state.active, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('continue dismisses the sheet without changing the session', (
    tester,
  ) async {
    final engine = await showStopSheet(tester);
    final before = engine.state.encode();
    expect(find.byType(SessionStopSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('continue-session')));
    await tester.pumpAndSettle();
    expect(find.byType(SessionStopSheet), findsNothing);
    expect(engine.state.encode(), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'confirming stop records elapsed focus without granting rewards',
    (tester) async {
      var now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
      final engine = await showStopSheet(tester, clock: () => now);
      now += 30000;
      await tester.tap(find.byKey(const ValueKey('confirm-stop-session')));
      await tester.pumpAndSettle();
      expect(engine.state.active, isNull);
      expect(engine.state.history, hasLength(1));
      expect(engine.state.history.single.status, SessionStatus.stopped);
      expect(engine.state.history.single.actualMs, 30000);
      expect(engine.state.completedMs, 0);
      expect(engine.state.unlocks, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('outside tap, downward swipe and back keep the session running', (
    tester,
  ) async {
    final engine = await showStopSheet(tester);
    final before = engine.state.encode();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(SessionStopSheet), findsNothing);
    expect(engine.state.encode(), before);
    await tester.tap(find.text('이번 시간 종료'));
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(BottomSheet));
    await tester.dragFrom(Offset(180, top.dy + 10), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byType(SessionStopSheet), findsNothing);
    expect(engine.state.encode(), before);
    await tester.tap(find.text('이번 시간 종료'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SessionStopSheet), findsNothing);
    expect(engine.state.encode(), before);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('deadline reached in the sheet still completes exactly once', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
    final engine = await showStopSheet(tester, clock: () => now);
    now += 25 * 60000;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.completed);
    await tester.tap(find.byKey(const ValueKey('confirm-stop-session')));
    await tester.pumpAndSettle();
    expect(engine.state.active!.status, SessionStatus.completed);
    expect(engine.state.completedCount, 1);
    expect(engine.state.history, hasLength(1));
    expect(engine.state.history.single.status, SessionStatus.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final mode in [SessionMode.demo, SessionMode.rest]) {
    testWidgets('${mode.name} explains its record policy and stays isolated', (
      tester,
    ) async {
      final engine = await showStopSheet(tester, mode: mode);
      expect(find.text('체험과 휴식은 집중 기록에 남지 않아요.'), findsOneWidget);
      expect(find.text('소품 해금 시간에는 더하지 않아요.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('confirm-stop-session')));
      await tester.pumpAndSettle();
      expect(engine.state.active, isNull);
      expect(engine.state.history, isEmpty);
      expect(engine.state.unlocks, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final locale in ['ko', 'en', 'es', 'ja']) {
    testWidgets('$locale sheet keeps both actions reachable with large text', (
      tester,
    ) async {
      final engine = await showStopSheet(
        tester,
        locale: Locale(locale),
        textScale: 1.6,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('continue-session')),
      );
      expect(
        find.byKey(const ValueKey('continue-session')).hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('confirm-stop-session')),
      );
      expect(
        find.byKey(const ValueKey('confirm-stop-session')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('confirm-stop-session')));
      await tester.pumpAndSettle();
      expect(engine.state.active, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
