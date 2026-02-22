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
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    // Setup rotation (tilted upward 30 degrees)
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-size.width / 2, -size.height / 2);

    const double padding = 35;
    final double barrelWidth = size.width - (padding * 2) - 30;
    final double barrelHeight = 44;
    final double centerY = size.height / 2;
    final double startX = padding + 25;

    // Draw components in order
    _drawShadow(canvas, startX, centerY, barrelWidth, barrelHeight, opacity);
    _drawNeedle(canvas, startX, centerY, opacity);
    _drawBarrel(canvas, startX, centerY, barrelWidth, barrelHeight, opacity);
    _drawLiquid(canvas, startX, centerY, barrelWidth, barrelHeight, opacity);
    _drawGlassReflections(
        canvas, startX, centerY, barrelWidth, barrelHeight, opacity);
    _drawPlunger(canvas, startX, centerY, barrelWidth, barrelHeight, opacity);
    _drawGraduationMarks(
        canvas, startX, centerY, barrelWidth, barrelHeight, opacity);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(
      RRect.fromLTRBR(
        startX + 4,
        centerY - (barrelHeight / 2) + 6,
        startX + barrelWidth + 4,
        centerY + (barrelHeight / 2) + 6,
        const Radius.circular(10),
      ),
      shadowPaint,
    );
  }

  void _drawNeedle(
      Canvas canvas, double startX, double centerY, double opacity) {
    // Needle hub (metal connector)
    final Paint hubPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF8B8B8B).withValues(alpha: opacity),
          const Color(0xFFD4D4D4).withValues(alpha: opacity),
          const Color(0xFF9A9A9A).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.4, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(startX - 18, centerY - 8, 18, 16));

    canvas.drawRRect(
      RRect.fromLTRBR(startX - 18, centerY - 8, startX, centerY + 8,
          const Radius.circular(3)),
      hubPaint,
    );

    // Needle shaft (metallic gradient)
    final Paint needlePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFB8B8B8).withValues(alpha: opacity),
          const Color(0xFFE8E8E8).withValues(alpha: opacity),
          const Color(0xFFA0A0A0).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.3, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(startX - 45, centerY - 2, 27, 4));

    // Main needle body
    canvas.drawRect(
      Rect.fromLTWH(startX - 45, centerY - 1.5, 27, 3),
      needlePaint,
    );

    // Bevel tip (angled cut)
    final Path tipPath = Path()
      ..moveTo(startX - 45, centerY - 1.5)
      ..lineTo(startX - 52, centerY)
      ..lineTo(startX - 45, centerY + 1.5)
      ..close();

    canvas.drawPath(tipPath, needlePaint);

    // Tiny highlight on needle
    canvas.drawLine(
      Offset(startX - 44, centerY - 0.5),
      Offset(startX - 20, centerY - 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * opacity)
        ..strokeWidth = 0.8,
    );
  }

  void _drawBarrel(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    // Glass barrel with subtle blue tint
    final Paint barrelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFF5F8FA).withValues(alpha: 0.9 * opacity),
          const Color(0xFFE8EEF2).withValues(alpha: 0.85 * opacity),
          const Color(0xFFF0F4F7).withValues(alpha: 0.9 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
          startX, centerY - barrelHeight / 2, barrelWidth, barrelHeight));

    final RRect barrelRect = RRect.fromLTRBR(
      startX,
      centerY - (barrelHeight / 2),
      startX + barrelWidth,
      centerY + (barrelHeight / 2),
      const Radius.circular(10),
    );

    canvas.drawRRect(barrelRect, barrelPaint);

    // Glass edge highlight
    final Paint edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromLTRBR(
        startX + 1,
        centerY - (barrelHeight / 2) + 1,
        startX + barrelWidth - 1,
        centerY + (barrelHeight / 2) - 1,
        const Radius.circular(9),
      ),
      edgePaint,
    );

    // Outer border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFCCD5DC).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(barrelRect, borderPaint);
  }

  void _drawLiquid(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    double fillProgress = progress.clamp(0.0, 1.0);
    double liquidWidth = (barrelWidth - 8) * fillProgress;

    if (liquidWidth < 4) return;

    // Blood-red gradient
    final Paint liquidPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.red[900]!.withValues(alpha: 0.9 * opacity),
          Colors.red[600]!.withValues(alpha: 0.85 * opacity),
          Colors.red[800]!.withValues(alpha: 0.9 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(startX + 4, centerY - barrelHeight / 2 + 4,
          liquidWidth, barrelHeight - 8));

    // Liquid body
    final RRect liquidRect = RRect.fromLTRBAndCorners(
      startX + 4,
      centerY - (barrelHeight / 2) + 4,
      startX + 4 + liquidWidth,
      centerY + (barrelHeight / 2) - 4,
      topLeft: const Radius.circular(7),
      bottomLeft: const Radius.circular(7),
    );

    canvas.drawRRect(liquidRect, liquidPaint);

    // Meniscus effect (curved edge on liquid surface)
    if (liquidWidth > 10) {
      final Path meniscusPath = Path();
      double meniscusX = startX + 4 + liquidWidth;

      meniscusPath.moveTo(meniscusX - 3, centerY - (barrelHeight / 2) + 4);
      meniscusPath.quadraticBezierTo(
        meniscusX + 2,
        centerY,
        meniscusX - 3,
        centerY + (barrelHeight / 2) - 4,
      );
      meniscusPath.lineTo(meniscusX - 3, centerY - (barrelHeight / 2) + 4);

      final Paint meniscusPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.red[700]!.withValues(alpha: 0.7 * opacity),
            Colors.red[900]!.withValues(alpha: 0.9 * opacity),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(meniscusX - 5, centerY - barrelHeight / 2,
            10, barrelHeight));

      canvas.drawPath(meniscusPath, meniscusPaint);
    }

    // Air bubbles
    _drawBubbles(canvas, startX, centerY, liquidWidth, barrelHeight, opacity);
  }

  void _drawBubbles(Canvas canvas, double startX, double centerY,
      double liquidWidth, double barrelHeight, double opacity) {
    final math.Random random = math.Random(1234);

    for (int i = 0; i < 6; i++) {
      double bubbleSpeed = 0.3 + random.nextDouble() * 0.4;
      double xBase = random.nextDouble() * 0.7;
      double yOffset = random.nextDouble() * 0.6 - 0.3;

      // Bubbles rise slowly upward
      double bubbleY = centerY +
          (barrelHeight * yOffset * 0.4) -
          (progress * bubbleSpeed * 30) % (barrelHeight * 0.4);

      double bubbleX = startX + 8 + (liquidWidth * xBase);

      if (bubbleX < startX + 4 + liquidWidth - 5 && bubbleX > startX + 8) {
        double bubbleSize = 1.5 + random.nextDouble() * 2;

        // Bubble glow
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleSize + 1,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );

        // Bubble body
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleSize,
          Paint()..color = Colors.white.withValues(alpha: 0.35 * opacity),
        );

        // Bubble highlight
        canvas.drawCircle(
          Offset(bubbleX - bubbleSize * 0.3, bubbleY - bubbleSize * 0.3),
          bubbleSize * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.6 * opacity),
        );
      }
    }
  }

  void _drawGlassReflections(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    // Top diagonal reflection stripe
    final Paint reflectionPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.25 * opacity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
          startX, centerY - barrelHeight / 2, barrelWidth * 0.4, 8));

    canvas.drawRect(
      Rect.fromLTWH(
          startX + 8, centerY - (barrelHeight / 2) + 5, barrelWidth * 0.35, 4),
      reflectionPaint,
    );

    // Secondary subtle reflection
    canvas.drawRect(
      Rect.fromLTWH(startX + barrelWidth * 0.5,
          centerY - (barrelHeight / 2) + 6, barrelWidth * 0.2, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.12 * opacity),
    );
  }

  void _drawPlunger(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    double fillProgress = progress.clamp(0.0, 1.0);
    double plungerX = startX + 4 + ((barrelWidth - 8) * fillProgress);

    // Rubber stopper (dark with texture gradient)
    final Paint stopperPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF2A2A2A).withValues(alpha: opacity),
          const Color(0xFF404040).withValues(alpha: opacity),
          const Color(0xFF1A1A1A).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
          plungerX, centerY - barrelHeight / 2 + 4, 10, barrelHeight - 8));

    canvas.drawRRect(
      RRect.fromLTRBR(
        plungerX,
        centerY - (barrelHeight / 2) + 4,
        plungerX + 10,
        centerY + (barrelHeight / 2) - 4,
        const Radius.circular(2),
      ),
      stopperPaint,
    );

    // Stopper edge highlight
    canvas.drawLine(
      Offset(plungerX + 1, centerY - (barrelHeight / 2) + 6),
      Offset(plungerX + 1, centerY + (barrelHeight / 2) - 6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * opacity)
        ..strokeWidth = 1,
    );

    // Plunger rod
    final Paint rodPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF606060).withValues(alpha: opacity),
          const Color(0xFF909090).withValues(alpha: opacity),
          const Color(0xFF505050).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.4, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(plungerX + 10, centerY - 3, 80, 6));

    canvas.drawRect(
      Rect.fromLTWH(plungerX + 10, centerY - 2, 80, 4),
      rodPaint,
    );

    // Thumb rest
    final Paint thumbRestPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF707070).withValues(alpha: opacity),
          const Color(0xFFA0A0A0).withValues(alpha: opacity),
          const Color(0xFF606060).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.4, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
          Rect.fromLTWH(plungerX + 85, centerY - 18, 8, 36));

    canvas.drawRRect(
      RRect.fromLTRBR(
        plungerX + 85,
        centerY - 18,
        plungerX + 93,
        centerY + 18,
        const Radius.circular(3),
      ),
      thumbRestPaint,
    );
  }

  void _drawGraduationMarks(Canvas canvas, double startX, double centerY,
      double barrelWidth, double barrelHeight, double opacity) {
    final Paint markPaint = Paint()
      ..color = const Color(0xFF6080A0).withValues(alpha: 0.5 * opacity)
      ..strokeWidth = 0.8;

    // Draw graduation marks on barrel
    for (int i = 1; i <= 8; i++) {
      double markX = startX + (barrelWidth / 9) * i;
      double markHeight = (i % 2 == 0) ? 8 : 5;

      canvas.drawLine(
        Offset(markX, centerY - (barrelHeight / 2) + 3),
        Offset(markX, centerY - (barrelHeight / 2) + 3 + markHeight),
        markPaint,
      );

      canvas.drawLine(
        Offset(markX, centerY + (barrelHeight / 2) - 3),
        Offset(markX, centerY + (barrelHeight / 2) - 3 - markHeight),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SyringePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      transition != oldDelegate.transition ||
      color != oldDelegate.color;
}
