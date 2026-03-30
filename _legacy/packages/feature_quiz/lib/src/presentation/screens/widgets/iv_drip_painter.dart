import 'package:flutter/material.dart';
import 'dart:math' as math;

class IVDripPainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;

  IVDripPainter({
    required this.progress,
    required this.transition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    final double centerX = size.width / 2;

    // Draw IV bag
    _drawIVBag(canvas, centerX, 20, opacity);

    // Draw drip chamber
    _drawDripChamber(canvas, centerX, 75, opacity);

    // Draw tubing
    _drawTubing(canvas, centerX, 115, size.height - 20, opacity);

    // Draw falling droplets
    _drawDroplets(canvas, centerX, 75, 115, opacity);
  }

  void _drawIVBag(
      Canvas canvas, double centerX, double topY, double opacity) {
    const double bagWidth = 70;
    const double bagHeight = 50;

    // Bag shadow
    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - bagWidth / 2 + 3,
        topY + 4,
        centerX + bagWidth / 2 + 3,
        topY + bagHeight + 4,
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Bag body (translucent plastic)
    final Paint bagPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE8F0F8).withValues(alpha: 0.9 * opacity),
          const Color(0xFFD0E0F0).withValues(alpha: 0.85 * opacity),
          const Color(0xFFE0ECF5).withValues(alpha: 0.9 * opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
          centerX - bagWidth / 2, topY, bagWidth, bagHeight));

    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - bagWidth / 2,
        topY,
        centerX + bagWidth / 2,
        topY + bagHeight,
        const Radius.circular(8),
      ),
      bagPaint,
    );

    // Fluid inside bag (decreasing as progress increases)
    double fluidLevel = 1.0 - (progress * 0.4); // Drain 40% over animation
    double fluidHeight = (bagHeight - 12) * fluidLevel;
    double fluidTop = topY + bagHeight - 6 - fluidHeight;

    if (fluidHeight > 4) {
      final Paint fluidPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.5 * opacity),
            color.withValues(alpha: 0.6 * opacity),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(
            centerX - bagWidth / 2 + 6, fluidTop, bagWidth - 12, fluidHeight));

      canvas.drawRRect(
        RRect.fromLTRBR(
          centerX - bagWidth / 2 + 6,
          fluidTop,
          centerX + bagWidth / 2 - 6,
          topY + bagHeight - 6,
          const Radius.circular(4),
        ),
        fluidPaint,
      );
    }

    // Bag border
    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - bagWidth / 2,
        topY,
        centerX + bagWidth / 2,
        topY + bagHeight,
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFFB0C0D0).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Hanging loop
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(centerX, topY - 5), width: 20, height: 12),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF90A0B0).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDripChamber(
      Canvas canvas, double centerX, double topY, double opacity) {
    const double chamberWidth = 20;
    const double chamberHeight = 35;

    // Chamber body
    final Paint chamberPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFF5F8FA).withValues(alpha: 0.95 * opacity),
          const Color(0xFFE8EEF2).withValues(alpha: 0.9 * opacity),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(
          centerX - chamberWidth / 2, topY, chamberWidth, chamberHeight));

    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - chamberWidth / 2,
        topY,
        centerX + chamberWidth / 2,
        topY + chamberHeight,
        const Radius.circular(4),
      ),
      chamberPaint,
    );

    // Fluid level in chamber (lower third)
    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - chamberWidth / 2 + 2,
        topY + chamberHeight * 0.6,
        centerX + chamberWidth / 2 - 2,
        topY + chamberHeight - 3,
        const Radius.circular(2),
      ),
      Paint()..color = color.withValues(alpha: 0.5 * opacity),
    );

    // Chamber border
    canvas.drawRRect(
      RRect.fromLTRBR(
        centerX - chamberWidth / 2,
        topY,
        centerX + chamberWidth / 2,
        topY + chamberHeight,
        const Radius.circular(4),
      ),
      Paint()
        ..color = const Color(0xFFC0D0E0).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Connector to bag
    canvas.drawRect(
      Rect.fromLTWH(centerX - 3, topY - 5, 6, 6),
      Paint()..color = const Color(0xFF90A0B0).withValues(alpha: opacity),
    );
  }

  void _drawTubing(Canvas canvas, double centerX, double topY, double bottomY,
      double opacity) {
    // Main tube with subtle curve
    final Path tubePath = Path();
    tubePath.moveTo(centerX, topY);
    tubePath.quadraticBezierTo(
      centerX + 8,
      (topY + bottomY) / 2,
      centerX,
      bottomY,
    );

    // Tube shadow
    canvas.drawPath(
      tubePath.shift(const Offset(2, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Tube body
    canvas.drawPath(
      tubePath,
      Paint()
        ..color = const Color(0xFFE0E8F0).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Tube highlight
    canvas.drawPath(
      tubePath.shift(const Offset(-1, 0)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Flowing liquid indicator (animated stripe)
    double flowOffset = (progress * 200) % 40;
    for (double y = topY + flowOffset; y < bottomY; y += 40) {
      double t = (y - topY) / (bottomY - topY);
      double x = centerX + 8 * math.sin(t * math.pi);

      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = color.withValues(alpha: 0.4 * opacity),
      );
    }
  }

  void _drawDroplets(Canvas canvas, double centerX, double chamberTop,
      double chamberBottom, double opacity) {
    // Droplets falling inside drip chamber
    double dropCycle = (progress * 8) % 1.0; // 8 drops over animation

    // Only draw drop during falling phase
    if (dropCycle < 0.5) {
      double dropProgress = dropCycle / 0.5;
      double dropY = chamberTop + 12 + (chamberBottom - chamberTop - 24) *
          _easeInQuad(dropProgress);

      // Droplet forming at top
      if (dropProgress < 0.2) {
        double formSize = 3 + dropProgress * 5;
        canvas.drawCircle(
          Offset(centerX, chamberTop + 10),
          formSize,
          Paint()..color = color.withValues(alpha: 0.6 * opacity),
        );
      }

      // Falling droplet
      if (dropProgress >= 0.15) {
        double dropSize = 4 * (1 - dropProgress * 0.3);

        // Droplet glow
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, dropY),
            width: dropSize * 2 + 4,
            height: dropSize * 2.5 + 4,
          ),
          Paint()
            ..color = color.withValues(alpha: 0.2 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        // Droplet body (teardrop shape)
        final Path dropPath = Path();
        dropPath.moveTo(centerX, dropY - dropSize * 1.5);
        dropPath.quadraticBezierTo(
          centerX + dropSize,
          dropY,
          centerX,
          dropY + dropSize,
        );
        dropPath.quadraticBezierTo(
          centerX - dropSize,
          dropY,
          centerX,
          dropY - dropSize * 1.5,
        );

        canvas.drawPath(
          dropPath,
          Paint()..color = color.withValues(alpha: 0.7 * opacity),
        );

        // Droplet highlight
        canvas.drawCircle(
          Offset(centerX - dropSize * 0.3, dropY - dropSize * 0.3),
          dropSize * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * opacity),
        );
      }

      // Splash effect at bottom
      if (dropProgress > 0.9) {
        double splashIntensity = (dropProgress - 0.9) / 0.1;
        double splashY = chamberBottom - 8;

        for (int i = 0; i < 3; i++) {
          double angle = (i - 1) * 0.5;
          double splashX = centerX + math.sin(angle) * splashIntensity * 8;
          double splashYOffset = splashY - splashIntensity * 4;

          canvas.drawCircle(
            Offset(splashX, splashYOffset),
            1.5 * (1 - splashIntensity * 0.5),
            Paint()..color = color.withValues(alpha: 0.5 * opacity *
                (1 - splashIntensity)),
          );
        }
      }
    }
  }

  double _easeInQuad(double t) => t * t;

  @override
  bool shouldRepaint(covariant IVDripPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      transition != oldDelegate.transition ||
      color != oldDelegate.color;
}
