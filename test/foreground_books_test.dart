import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_friend_app/focus_friend.dart';
import 'package:focus_friend_app/friend_motion_scene.dart';

void main() {
  Path books(FocusFriend friend) =>
      FriendMotionScenePainter.foregroundBooks(friend);

  test('squirrel book cover hides the tail from its own top edge', () {
    // The cover starts near y 1013–1021, well above the shared 1040 edge.
    expect(
      books(FocusFriend.squirrel).contains(const Offset(200, 1025)),
      isTrue,
    );
    expect(
      books(FocusFriend.squirrel).contains(const Offset(150, 1035)),
      isTrue,
    );
    // The sofa and tail above the cover stay visible.
    expect(
      books(FocusFriend.squirrel).contains(const Offset(200, 1005)),
      isFalse,
    );
  });

  test('fennec keeps the sofa strip above its lower book stack', () {
    // The cover starts near y 1051–1060, below the shared 1040 edge.
    expect(
      books(FocusFriend.fennec).contains(const Offset(150, 1045)),
      isFalse,
    );
    expect(books(FocusFriend.fennec).contains(const Offset(150, 1065)), isTrue);
  });

  test('penguin and otter covers start above the old shared edge', () {
    // Their top covers begin near y 1030–1034, not at the old 1040.
    for (final friend in [FocusFriend.penguin, FocusFriend.otter]) {
      expect(books(friend).contains(const Offset(150, 1037)), isTrue);
      expect(books(friend).contains(const Offset(150, 1025)), isFalse);
    }
  });

  test('stepped right ends leave the notebook corner visible', () {
    // Just right of each top book, where the old outline cut a staircase
    // into the notebook drawn by the actor.
    expect(
      books(FocusFriend.penguin).contains(const Offset(296, 1060)),
      isFalse,
    );
    expect(books(FocusFriend.otter).contains(const Offset(298, 1060)), isFalse);
  });

  test('outlines stay clear of the notebook beside the stack', () {
    for (final friend in FocusFriend.values) {
      expect(books(friend).contains(const Offset(360, 1080)), isFalse);
    }
  });
}
