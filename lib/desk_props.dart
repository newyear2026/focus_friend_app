/// A desk prop earned by finished focus time.
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
  });

  final String key;
  final int unlockMinutes;
  final double left;
  final double top;
  final double width;
  final double height;
  final int layer;
  final bool contain;

  int get unlockMs => unlockMinutes * 60000;
  String get asset => 'assets/images/immersive/reward-$key.png';
}

/// Every prop in unlock order. Adding one needs an asset at [DeskProp.asset]
/// and names in `propName` / `propShortName`.
const deskProps = [
  DeskProp(
    'plant',
    unlockMinutes: 0,
    left: 648,
    top: 957,
    width: 115,
    height: 138,
    layer: 1,
    contain: true,
  ),
  DeskProp(
    'mug',
    unlockMinutes: 60,
    left: 613,
    top: 1010,
    width: 156,
    height: 170,
    layer: 2,
  ),
  DeskProp(
    'lamp',
    unlockMinutes: 120,
    left: 608,
    top: 739,
    width: 266,
    height: 400,
    layer: 0,
  ),
];
