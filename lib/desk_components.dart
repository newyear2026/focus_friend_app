import 'package:flutter/material.dart';
import 'desk_style.dart';

const ticketGold = deskAccent;

class TicketBorder extends OutlinedBorder {
  const TicketBorder({
    super.side = const BorderSide(color: deskInk, width: 1.5),
  });
  @override
  TicketBorder copyWith({BorderSide? side}) =>
      TicketBorder(side: side ?? this.side);
  @override
  ShapeBorder scale(double t) => TicketBorder(side: side.scale(t));
  Path _path(Rect rect) {
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    final cuts = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(rect.left, rect.center.dy), radius: 7),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(rect.right, rect.center.dy), radius: 7),
      );
    return Path.combine(PathOperation.difference, base, cuts);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }
}

class TicketPanel extends StatelessWidget {
  const TicketPanel({
    super.key,
    required this.child,
    this.color = deskCream,
    this.onTap,
  });
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: deskDivider),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: child),
  );
}

class DeskPrimaryButton extends StatelessWidget {
  const DeskPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
    ),
    padding: EdgeInsets.zero,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: deskAccent,
        foregroundColor: deskInkShadow,
        disabledBackgroundColor: loading
            ? deskAccent.withValues(alpha: .55)
            : deskCream,
        disabledForegroundColor: loading ? deskInkShadow : deskMuted,
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          if (icon != null || loading) const SizedBox(width: 34),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 34,
              height: 34,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: deskInkShadow,
                ),
              ),
            )
          else if (icon != null)
            CircleAvatar(
              radius: 17,
              backgroundColor: deskInkShadow,
              child: Icon(icon, size: 23, color: deskAccent),
            ),
        ],
      ),
    ),
  );
}

class CompanionImage extends StatelessWidget {
  const CompanionImage({super.key, this.size = 80});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/companion-portrait.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}
