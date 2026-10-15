import 'room_ambience.dart';

/// Stable ids used in saved rooms. Unknown ids fall back to the original friend.
enum FocusFriend {
  redpanda,
  penguin,
  otter,
  squirrel,
  fennec;

  static FocusFriend fromId(String? id) =>
      values.firstWhere((friend) => friend.name == id, orElse: () => redpanda);

  String? get sceneAsset =>
      this == redpanda ? null : 'assets/images/friends/$name-scene.png';

  bool get hasDeskMotion => this == penguin || this == otter;
  bool get hasWindowTeaMotion => this == squirrel || this == fennec;
  bool get hasRestMotion => hasDeskMotion || hasWindowTeaMotion;
  bool get hasMotion => this == redpanda || hasRestMotion;
  String get motionDirectory => 'assets/images/friends/motion/$name';

  String restRoomAsset(RoomAmbience ambience) => hasWindowTeaMotion
      ? '$motionDirectory/rooms/${ambience.assetName}.png'
      : ambienceAsset(ambience);

  /// Motion friends use empty room plates; the other friends include the actor.
  String ambienceAsset(RoomAmbience ambience) => this == redpanda
      ? ambience.asset
      : 'assets/images/friends/ambience/$name/${ambience.assetName}.png';
}
