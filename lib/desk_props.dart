import 'room_ambience.dart';

/// A desk prop included by default or earned by finished focus time.
///
/// [key] is stored in saved state and must not change. Placement is in the
/// 853×1844 study scene; [layer] orders overlapping props back to front.
class DeskProp {
  const DeskProp(
    this.key, {
    required this.unlockMinutes,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.layer,
    this.contain = false,
    this.availableByDefault = false,
  });

  final String key;
  final int unlockMinutes;
  final double left;
  final double top;
  final double width;
  final double height;
  final int layer;
  final bool contain;
  final bool availableByDefault;

  int get unlockMs => unlockMinutes * 60000;
  bool isAvailable(Iterable<String> unlocked) =>
      availableByDefault || unlocked.contains(key);
  String get asset => 'assets/images/immersive/reward-$key.png';
  String sceneAsset(RoomAmbience ambience) => key == 'lamp' && !ambience.lampsOn
      ? 'assets/images/immersive/reward-lamp-unlit.png'
      : asset;
}

/// Every desk prop. Default items are not granted again as focus rewards.
/// Adding one needs an asset at [DeskProp.asset]
/// and names in `propName` / `propShortName`.
const deskProps = [
  DeskProp(
    'plant',
    unlockMinutes: 0,
    // Keep greenery on the left book stack, clear of the cup and task light.
    left: 28,
    top: 936,
    width: 126,
    height: 126,
    layer: 1,
    contain: true,
  ),
  DeskProp(
    'mug',
    unlockMinutes: 60,
    // The cup sits beside the far edge of the open notebook.
    left: 655,
    top: 950,
    width: 125,
    height: 148,
    layer: 2,
    contain: true,
  ),
  DeskProp(
    'lamp',
    unlockMinutes: 0,
    availableByDefault: true,
    // The base sits at the back of the desk, behind the foreground pen cup.
    left: 606,
    top: 732,
    width: 246,
    height: 354,
    layer: 0,
    contain: true,
  ),
];

/// The next prop that finished focus time will earn, and how close it is.
class NextDeskGift {
  const NextDeskGift(this.prop, this.completedMs);

  final DeskProp prop;

  /// Lifetime finished focus time; only finished focus sessions count.
  final int completedMs;

  /// The first-focus prop needs a finished session, not a minute total.
  bool get needsFirstFocus => prop.unlockMinutes == 0;

  /// Whole minutes still needed, rounded up so "0" never shows before unlock.
  int get remainingMinutes =>
      ((prop.unlockMs - completedMs).clamp(0, prop.unlockMs) + 59999) ~/ 60000;

  int get doneMinutes => (completedMs ~/ 60000).clamp(0, prop.unlockMinutes);

  double get progress => needsFirstFocus || prop.unlockMs == 0
      ? 0
      : (completedMs / prop.unlockMs).clamp(0.0, 1.0);
}

/// The earned (not default) prop with the lowest threshold that is still
/// locked, or `null` once every prop is on the desk.
NextDeskGift? nextDeskGift(Iterable<String> unlocked, int completedMs) {
  final owned = unlocked.toSet();
  final locked = [
    for (final prop in deskProps)
      if (!prop.availableByDefault && !owned.contains(prop.key)) prop,
  ]..sort((a, b) => a.unlockMinutes.compareTo(b.unlockMinutes));
  return locked.isEmpty ? null : NextDeskGift(locked.first, completedMs);
}
