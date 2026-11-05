import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/update_news.dart';
import 'package:focus_friend_app/update_news_sheet.dart';

import '../test/session_engine_test.dart' show MemoryStore;

void main() {
  // Native preferences are tested only in the separate verification package.
  if (!const bool.fromEnvironment('FOCUS_FRIEND_VERIFICATION')) {
    throw StateError('Use --dart-define=FOCUS_FRIEND_VERIFICATION=true');
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android build detection, durable read marker and settings', (
    tester,
  ) async {
    final store = AndroidUpdateNewsStore();
    final installed = await store.load();
    expect(installed.currentBuild, greaterThan(0));

    final news = UpdateNews(store);
    await news.prepare();
    expect(news.pending, installed.shouldShow);
    await news.acknowledge();
    final reopened = await AndroidUpdateNewsStore().load();
    expect(
      reopened.lastAcknowledgedBuild,
      greaterThanOrEqualTo(installed.currentBuild),
    );
    final nextLaunch = UpdateNews(AndroidUpdateNewsStore());
    await nextLaunch.prepare();
    expect(nextLaunch.pending, isFalse);

    final now = DateTime(2026, 11, 5, 18).millisecondsSinceEpoch;
    final engine = SessionEngine(MemoryStore(), clock: () => now);
    await tester.pumpWidget(
      FocusFriendApp(
        engine: engine,
        updateNews: nextLaunch,
        locale: const Locale('ko'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(UpdateNewsSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-update-news')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('open-update-news'))),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-update-news')));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateNewsSheet), findsOneWidget);
    expect(find.text('작은 방이\n새로워졌어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('update-news-done')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(UpdateNewsSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('start-focus')).hitTestable(),
      findsOneWidget,
    );
    expect(engine.state.active, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
