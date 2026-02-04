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
    // 0. Setup Rotation
    canvas.save();
    // Centering and rotating by 30 degrees (upwards)
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6); 
    canvas.translate(-size.width / 2, -size.height / 2);

    const double padding = 30;
    final double barrelWidth = size.width - (padding * 2);
    final double barrelHeight = 40;
    final double centerY = size.height / 2;
    final double startX = padding;

    // 1. Paints
    final Paint barrelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Blood Red Gradient
    final Paint liquidPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red[800]!, Colors.red[400]!],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(startX, centerY - (barrelHeight / 2), barrelWidth, barrelHeight));

    final Paint plungerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;

    // 2. Draw Barrel (Less rounded)
    RRect barrelRect = RRect.fromLTRBR(
      startX, 
      centerY - (barrelHeight / 2), 
      startX + barrelWidth, 
      centerY + (barrelHeight / 2), 
      const Radius.circular(8) // Reduced rounding
    );
    canvas.drawRRect(barrelRect, barrelPaint);
    canvas.drawRRect(barrelRect, borderPaint);

    // 3. Draw Liquid (Filling)
    // Note: User wants it to stop when filled
    double fillProgress = progress.clamp(0.0, 1.0);
    
    double liquidWidth = barrelWidth * fillProgress;
    if (liquidWidth > 4) { 
      RRect liquidRRect = RRect.fromLTRBAndCorners(
        startX, 
        centerY - (barrelHeight / 2) + 1, 
        startX + liquidWidth, 
        centerY + (barrelHeight / 2) - 1,
        topLeft: const Radius.circular(8),
        bottomLeft: const Radius.circular(8),
      );
      canvas.drawRRect(liquidRRect, liquidPaint);
      
      // Particles floating towards the plunger (direction of filling)
      _drawParticles(canvas, startX, centerY, liquidWidth, barrelHeight);
    }

    // 4. Draw Plunger
    double plungerX = startX + (barrelWidth * fillProgress);
    
    // Plunger handle/rod
    canvas.drawLine(Offset(plungerX, centerY), Offset(size.width - 5, centerY), plungerPaint);
    
    // Thumb rest
    canvas.drawLine(Offset(size.width - 5, centerY - 15), Offset(size.width - 5, centerY + 15), plungerPaint);

    // Plunger head
    Paint stopperPaint = Paint()..color = Colors.black.withValues(alpha: 0.4)..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(plungerX - 8, centerY - (barrelHeight / 2) + 2, 8, barrelHeight - 4), 
      stopperPaint
    );

    // 5. Draw Tip
    canvas.drawRect(
        Rect.fromLTWH(startX - 10, centerY - 4, 10, 8),
        Paint()..color = Colors.black.withValues(alpha: 0.2)..style = PaintingStyle.fill
    );

    canvas.restore();
  }

  void _drawParticles(Canvas canvas, double startX, double centerY, double liquidWidth, double barrelHeight) {
    final Paint particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.4)..style = PaintingStyle.fill;
    
    // Stable random seed
    final math.Random random = math.Random(5678); 
    for (int i = 0; i < 8; i++) {
        // Particles should flow towards the plunger (right side)
        double personalSpeed = 0.5 + random.nextDouble();
        double xOffset = (progress * 150 * personalSpeed + i * 30) % liquidWidth;
        double bx = startX + xOffset;
        
        double by = centerY + (math.sin(progress * 5 + i) * (barrelHeight * 0.3));
        
        // Only draw if within current liquid bounds
        if (bx < startX + liquidWidth - 5) {
            canvas.drawCircle(Offset(bx, by), 1.2, particlePaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant SyringePainter oldDelegate) => true;
}
