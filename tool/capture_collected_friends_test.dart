import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_props.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/localized_names.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/study_scene.dart';
import '../test/companion_art.dart' show precacheCompanionArt;
import '../test/widget_test.dart' show loadAppFont;

void main() {
  testWidgets('capture shared collection in every real room', (tester) async {
    tester.view.physicalSize = const Size(1160, 1040);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await loadAppFont();
    final key = GlobalKey();
    final output = Directory('docs/design/shared-collected-props-v1')
      ..createSync(recursive: true);
    for (final ambience in [RoomAmbience.day, RoomAmbience.night]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Pretendard'),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFFFF8E9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Column(
                        children: [
                          Text(
                            '모든 친구와 함께 모은 소품 · ${ambienceName(l10n, ambience)}',
                            style: const TextStyle(fontSize: 27),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final friend in FocusFriend.values)
                                Expanded(
                                  child: Text(
                                    friendName(l10n, friend),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                            ],
                          ),
                          for (final (label, unlocks, rest) in [
                            ('처음 시작 · 기본 조명', <String>{}, false),
                            ('첫 집중 완료 · 화분', {'plant'}, false),
                            ('누적 60분 완료 · 머그컵', {'plant', 'mug'}, false),
                            ('휴식 · 모은 화분과 찻잔 동작', {'plant', 'mug'}, true),
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(label),
                              ),
                            ),
                            Row(
                              children: [
                                for (final friend in FocusFriend.values)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: SizedBox(
                                        height: 176,
                                        child: DeskIllustration(
                                          friend: friend,
                                          unlocked: unlocks,
                                          ambience: ambience,
                                          resting: rest,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await precacheCompanionArt(tester);
      final context = tester.element(find.byType(DeskIllustration).first);
      await tester.runAsync(() async {
        for (final asset in [
          ambience.asset,
          'assets/images/rest/closed-book.png',
          for (final prop in deskProps) prop.asset,
          for (final prop in deskProps) prop.sceneAsset(ambience),
          for (final friend in FocusFriend.values.skip(1)) ...[
            friend.restRoomAsset(ambience),
            '${friend.motionDirectory}/study.png',
            '${friend.motionDirectory}/rest.png',
          ],
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${ambience.name}-overview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
