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
  testWidgets('capture full rooms with lamps off by day and on at night', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1160, 1180);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await loadAppFont();

    final boundaryKey = GlobalKey();
    final output = Directory('docs/design/daylight-lamps-v1')
      ..createSync(recursive: true);
    for (final (stem, title, periods) in [
      (
        'daylight',
        '아침과 낮 · 자연광으로 밝은 방',
        [RoomAmbience.morning, RoomAmbience.day],
      ),
      (
        'evening',
        '저녁과 밤 · 조명을 켠 방',
        [RoomAmbience.evening, RoomAmbience.night],
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Pretendard'),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
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
                            title,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
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
                          for (final ambience in periods) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${ambienceName(l10n, ambience)} · '
                                  '${ambience.lampsOn ? '조명 켜짐' : '조명 꺼짐'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final friend in FocusFriend.values)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: AspectRatio(
                                        // Preserve the entire room so upper
                                        // shelf lanterns remain in the frame.
                                        aspectRatio: 853 / 1844,
                                        child: DeskIllustration(
                                          friend: friend,
                                          unlocked: const {'plant', 'mug'},
                                          ambience: ambience,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Text(
                            '현재 앱의 실제 렌더링 · 같은 수집 상태로 비교',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF77665C),
                            ),
                          ),
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
        for (final asset in {
          for (final ambience in periods) ...[
            ambience.asset,
            for (final prop in deskProps) prop.sceneAsset(ambience),
            for (final friend in FocusFriend.values.skip(1)) ...[
              friend.restRoomAsset(ambience),
              '${friend.motionDirectory}/study.png',
            ],
          ],
        }) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(DeskIllustration), findsNWidgets(10));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/$stem-overview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
