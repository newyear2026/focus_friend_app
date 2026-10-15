import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_clock.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';

void main() {
  testWidgets('render penguin and otter motion from the production painter', (
    tester,
  ) async {
    await tester.runAsync(() async {
      Future<ui.Image> decode(String path) async {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final result = (await codec.getNextFrame()).image;
        codec.dispose();
        return result;
      }

      final output = Directory('docs/design/penguin-otter-motion-v1')
        ..createSync(recursive: true);
      for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
        final room = await decode('${friend.motionDirectory}/room.png');
        final study = await decode('${friend.motionDirectory}/study.png');
        final rest = await decode('${friend.motionDirectory}/rest.png');
        Future<void> render(
          String name,
          FriendMotionPose pose, {
          bool crop = false,
        }) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          if (crop) {
            canvas.scale(.7);
            canvas.translate(-115, -620);
          }
          FriendMotionScenePainter(
            room: room,
            actor: FriendMotionPainter(
              friend: friend,
              study: study,
              rest: rest,
              pose: pose,
            ),
          ).paint(canvas, const Size(853, 1844));
          final picture = recorder.endRecording();
          final image = await picture.toImage(
            crop ? 483 : 853,
            crop ? 434 : 1844,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${output.path}/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }

        for (final (name, pose) in [
          ('writing', FriendMotionClock.sample(Duration.zero)),
          (
            'stroke',
            FriendMotionClock.sample(const Duration(milliseconds: 1800)),
          ),
          (
            'pen-down',
            const FriendMotionPose(8, 8, 0, FriendMotionPhase.pageTurn),
          ),
          (
            'page',
            const FriendMotionPose(16, 16, 0, FriendMotionPhase.pageTurn),
          ),
          (
            'return',
            const FriendMotionPose(23, 23, 0, FriendMotionPhase.pageTurn),
          ),
          ('rest', const FriendMotionPose(0, 0, 0, FriendMotionPhase.tea)),
          ('sip', const FriendMotionPose(6, 6, 0, FriendMotionPhase.tea)),
        ]) {
          await render('${friend.name}-$name', pose);
        }
        if (Platform.environment['FRIEND_MOTION_VIDEO'] == '1') {
          for (final resting in [false, true]) {
            final action = resting ? 'rest' : 'study';
            final frames = resting ? 168 : 162;
            for (var frame = 0; frame < frames; frame++) {
              final elapsed = Duration(
                microseconds:
                    ((resting ? 0 : 32.4) * 1000000 + frame * 1000000 / 12)
                        .round(),
              );
              await render(
                'frames/${friend.name}-$action/${frame.toString().padLeft(4, '0')}',
                FriendMotionClock.sample(
                  elapsed,
                  resting: resting,
                  friend: friend,
                ),
                crop: true,
              );
            }
          }
        }
        room.dispose();
        study.dispose();
        rest.dispose();
      }
    });
  });
}
