import 'package:flutter/material.dart';
import 'dart:math' as math;

class SyringePainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;

  SyringePainter({
    required this.progress,
    required this.transition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 20;
    final double barrelWidth = size.width - (padding * 2);
    final double barrelHeight = 40;
    final double centerY = size.height / 2;
    final double startX = padding;

    final Paint barrelPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint liquidPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final Paint plungerPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 1. Draw Barrel
    RRect barrelRect = RRect.fromLTRBR(startX, centerY - (barrelHeight / 2), startX + barrelWidth, centerY + (barrelHeight / 2), Radius.circular(4));
    canvas.drawRRect(barrelRect, barrelPaint);

    // 2. Draw Liquid (Filling)
    // In transition (inject), liquid disappears rapidly
    double fillProgress = progress;
    if (transition > 0) {
      fillProgress = progress * (1.0 - transition * 2).clamp(0.0, 1.0);
    }
    
    double liquidWidth = barrelWidth * fillProgress;
    if (liquidWidth > 5) {
      Rect liquidRect = Rect.fromLTWH(startX, centerY - (barrelHeight / 2) + 2, liquidWidth, barrelHeight - 4);
      canvas.drawRect(liquidRect, liquidPaint);
      
      // Draw some bubbles
      _drawBubbles(canvas, startX, centerY, liquidWidth, barrelHeight, progress);
    }

    // 3. Draw Plunger
    // Plunger starts at startX and moves back as it fills, then forward as it injects
    double plungerX = startX + (barrelWidth * fillProgress);
    
    // Plunger handle/rod
    canvas.drawLine(Offset(plungerX, centerY), Offset(size.width, centerY), plungerPaint);
    canvas.drawLine(Offset(size.width - 5, centerY - 15), Offset(size.width - 5, centerY + 15), plungerPaint); // Thumb rest
    
    // Plunger head (rubber stopper)
    Paint stopperPaint = Paint()..color = Colors.black54..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(plungerX - 5, centerY - (barrelHeight / 2) + 2, 10, barrelHeight - 4), stopperPaint);

    // 4. Draw Tip/Needle area (simplified)
    Paint tipPaint = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawLine(Offset(startX, centerY), Offset(startX - 15, centerY), tipPaint);
  }

  void _drawBubbles(Canvas canvas, double startX, double centerY, double liquidWidth, double barrelHeight, double progress) {
    final Paint bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.4)..style = PaintingStyle.fill;
    
    // Simulating a few bubbles that move slightly
    for (int i = 0; i < 5; i++) {
        double bx = startX + (liquidWidth * (i + 1) / 6);
        double by = centerY + (math.sin(progress * 10 + i) * (barrelHeight / 4));
        canvas.drawCircle(Offset(bx, by), 2, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SyringePainter oldDelegate) => true;
}
