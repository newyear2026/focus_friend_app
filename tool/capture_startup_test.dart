import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/startup_screen.dart';
import 'package:focus_friend_app/startup_companion.dart';

import '../test/session_engine_test.dart' show MemoryStore;
import '../test/widget_test.dart' show loadAppFont;

class _LoadingStore extends MemoryStore {
  final loaded = Completer<FocusState>();

  @override
  Future<FocusState> load() => loaded.future;
}

const _output = String.fromEnvironment(
  'STARTUP_CAPTURE_DIR',
  defaultValue: 'docs/design/startup-screen-v2',
);
const _reference =
    'docs/design/startup-screen-concepts-v1/03-reading-companion.png';

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String name,
  double ratio,
) => tester.runAsync(() async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bitmap = await boundary.toImage(pixelRatio: ratio);
  final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
  Directory(_output).createSync(recursive: true);
  await File('$_output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  bitmap.dispose();
});

Future<void> _loadArt(WidgetTester tester) => tester.runAsync(() async {
  final context = tester.element(find.byType(StartupScreen));
  await Future.wait([
    for (final asset in [
      StartupCompanion.asset,
      ...StartupCompanion.motionAssets,
    ])
      precacheImage(StartupCompanion.imageProvider(asset), context),
    precacheImage(const AssetImage(StartupScreen.backgroundAsset), context),
  ]);
});

// flutter test --no-pub tool/capture_startup_test.dart
void main() {
  for (final (name, size, ratio, scale, locale) in [
    ('reference-size', const Size(977, 1610), 977 / 390, 1.0, 'ko'),
    ('loading', const Size(780, 1688), 2.0, 1.0, 'ko'),
    ('compact-large-text', const Size(640, 1136), 2.0, 1.6, 'ko'),
    ('landscape', const Size(1688, 780), 2.0, 1.0, 'ko'),
    ('spanish', const Size(780, 1688), 2.0, 1.0, 'es'),
  ]) {
    testWidgets('capture startup $name', (tester) async {
      await loadAppFont();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final key = GlobalKey();
      final store = _LoadingStore();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: FocusFriendApp(
            engine: SessionEngine(store),
            locale: Locale(locale),
          ),
        ),
      );
      await _loadArt(tester);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _capture(tester, key, name, ratio);
      if (name == 'loading') {
        await tester.pump(const Duration(milliseconds: 600));
        await _capture(tester, key, 'loading-pulse', ratio);
        store.loaded.completeError(StateError('Preview storage failure'));
        await tester.pumpAndSettle();
        expect(find.text('다시 확인'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, key, 'retry', ratio);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('compare selected image and real startup at equal size', (
    tester,
  ) async {
    await loadAppFont();
    tester.view.physicalSize = const Size(1954, 1610);
    tester.view.devicePixelRatio = 977 / 390;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final reference = await tester.runAsync(
      () async => decodeImageFromList(await File(_reference).readAsBytes()),
    );
    addTearDown(() => reference?.dispose());
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: RawImage(image: reference, fit: BoxFit.contain),
              ),
              Expanded(
                child: FocusFriendApp(
                  engine: SessionEngine(_LoadingStore()),
                  locale: const Locale('ko'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _loadArt(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'comparison', 977 / 390);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
