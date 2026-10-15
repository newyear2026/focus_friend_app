import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/reference_companion.dart';
import 'package:focus_friend_app/reference_study_animation.dart';
import 'package:focus_friend_app/rest_animation.dart';
import 'package:focus_friend_app/rest_companion.dart';

/// Image decoding never finishes inside a widget test's fake clock, so without
/// this the companions keep their still fallback and never start animating.
/// Call it after the app is pumped; later companions resolve from the cache.
Future<void> precacheCompanionArt(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final asset in [
      ReferenceStudyAnimation.bodyAsset,
      ReferenceStudyAnimation.notebookAsset,
      RestAnimation.asset,
      RestAnimation.inbetweensAsset,
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
}

ReferenceCompanionPainter studyPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('reference-companion-cels')),
            )
            .painter!
        as ReferenceCompanionPainter;

/// The writing cel the home scene is drawing right now.
int studyFrame(WidgetTester tester) => studyPainter(tester).frame;

RestCompanionPainter restPainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(RestCompanion),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as RestCompanionPainter;

/// Distinct writing cels seen while pumping [duration] at the 12fps grid.
Future<Set<int>> studyFramesDuring(
  WidgetTester tester,
  Duration duration,
) async {
  final seen = <int>{};
  for (
    var t = Duration.zero;
    t < duration;
    t += const Duration(milliseconds: 84)
  ) {
    await tester.pump(const Duration(milliseconds: 84));
    seen.add(studyFrame(tester));
  }
  return seen;
}
