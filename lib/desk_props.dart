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
