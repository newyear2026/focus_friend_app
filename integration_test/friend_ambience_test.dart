import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/room_ambience.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/study_scene.dart';

class AmbiencePreviewStore implements StateStore {
  AmbiencePreviewStore(this.value);
  FocusState value;
  @override
  Future<FocusState> load() async => value.copy();
  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    if (value.revision != expectedRevision) throw StateError('revision');
    value = next.copy();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('sixteen native friend rooms follow local time without saving', (
    tester,
  ) async {
    final output = Directory(
      '${Directory.systemTemp.path}/friend-ambience-preview',
    );
    await output.create(recursive: true);
    final captures = <String, int>{};
    for (final friend in FocusFriend.values.where(
      (f) => f != FocusFriend.redpanda,
    )) {
      var now = DateTime(2026, 10, 15, 7).millisecondsSinceEpoch;
      final store = AmbiencePreviewStore(FocusState(friend: friend));
      final engine = SessionEngine(store, clock: () => now);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(engine: engine, locale: const Locale('ko')),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(DeskIllustration));
      for (final asset in [
        for (final ambience in RoomAmbience.values)
          friend.ambienceAsset(ambience),
        if (friend.hasDeskMotion) '${friend.motionDirectory}/study.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
      await tester.pumpAndSettle();
      final before = engine.state.encode();
      for (final (hour, ambience) in [
        (7, RoomAmbience.morning),
        (12, RoomAmbience.day),
        (18, RoomAmbience.evening),
        (22, RoomAmbience.night),
      ]) {
        now = DateTime(2026, 10, 15, hour).millisecondsSinceEpoch;
        // Android's live test clock and the app's 250 ms wall-clock poll are
        // separate. Wait for the actual poll rather than one synthetic frame.
        for (var attempt = 0; attempt < 20; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          await tester.pump();
          if (tester
                  .widget<DeskIllustration>(find.byType(DeskIllustration))
              .ambience ==
              ambience) {
            break;
          }
        }
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DeskIllustration>(find.byType(DeskIllustration))
              .ambience,
          ambience,
          reason: '${friend.name} did not refresh at hour $hour',
        );
        expect(engine.state.encode(), before);
        expect(tester.takeException(), isNull);
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final name = '${friend.name}-${ambience.assetName}';
        await File(
          '${output.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        captures[name] = now;
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    await File(
      '${output.path}/capture-times.json',
    ).writeAsString(jsonEncode(captures));
    // The host exporter reads screenshots before Flutter removes the isolated APK.
    await Future<void>.delayed(const Duration(seconds: 12));
  });
}
