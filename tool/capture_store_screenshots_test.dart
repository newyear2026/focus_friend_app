// Capture the current localized app for store artwork with an isolated store.
// This never opens an installed app or its database.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  const language = String.fromEnvironment(
    'STORE_SCREENSHOT_LOCALE',
    defaultValue: 'ko',
  );
  const captureDate = String.fromEnvironment(
    'STORE_SCREENSHOT_DATE',
    defaultValue: '2026-10-15',
  );
  final anchor = DateTime.parse(captureDate);
  testWidgets('capture current $language app for six store screenshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1400);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final (font, path) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font)..addFont(rootBundle.load(path))).load();
    }
    final output = Directory('deliverables/store_screenshots/$language/sources')
      ..createSync(recursive: true);
    int atHour(int hour) => DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      hour,
    ).millisecondsSinceEpoch;
    var now = atHour(18);
    final daily = <String, DailyFocus>{};
    final sessions = <Session>[];
    // Plausible demonstration data, anchored to the user's current date.
    final days = {
      2,
      3,
      5,
      6,
      8,
      9,
      11,
      12,
      13,
      14,
      15,
      anchor.day,
    }.where((day) => day <= anchor.day).toList()..sort();
    for (final day in days) {
      final count = day == anchor.day ? 2 : (day.isEven ? 2 : 1);
      daily[calendarKey(DateTime(anchor.year, anchor.month, day))] = DailyFocus(
        milliseconds: count * 25 * 60000,
        count: count,
      );
      for (var index = 0; index < count; index++) {
        final end = DateTime(
          anchor.year,
          anchor.month,
          day,
          10 + index,
          25,
        ).millisecondsSinceEpoch;
        sessions.add(
          Session(
            id: 'store-demo-$day-$index',
            mode: SessionMode.focus,
            status: SessionStatus.completed,
            startedAt: end - 25 * 60000,
            durationMs: 25 * 60000,
            remainingMs: 0,
            actualMs: 25 * 60000,
            finishedAt: end,
          ),
        );
      }
    }
    final engine = SessionEngine(
      MemoryStore()
        ..raw = FocusState(
          completedMs: sessions.length * 25 * 60000,
          completedCount: sessions.length,
          dailyFocus: daily,
          history: sessions.reversed.toList(),
          unlocks: {'plant': now - 3, 'mug': now - 2, 'lamp': now - 1},
          sound: const SoundPreferences(enabled: true),
        ).encode(),
      clock: () => now,
    );
    await engine.restore();
    final key = GlobalKey();
    Future<void> mount() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: Locale(language)),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(DeskIllustration));
      await tester.runAsync(() async {
        // Capture the same real assets as the production widgets use.
        for (final asset in [
          for (final period in ['morning', 'day', 'evening', 'night'])
            'assets/images/immersive/room-$period.png',
          'assets/images/immersive/redpanda-slow-connected-body-38.png',
          'assets/images/immersive/redpanda-fixed-notebook.png',
          'assets/images/immersive/redpanda-reference.png',
          for (final prop in ['plant', 'mug', 'lamp'])
            'assets/images/immersive/reward-$prop.png',
          'assets/images/companion-portrait.png',
          for (final sound in ['rain', 'forest', 'fire'])
            'assets/images/sound-$sound.png',
          'assets/images/friends/ambience/fennec/evening.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await mount();
    final l10n = AppLocalizations.of(tester.element(find.byType(RoomScreen)));
    await capture('redpanda-home');
    await tester.tap(find.byKey(const ValueKey('start-focus')));
    await capture('redpanda-focus');
    await engine.stop(engine.state.active!.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount();

    await tester.tap(find.byKey(const ValueKey('desk-navigation-1')));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(RoomScreen));
      for (final friend in FocusFriend.values) {
        if (friend.sceneAsset != null) {
          await precacheImage(AssetImage(friend.sceneAsset!), context);
        }
      }
    });
    await capture('friends');
    await tester.tap(find.byKey(const ValueKey('desk-navigation-0')));
    for (final (hour, period) in [
      (7, 'morning'),
      (12, 'day'),
      (18, 'evening'),
      (22, 'night'),
    ]) {
      now = atHour(hour);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 3));
      await capture('room-$period');
    }
    now = atHour(18);
    await tester.pump(const Duration(minutes: 1));
    await tester.tap(find.byKey(const ValueKey('open-sound')));
    await capture('sound');
    await tester.tap(find.byTooltip(l10n.close));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desk-navigation-2')));
    await capture('records');
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    tester.view.physicalSize = const Size(780, 1500);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text(l10n.collectionTitle)),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.collectionTitle).hitTestable(), findsOneWidget);
    await tester.tap(find.text(l10n.collectionTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.collectionHeading), findsOneWidget);
    await capture('collection');
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(780, 1400);
    await engine.saveFriend(FocusFriend.fennec);
    await mount();
    await capture('fennec-home');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
