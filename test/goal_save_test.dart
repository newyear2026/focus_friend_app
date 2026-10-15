import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/desk_components.dart';
import 'package:focus_friend_app/goal_editor.dart';
import 'package:focus_friend_app/main.dart';
import 'package:focus_friend_app/session_engine.dart';
import 'package:focus_friend_app/sound_sheet.dart';
import 'session_engine_test.dart' show MemoryStore;

class DelayedStore extends MemoryStore {
  Completer<void>? loadGate, commitGate;

  @override
  Future<FocusState> load() async {
    final gate = loadGate;
    loadGate = null;
    await gate?.future;
    return super.load();
  }

  @override
  Future<void> commit(FocusState next, int expectedRevision) async {
    final gate = commitGate;
    commitGate = null;
    await gate?.future;
    await super.commit(next, expectedRevision);
  }
}

Completer<void> hold() {
  final gate = Completer<void>();
  addTearDown(() {
    if (!gate.isCompleted) gate.complete();
  });
  return gate;
}

void resumeApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

Future<SessionEngine> openGoal(
  WidgetTester tester,
  DelayedStore store, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final engine = SessionEngine(
    store,
    clock: () => DateTime(2026, 10, 14, 18).millisecondsSinceEpoch,
  );
  await tester.pumpWidget(
    FocusFriendApp(engine: engine, locale: const Locale('ko')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('desk-navigation-3')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('목표와 다짐'));
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('goal save waits for restore and commit before closing', (
    tester,
  ) async {
    final store = DelayedStore();
    final engine = await openGoal(
      tester,
      store,
      size: const Size(360, 740),
      textScale: 1.6,
    );
    await tester.enterText(find.byKey(const ValueKey('goal-name')), '자격증 시험');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final restoring = hold();
    final writing = hold();
    store.loadGate = restoring;
    store.commitGate = writing;
    resumeApp(tester);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-goal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GoalEditor), findsOneWidget);
    expect(find.text('저장 중…'), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-saving-status')), findsOneWidget);
    expect(
      tester
          .widget<DeskPrimaryButton>(find.byKey(const ValueKey('save-goal')))
          .loading,
      isTrue,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('goal-name')))
          .enabled,
      isFalse,
    );
    expect(engine.state.goal, isNull);
    expect(store.commits, 0);
    expect(tester.takeException(), isNull);
    // System back must also leave the editor open while its save is pending.
    await Navigator.of(tester.element(find.byType(GoalEditor))).maybePop();
    await tester.pump();
    expect(find.byType(GoalEditor), findsOneWidget);

    restoring.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GoalEditor), findsOneWidget);
    expect(store.commits, 0);
    await tester.tap(find.byKey(const ValueKey('save-goal')));
    await tester.pump();
    writing.complete();
    await tester.pumpAndSettle();

    expect(find.byType(GoalEditor), findsNothing);
    expect(store.commits, 1);
    expect(engine.state.goal!.name, '자격증 시험');
    await tester.pumpWidget(const SizedBox.shrink());
    final reopened = SessionEngine(store);
    await reopened.restore();
    expect(reopened.state.goal!.name, '자격증 시험');
  });

  testWidgets('failed queued goal save keeps the draft and can retry', (
    tester,
  ) async {
    final store = DelayedStore();
    final engine = await openGoal(tester, store);
    await tester.enterText(
      find.byKey(const ValueKey('goal-name')),
      '내가 수정한 목표',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final restoring = hold();
    store.loadGate = restoring;
    store.failBefore = true;
    resumeApp(tester);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-goal')));
    await tester.pump();
    expect(find.text('저장 중…'), findsOneWidget);
    restoring.complete();
    await tester.pumpAndSettle();

    expect(find.byType(GoalEditor), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('goal-save-error')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('goal-name')))
          .controller!
          .text,
      '내가 수정한 목표',
    );
    expect(engine.state.goal, isNull);
    expect(store.commits, 0);
    await tester.tap(find.byKey(const ValueKey('save-goal')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalEditor), findsNothing);
    expect(engine.state.goal!.name, '내가 수정한 목표');
    expect(store.commits, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('goal deletion waits for restore and preserves focus records', (
    tester,
  ) async {
    final store = DelayedStore()
      ..raw = FocusState(
        goal: const FocusGoal(name: '이전 목표', date: '2026-11-13'),
        completedMs: 25 * 60000,
        completedCount: 1,
        unlocks: {'plant': 1},
      ).encode();
    final engine = await openGoal(tester, store);
    await tester.tap(find.byTooltip('목표 삭제'));
    await tester.pumpAndSettle();
    final restoring = hold();
    store.loadGate = restoring;
    resumeApp(tester);
    await tester.pump();
    await tester.tap(find.text('삭제'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GoalEditor), findsOneWidget);
    expect(engine.state.goal!.name, '이전 목표');
    restoring.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GoalEditor), findsNothing);
    expect(engine.state.goal, isNull);
    expect(engine.state.completedMs, 25 * 60000);
    expect(engine.state.completedCount, 1);
    expect(engine.state.unlocks, {'plant': 1});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sound save also waits for an in-flight timer completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = DelayedStore();
    var now = DateTime(2026, 10, 14, 18).millisecondsSinceEpoch;
    final engine = SessionEngine(store, clock: () => now);
    await engine.restore();
    await engine.start(const Duration(seconds: 1));
    await tester.pumpWidget(
      FocusFriendApp(engine: engine, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-sound')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sound-forest')));
    await tester.pumpAndSettle();
    final completing = hold();
    store.commitGate = completing;
    now += 1000;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(find.byKey(const ValueKey('save-sound')));
    await tester.tap(find.byKey(const ValueKey('save-sound')));
    await tester.pump();
    expect(find.byType(SoundSheet), findsOneWidget);
    expect(engine.state.sound.enabled, isFalse);
    completing.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SoundSheet), findsNothing);
    expect(engine.state.completedCount, 1);
    expect(engine.state.sound.sound, 'forest');
    expect(engine.state.sound.enabled, isTrue);
    expect(store.commits, 3); // Start, completion, settings save.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
