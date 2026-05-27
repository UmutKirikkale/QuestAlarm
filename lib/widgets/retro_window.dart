import 'package:flutter/material.dart';

import '../theme/quest_theme.dart';

/// Klasik JRPG diyalog kutusu — çift kenarlık, gradyan iç yüzey, piksel köşeler.
class RetroWindow extends StatelessWidget {
  const RetroWindow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.useGradient = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool useGradient;

  static const _outerBorder = Color(0xFF39FF14);
  static const _innerBorder = Color(0xFF0FAE00);
  static const _gradientTop = Color(0xFF0A1428);
  static const _gradientBottom = Color(0xFF1C2E52);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _outerBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Color(0x8839FF14),
                offset: Offset(0, 0),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: _innerBorder, width: 2),
              color: useGradient ? null : QuestTheme.surface,
              gradient: useGradient
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_gradientTop, _gradientBottom],
                    )
                  : null,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RetroWindowCornerPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Köşelerde minik piksel çıkıntıları çizer.
class _RetroWindowCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pixel = 3.0;
    const color = Color(0xFFB9FFAE);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void drawCorner(bool top, bool left) {
      final dx = left ? -pixel : size.width;
      final dy = top ? -pixel : size.height;
      final sx = left ? 1.0 : -1.0;
      final sy = top ? 1.0 : -1.0;

      canvas.drawRect(Rect.fromLTWH(dx, dy, pixel * sx, pixel * sy), paint);
      canvas.drawRect(
        Rect.fromLTWH(dx + pixel * sx, dy, pixel * sx, pixel * sy),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(dx, dy + pixel * sy, pixel * sx, pixel * sy),
        paint,
      );
    }

    drawCorner(true, true);
    drawCorner(true, false);
    drawCorner(false, true);
    drawCorner(false, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
