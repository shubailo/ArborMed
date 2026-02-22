import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeartbeatPainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;

  HeartbeatPainter({
    required this.progress,
    required this.transition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);

    // Heartbeat rhythm: beat every ~1 second (at 3s animation = 3 beats)
    double beatCycle = (progress * 3) % 1.0;
    double beatPhase = _getHeartbeatPhase(beatCycle);

    // Draw arterial pulse rings
    _drawPulseRings(canvas, center, beatPhase, opacity);

    // Draw anatomical heart
    _drawHeart(canvas, center, beatPhase, opacity);
  }

  double _getHeartbeatPhase(double cycle) {
    // Quick systole (0.0-0.15), pause, quick diastole (0.2-0.35), long pause
    if (cycle < 0.15) {
      // Systole (contraction) - scale up
      return math.sin(cycle / 0.15 * math.pi) * 0.12;
    } else if (cycle < 0.2) {
      // Brief pause at peak
      return 0.12 * (1 - (cycle - 0.15) / 0.05);
    } else if (cycle < 0.35) {
      // Diastole (relaxation) - secondary smaller beat
      return math.sin((cycle - 0.2) / 0.15 * math.pi) * 0.06;
    }
    // Rest phase
    return 0;
  }

  void _drawPulseRings(
      Canvas canvas, Offset center, double beatPhase, double opacity) {
    // Arterial pulse waves radiating outward
    double beatCycle = (progress * 3) % 1.0;

    for (int i = 0; i < 3; i++) {
      double ringProgress = ((beatCycle - i * 0.2) % 1.0);
      if (ringProgress < 0) ringProgress += 1.0;

      if (ringProgress < 0.6) {
        double ringRadius = 40 + ringProgress * 80;
        double ringAlpha = (1 - ringProgress / 0.6) * 0.3;

        canvas.drawCircle(
          center,
          ringRadius,
          Paint()
            ..color = color.withValues(alpha: ringAlpha * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + (1 - ringProgress / 0.6) * 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  void _drawHeart(
      Canvas canvas, Offset center, double beatPhase, double opacity) {
    // Heart base scale with beat animation
    double scale = 1.0 + beatPhase;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    // Heart shadow
    _drawHeartShape(
      canvas,
      Offset(center.dx + 3, center.dy + 4),
      40,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Heart glow (during beat)
    if (beatPhase > 0.02) {
      _drawHeartShape(
        canvas,
        center,
        44,
        Paint()
          ..color = color.withValues(alpha: 0.4 * beatPhase * 8 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Main heart body with gradient
    final Paint heartPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.red[400]!.withValues(alpha: opacity),
          Colors.red[700]!.withValues(alpha: opacity),
          Colors.red[900]!.withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: 45));

    _drawHeartShape(canvas, center, 40, heartPaint);

    // Highlight on heart
    final Paint highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
        center: const Alignment(-0.5, -0.5),
      ).createShader(Rect.fromCircle(center: center, radius: 35));

    _drawHeartShape(canvas, center, 35, highlightPaint);

    canvas.restore();
  }

  void _drawHeartShape(
      Canvas canvas, Offset center, double size, Paint paint) {
    final Path heartPath = Path();

    // Classic heart shape with two lobes
    double w = size;
    double h = size * 1.0;

    // Start at the bottom point
    heartPath.moveTo(center.dx, center.dy + h * 0.4);

    // Left side curve (bottom to top of left lobe)
    heartPath.cubicTo(
      center.dx - w * 0.5, center.dy + h * 0.1,  // control point 1
      center.dx - w * 0.5, center.dy - h * 0.3,  // control point 2
      center.dx - w * 0.25, center.dy - h * 0.4, // end at top of left lobe
    );

    // Top of left lobe to center dip
    heartPath.cubicTo(
      center.dx - w * 0.1, center.dy - h * 0.45, // control point 1
      center.dx, center.dy - h * 0.25,           // control point 2
      center.dx, center.dy - h * 0.2,            // center dip
    );

    // Center dip to top of right lobe
    heartPath.cubicTo(
      center.dx, center.dy - h * 0.25,           // control point 1
      center.dx + w * 0.1, center.dy - h * 0.45, // control point 2
      center.dx + w * 0.25, center.dy - h * 0.4, // top of right lobe
    );

    // Right side curve (top of right lobe to bottom point)
    heartPath.cubicTo(
      center.dx + w * 0.5, center.dy - h * 0.3,  // control point 1
      center.dx + w * 0.5, center.dy + h * 0.1,  // control point 2
      center.dx, center.dy + h * 0.4,            // back to bottom point
    );

    heartPath.close();
    canvas.drawPath(heartPath, paint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      transition != oldDelegate.transition ||
      color != oldDelegate.color;
}
