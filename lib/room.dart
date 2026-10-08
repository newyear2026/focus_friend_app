import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CatMood { resting, focusing, happy }

class CozyRoom extends StatelessWidget {
  const CozyRoom({
    super.key,
    required this.unlocked,
    this.zoom = false,
    this.mood = CatMood.resting,
  });
  final Set<String> unlocked;
  final bool zoom;
  final CatMood mood;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '아이소메트릭 방. 고양이 ${mood == CatMood.focusing
            ? "집중 중"
            : mood == CatMood.happy
            ? "기뻐하는 중"
            : "쉬는 중"}. '
        '화분 ${unlocked.contains("plant") ? "있음" : "빈 자리"}, 머그컵 ${unlocked.contains("mug") ? "있음" : "빈 자리"}, 조명 ${unlocked.contains("lamp") ? "있음" : "빈 자리"}',
    image: true,
    child: ClipRect(
      child: AnimatedScale(
        scale: zoom ? 1.48 : 1,
        alignment: const Alignment(.15, .23),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        child: CustomPaint(
          painter: RoomPainter(unlocked, mood),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class RoomPainter extends CustomPainter {
  RoomPainter(this.unlocked, this.mood);
  final Set<String> unlocked;
  final CatMood mood;
  late Canvas c;
  void poly(List<Offset> p, Color color, {Color? border}) {
    final path = Path()..addPolygon(p, true);
    c.drawPath(path, Paint()..color = color);
    if (border != null) {
      c.drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  List<Offset> points(List<double> xy) => [
    for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
  ];
  void shape(List<double> p, int color) => poly(points(p), Color(color));
  void line(Offset a, Offset b, Color color, [double width = 2]) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void oval(double x, double y, double w, double h, int color) => c.drawOval(
    Rect.fromCenter(center: Offset(x, y), width: w, height: h),
    Paint()..color = Color(color),
  );
  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    final scale = math.min(size.width / 600, size.height / 470);
    c.save();
    c.translate(
      (size.width - 600 * scale) / 2,
      (size.height - 470 * scale) / 2,
    );
    c.scale(scale);
    oval(300, 419, 405, 37, 0x0F574338);
    // The room is painted as individual surfaces and props, never a whole mockup bitmap.
    shape([48, 300, 300, 440, 554, 300, 300, 160], 0xFFD9B598);
    shape([48, 300, 300, 440, 300, 451, 48, 311], 0xFFB88C70);
    shape([300, 440, 554, 300, 554, 311, 300, 451], 0xFFC79D7D);
    shape([48, 150, 300, 12, 300, 160, 48, 300], 0xFFF0E3D0);
    shape([300, 12, 554, 150, 554, 300, 300, 160], 0xFFE5D3BC);
    shape([48, 150, 56, 154, 56, 296, 48, 300], 0xFFDDC7B0);
    shape([546, 154, 554, 150, 554, 300, 546, 296], 0xFFD1B79D);
    line(
      const Offset(56, 287),
      const Offset(300, 151),
      const Color(0xFFCEB091),
      5,
    );
    line(
      const Offset(300, 151),
      const Offset(546, 287),
      const Color(0xFFC7A687),
      5,
    );
    for (var i = 1; i < 9; i++) {
      final t = i / 9;
      line(
        Offset(48 + 252 * t, 300 + 140 * t),
        Offset(300 + 254 * t, 160 + 140 * t),
        const Color(0xFFC79F81),
        1,
      );
    }
    // Window frame, sky, and sunlight.
    shape([98, 155, 212, 93, 212, 199, 98, 262], 0xFFBD9675);
    shape([104, 157, 206, 102, 206, 194, 104, 250], 0xFFD5E5DC);
    shape([111, 160, 199, 112, 199, 150, 111, 198], 0xFFEAF2DA);
    line(
      const Offset(153, 132),
      const Offset(153, 225),
      const Color(0xFFFCF5E7),
      7,
    );
    line(
      const Offset(105, 204),
      const Offset(204, 149),
      const Color(0xFFFCF5E7),
      6,
    );
    shape([89, 256, 214, 188, 229, 196, 106, 265], 0xFFF9F0DF);
    shape([110, 269, 203, 219, 305, 293, 213, 342], 0x28FFF8D6);
    // Small wall picture.
    shape([411, 101, 461, 128, 461, 184, 411, 157], 0xFFA58364);
    shape([417, 112, 455, 133, 455, 174, 417, 153], 0xFFF5EADA);
    oval(437, 143, 17, 20, 0xFFA1AB7C);
    // Soft rug.
    shape([142, 321, 310, 229, 475, 320, 307, 411], 0xFFB9BD9F);
    shape([153, 321, 310, 236, 465, 320, 307, 403], 0xFFD7D6B8);
    for (var i = 0; i < 8; i++) {
      line(
        Offset(161 + i * 18, 335 + i * 10),
        Offset(166 + i * 18, 327 + i * 10),
        const Color(0xFFAAAC8C),
        2,
      );
    }
    // Desk legs, side and wooden worktop.
    shape([273, 259, 285, 265, 285, 330, 273, 324], 0xFF93735B);
    shape([430, 265, 443, 259, 443, 326, 430, 333], 0xFF9E785A);
    shape([350, 213, 361, 218, 361, 284, 350, 278], 0xFFAA8060);
    shape([244, 235, 345, 180, 475, 251, 372, 308], 0xFFF0C899);
    shape([244, 235, 372, 308, 372, 318, 244, 245], 0xFFC0946F);
    shape([372, 308, 475, 251, 475, 261, 372, 318], 0xFFB48763);
    // Notebook and pencil.
    shape([330, 240, 362, 223, 403, 246, 371, 264], 0xFFFDF6E6);
    line(
      const Offset(362, 224),
      const Offset(372, 260),
      const Color(0xFFD6C5AD),
      1,
    );
    line(
      const Offset(334, 246),
      const Offset(356, 258),
      const Color(0xFF94745D),
      3,
    );
    // Three fixed prop positions.
    if (unlocked.contains('plant')) {
      _plant(278, 235);
    } else {
      _slot(278, 235, 28, 13);
    }
    if (unlocked.contains('mug')) {
      oval(413, 253, 26, 13, 0xFFCFAD8B);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(402, 234, 20, 19),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFFFBF3E1),
      );
      c.drawCircle(
        const Offset(425, 242),
        6,
        Paint()
          ..color = const Color(0xFFFAF1DF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      oval(412, 235, 19, 7, 0xFF967B63);
    } else {
      _slot(414, 249, 25, 13);
    }
    if (unlocked.contains('lamp')) {
      oval(448, 245, 30, 13, 0xFFAD8A67);
      line(
        const Offset(448, 245),
        const Offset(448, 205),
        const Color(0xFFAA8862),
        4,
      );
      shape([435, 192, 461, 192, 470, 215, 426, 215], 0xFFF7D78C);
      oval(448, 214, 43, 13, 0xFFF3C974);
      oval(448, 253, 55, 25, 0x30FFF2AA);
    } else {
      _slot(450, 242, 29, 14);
    }
    // Stool and three distinct cat poses.
    line(
      const Offset(328, 345),
      const Offset(324, 379),
      const Color(0xFFAA8261),
      7,
    );
    line(
      const Offset(367, 344),
      const Offset(373, 375),
      const Color(0xFFAA8261),
      7,
    );
    oval(349, 339, 72, 36, 0xFFC5A182);
    oval(349, 334, 72, 33, 0xFFEAD0AB);
    c.save();
    c.translate(347, 307);
    _cat();
    c.restore();
    // A low book basket gives the empty room a lived-in feel.
    shape([116, 307, 147, 289, 181, 309, 150, 328], 0xFFB89471);
    shape([116, 307, 150, 328, 150, 352, 116, 333], 0xFFC6A583);
    shape([150, 328, 181, 309, 181, 336, 150, 352], 0xFFA98665);
    shape([127, 303, 136, 298, 162, 313, 153, 318], 0xFF7D998C);
    shape([137, 300, 144, 296, 169, 310, 162, 314], 0xFFE8CEA6);
    c.restore();
  }

  void _slot(double x, double y, double w, double h) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      Paint()
        ..color = const Color(0xFFCAA37F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    line(Offset(x - 3, y), Offset(x + 3, y), const Color(0xFFCAA37F), 1.5);
    line(Offset(x, y - 3), Offset(x, y + 3), const Color(0xFFCAA37F), 1.5);
  }

  void _plant(double x, double y) {
    oval(x, y, 32, 13, 0xFFC39B75);
    shape([
      x - 14,
      y - 21,
      x + 14,
      y - 21,
      x + 10,
      y + 1,
      x - 10,
      y + 1,
    ], 0xFFCB8D6F);
    oval(x, y - 21, 28, 10, 0xFFE5AE89);
    line(Offset(x, y - 22), Offset(x, y - 54), const Color(0xFF788B58), 3);
    oval(x - 10, y - 46, 22, 11, 0xFF8D9D66);
    oval(x + 9, y - 54, 21, 12, 0xFF738953);
    oval(x - 4, y - 63, 13, 20, 0xFFA0AB72);
  }

  void _cat() {
    const fur = Color(0xFFC68C5A), dark = Color(0xFF674B39);
    final tail = Path()
      ..moveTo(21, 18)
      ..quadraticBezierTo(53, 25, 40, -1);
    c.drawPath(
      tail,
      Paint()
        ..color = fur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    oval(0, 14, 53, 34, 0xFFC68C5A);
    if (mood == CatMood.resting) {
      oval(-12, 5, 35, 29, 0xFFE0AF7D);
      shape([-28, -1, -28, -16, -15, -6], 0xFFE0AF7D);
      shape([-7, -5, 5, -15, 5, 0], 0xFFE0AF7D);
      line(const Offset(-23, 7), const Offset(-17, 8), dark, 2);
      line(const Offset(-7, 8), const Offset(-1, 6), dark, 2);
      oval(-13, 14, 4, 3, 0xFF92624D);
    } else {
      oval(-5, -8, 44, 38, 0xFFE0AF7D);
      shape([-26, -17, -27, -37, -10, -26], 0xFFE0AF7D);
      shape([5, -26, 19, -37, 17, -12], 0xFFE0AF7D);
      shape([-23, -22, -23, -32, -15, -26], 0xFFD4907A);
      shape([8, -26, 15, -32, 14, -22], 0xFFD4907A);
      oval(-14, 0, 12, 9, 0xFFEAB88E);
      oval(6, 0, 12, 9, 0xFFEAB88E);
      if (mood == CatMood.happy) {
        final p = Path()
          ..moveTo(-20, -8)
          ..quadraticBezierTo(-15, -15, -10, -8)
          ..moveTo(0, -8)
          ..quadraticBezierTo(5, -15, 10, -8);
        c.drawPath(
          p,
          Paint()
            ..color = dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        oval(-4, 6, 5, 5, 0xFF86543D);
      } else {
        oval(-15, -9, 4, 7, 0xFF674B39);
        oval(5, -9, 4, 7, 0xFF674B39);
      }
      oval(-5, 0, 5, 4, 0xFF9F6652);
      line(const Offset(-5, 2), const Offset(-5, 6), dark, 1);
      line(const Offset(-22, -1), const Offset(-34, -3), dark, 1);
      line(const Offset(14, -1), const Offset(26, -3), dark, 1);
      oval(-18, 26, 16, 9, 0xFFE8BC8D);
      oval(13, 26, 16, 9, 0xFFE8BC8D);
    }
    for (var i = 0; i < 3; i++) {
      line(
        Offset(5 + i * 7, 5),
        Offset(2 + i * 7, 13),
        const Color(0xFFAB7348),
        3,
      );
    }
    if (mood == CatMood.happy) {
      for (final p in [const Offset(-43, -25), const Offset(39, -30)]) {
        line(p.translate(-4, 0), p.translate(4, 0), const Color(0xFFC0A266), 2);
        line(p.translate(0, -5), p.translate(0, 5), const Color(0xFFC0A266), 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoomPainter oldDelegate) => true;
}
