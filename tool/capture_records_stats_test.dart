import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import '../test/session_engine_test.dart' show MemoryStore;

/// Captures the records calendar, week and month tabs with sample totals.
/// Run: flutter test tool/capture_records_stats_test.dart
Session _done(DateTime start, int minutes) => Session(
  id: '${start.millisecondsSinceEpoch}',
  mode: SessionMode.focus,
  status: SessionStatus.completed,
  startedAt: start.millisecondsSinceEpoch,
  durationMs: minutes * 60000,
  remainingMs: 0,
  actualMs: minutes * 60000,
  finishedAt: start.millisecondsSinceEpoch + minutes * 60000,
);

FocusState _sample() {
  final days = <String, DailyFocus>{
    for (final (day, minutes) in [
      (1, 50),
      (2, 75),
      (3, 25),
      (4, 50),
      (5, 100),
      (6, 50),
      (8, 50),
      (9, 125),
      (12, 45),
      (13, 80),
      (15, 75),
    ])
      '2026-10-${day.toString().padLeft(2, '0')}': DailyFocus(
        milliseconds: minutes * 60000,
        count: (minutes / 25).ceil(),
      ),
    for (final (month, total) in [
      (5, 240),
      (6, 360),
      (7, 540),
      (8, 420),
      (9, 660),
    ])
      '2026-${month.toString().padLeft(2, '0')}-14': DailyFocus(
        milliseconds: total * 60000,
        count: total ~/ 25,
      ),
  };
  return FocusState(
    unlocks: {'plant': 1, 'mug': 1, 'lamp': 1},
    dailyFocus: days,
    history: [
      _done(DateTime(2026, 10, 15, 20, 0), 50),
      _done(DateTime(2026, 10, 15, 7, 0), 25),
      _done(DateTime(2026, 10, 13, 20, 30), 55),
      _done(DateTime(2026, 10, 13, 14, 0), 25),
      _done(DateTime(2026, 10, 12, 18, 0), 45),
    ],
  );
}

void main() {
  for (final (name, tab, size, scale, back) in [
    ('calendar', 'calendar', const Size(390, 844), 1.0, 0),
    ('week', 'week', const Size(390, 844), 1.0, 0),
    ('month', 'month', const Size(390, 844), 1.0, 0),
    ('week-compact-large-text', 'week', const Size(360, 740), 1.6, 0),
    // A past period shows the way back; the current one dims its next arrow.
    ('week-past', 'week', const Size(390, 844), 1.0, 1),
    ('month-past-large-text', 'month', const Size(360, 740), 1.6, 1),
  ]) {
    testWidgets('capture records $name', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
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
      final now = DateTime(2026, 10, 15, 22).millisecondsSinceEpoch;
      final store = MemoryStore()..raw = _sample().encode();
      final engine = SessionEngine(store, clock: () => now);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/companion-portrait.png'),
          context,
        ),
      );
      await tester.tap(find.byKey(ValueKey('records-tab-$tab')));
      await tester.pumpAndSettle();
      for (var i = 0; i < back; i++) {
        await tester.tap(find.byKey(ValueKey('previous-$tab')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/design/records-stats')
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
