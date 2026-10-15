import 'package:flutter/material.dart';
import 'desk_style.dart';

/// Stretches the plain paper edges while keeping the bookmark and fold intact.
class BookPageFrame extends StatelessWidget {
  const BookPageFrame({super.key, required this.child});

  static const asset = 'assets/images/ui/session-stop-book-frame.png';
  static const assetScale = 4.0;
  // Flutter expects centerSlice in logical image units, before ImageInfo.scale.
  static const centerSlice = Rect.fromLTRB(
    315 / assetScale,
    310 / assetScale,
    1104 / assetScale,
    1043 / assetScale,
  );

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: deskPaper,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: Image.asset(
            asset,
            scale: assetScale,
            centerSlice: centerSlice,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ],
  );
}
