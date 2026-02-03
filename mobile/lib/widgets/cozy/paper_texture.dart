import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PaperTexturePainter extends CustomPainter {
  final Color color;
  final double opacity;

  PaperTexturePainter({required this.color, this.opacity = 0.03});

  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(42); // Fixed seed for consistent grain
    final Paint paint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < size.width; i += 2) {
      for (int j = 0; j < size.height; j += 2) {
        if (random.nextDouble() < 0.5) {
          paint.color = color.withValues(alpha: random.nextDouble() * opacity);
          canvas.drawPoints(
            PointMode.points,
            [Offset(i.toDouble(), j.toDouble())],
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperTexture extends StatelessWidget {
  final Widget child;
  final Color grainColor;
  final double opacity;

  const PaperTexture({
    super.key,
    required this.child,
    this.grainColor = Colors.black,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: PaperTexturePainter(
                color: grainColor,
                opacity: opacity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
