// Audit fixtures for current production widgets; deliberately hold an uncached
// rest atlas to inspect what a first mode change displays while it loads.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_style.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';
import 'package:focus_friend_app/friend_picker.dart';
import 'package:focus_friend_app/l10n/app_localizations.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/study_scene.dart';

class HeldRestBundle extends CachingAssetBundle {
  HeldRestBundle(this.rest);
  final String rest;
  final gate = Completer<ByteData>();
  @override
  Future<ByteData> load(String key) =>
      key == rest ? gate.future : rootBundle.load(key);
}

void main() {
  testWidgets('capture cold rest switch and friend preview scope', (
    tester,
  ) async {
    final folder = Directory('docs/design/motion-quality-audit-v2/fixtures')
      ..createSync(recursive: true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (family, asset) in [
      ('Pretendard', 'assets/fonts/PretendardVariable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
    final report = <Map<String, Object>>[];
    for (final friend in [FocusFriend.fennec, FocusFriend.squirrel]) {
      final bundle = HeldRestBundle('${friend.motionDirectory}/rest.png');
      final key = GlobalKey();
      var resting = false;
      Widget harness({bool preview = false}) => DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(
          theme: buildDeskTheme(ThemeData(useMaterial3: true)),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: key,
            child: preview
                ? FriendPreview(
                    friend: friend,
                    unlocked: const {},
                    onApply: () async {},
                  )
                : DeskIllustration(
                    friend: friend,
                    unlocked: const {},
                    ambience: RoomAmbience.night,
                    studying: !resting,
                    resting: resting,
                    animate: false,
                  ),
          ),
        ),
      );
      Future<void> snapshot(String name) => tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${folder.path}/${friend.name}-$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(harness());
      final context = tester.element(find.byType(DeskIllustration));
      await tester.runAsync(() async {
        for (final asset in [
          friend.sceneAsset!,
          friend.restRoomAsset(RoomAmbience.night),
          '${friend.motionDirectory}/study.png',
        ]) {
          await precacheImage(AssetImage(asset, bundle: bundle), context);
        }
      });
      await tester.pump();
      expect(find.byKey(const ValueKey('friend-motion-cels')), findsOneWidget);
      await snapshot('01-night-focus');
      resting = true;
      await tester.pumpWidget(harness());
      final fallback = tester.widget<Image>(
        find.descendant(
          of: find.byType(FriendMotionScene),
          matching: find.byType(Image),
        ),
      );
      expect((fallback.image as AssetImage).assetName, friend.sceneAsset);
      await snapshot('02-rest-loading');
      await tester.runAsync(() async {
        bundle.gate.complete(await rootBundle.load(bundle.rest));
        await precacheImage(AssetImage(bundle.rest, bundle: bundle), context);
      });
      await tester.pump();
      expect(find.byKey(const ValueKey('friend-motion-cels')), findsOneWidget);
      await snapshot('03-night-rest');
      report.add({
        'friend': friend.name,
        'controlledCondition':
            'rest PNG held pending; animation disabled to isolate loading',
        'requestedAmbience': 'night',
        'fallbackAssetWhileLoading': (fallback.image as AssetImage).assetName,
        'restRendererResumesAfterDecode': true,
      });
      await tester.pumpWidget(harness(preview: true));
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(
            friend.restRoomAsset(RoomAmbience.evening),
            bundle: bundle,
          ),
          tester.element(find.byType(DeskIllustration)),
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('friend-motion-cels')), findsOneWidget);
      final previewScene = tester.widget<DeskIllustration>(
        find.byType(DeskIllustration),
      );
      expect(previewScene.resting, isTrue);
      expect(previewScene.studying, isFalse);
      await snapshot('04-friend-preview');
      report.last['previewStudying'] = previewScene.studying;
      report.last['previewResting'] = previewScene.resting;
      report.last['previewButtons'] = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    File(
      '${folder.path}/verification.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  });
}
