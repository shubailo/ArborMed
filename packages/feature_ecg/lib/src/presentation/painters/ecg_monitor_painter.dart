import 'package:flutter/material.dart';
import 'dart:math' as math;

class ECGMonitorPainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;
  final int seed;

  ECGMonitorPainter({
    required this.progress,
    required this.transition,
    required this.color,
    this.seed = 42,
  });

  late final math.Random _random = math.Random(seed);

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    // Monitor dimensions
    const double bezelPadding = 12;
    const double bezelRadius = 16;
    final Rect monitorRect = Rect.fromLTWH(
      bezelPadding,
      bezelPadding,
      size.width - bezelPadding * 2,
      size.height - bezelPadding * 2,
    );

    // 1. Draw Monitor Bezel (outer frame)
    _drawMonitorFrame(canvas, monitorRect, bezelRadius, opacity);

    // 2. Draw Grid Lines (oscilloscope style)
    _drawGrid(canvas, monitorRect, bezelRadius, opacity);

    // 3. Draw ECG Waveform
    final double midY = size.height / 2;
    final double activeX = monitorRect.left + monitorRect.width * progress;

    // Background trace (faint)
    _drawBackgroundTrace(canvas, monitorRect, midY, opacity);

    // Active trail with phosphor glow
    _drawActiveTrail(canvas, monitorRect, midY, activeX, opacity);

    // R-spike pulse effect
    _drawRSpikePulse(canvas, size, midY, activeX, opacity);

    // Traveling dot
    _drawTravelingDot(canvas, midY, activeX, opacity);
  }

  void _drawMonitorFrame(
      Canvas canvas, Rect rect, double radius, double opacity) {
    // Outer bezel shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(4), Radius.circular(radius + 4)),
      shadowPaint,
    );

    // Bezel (dark frame)
    final Paint bezelPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      bezelPaint,
    );

    // Inner screen area (darker)
    final Paint screenPaint = Paint()
      ..color = const Color(0xFF0D1810).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(radius - 2)),
      screenPaint,
    );

    // Inner glow edge
    final Paint innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.05 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(radius - 2)),
      innerGlowPaint,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect, double radius, double opacity) {
    final Paint gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08 * opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Save and clip to monitor area
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(radius - 2)));

    // Vertical lines
    const double gridSpacing = 20;
    for (double x = rect.left; x <= rect.right; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = rect.top; y <= rect.bottom; y += gridSpacing) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        gridPaint,
      );
    }

    // Center line (brighter)
    final Paint centerLinePaint = Paint()
      ..color = color.withValues(alpha: 0.15 * opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      centerLinePaint,
    );

    canvas.restore();
  }

  void _drawBackgroundTrace(
      Canvas canvas, Rect rect, double midY, double opacity) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.12 * opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path fullPath = Path();
    const int segments = 180;
    for (int i = 0; i <= segments; i++) {
      double x = rect.left + (rect.width / segments) * i;
      double y = _getOrganicHeight(x, rect.left);
      if (i == 0) {
        fullPath.moveTo(x, midY + y);
      } else {
        fullPath.lineTo(x, midY + y);
      }
    }
    canvas.drawPath(fullPath, backgroundPaint);
  }

  void _drawActiveTrail(Canvas canvas, Rect rect, double midY, double activeX,
      double opacity) {
    // Extended phosphor trail with exponential fade
    const double trailLength = 80;
    double trailStart = (activeX - trailLength).clamp(rect.left, rect.right);

    // Draw multiple layers for bloom effect
    for (int layer = 0; layer < 3; layer++) {
      final double layerWidth = 2.0 + layer * 3.0;
      final double layerAlpha = (layer == 0 ? 1.0 : 0.3 / layer) * opacity;

      final Paint trailPaint = Paint()
        ..strokeWidth = layerWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (layer > 0) {
        trailPaint.maskFilter =
            MaskFilter.blur(BlurStyle.normal, layer * 3.0);
      }

      // Create gradient shader for trail fade
      trailPaint.shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: layerAlpha * 0.3),
          color.withValues(alpha: layerAlpha),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTRB(trailStart, 0, activeX, 1));

      final Path trailPath = Path();
      bool started = false;
      for (double x = trailStart; x <= activeX; x += 1.5) {
        double y = _getOrganicHeight(x, rect.left);
        if (!started) {
          trailPath.moveTo(x, midY + y);
          started = true;
        } else {
          trailPath.lineTo(x, midY + y);
        }
      }
      canvas.drawPath(trailPath, trailPaint);
    }
  }

  void _drawRSpikePulse(Canvas canvas, Size size, double midY, double activeX,
      double opacity) {
    // Check if we're near an R-spike
    double cycleX = (activeX - 12) % 120; // Offset for the cycle
    bool nearRSpike = cycleX >= 42 && cycleX <= 50;

    if (nearRSpike) {
      double pulseIntensity = 1.0 - ((cycleX - 46).abs() / 4).clamp(0.0, 1.0);

      // Radial pulse glow
      final Paint pulsePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.25 * pulseIntensity * opacity),
            color.withValues(alpha: 0.08 * pulseIntensity * opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(activeX, midY + _getOrganicHeight(activeX, 12)),
          radius: 50,
        ));

      canvas.drawCircle(
        Offset(activeX, midY + _getOrganicHeight(activeX, 12)),
        50,
        pulsePaint,
      );
    }
  }

  void _drawTravelingDot(
      Canvas canvas, double midY, double activeX, double opacity) {
    final double currentY = midY + _getOrganicHeight(activeX, 12);

    // Outer glow
    canvas.drawCircle(
      Offset(activeX, currentY),
      8,
      Paint()
        ..color = color.withValues(alpha: 0.4 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Middle glow
    canvas.drawCircle(
      Offset(activeX, currentY),
      5,
      Paint()
        ..color = color.withValues(alpha: 0.7 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Bright core
    canvas.drawCircle(
      Offset(activeX, currentY),
      3,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  double _getOrganicHeight(double x, double offset) {
    // Organic ECG with slight variations
    double cycleX = (x - offset) % 120;

    // Add subtle baseline wander
    double wander = math.sin(x * 0.02) * 2;

    // Add micro-variations (±5%)
    double variation = 1.0 + (_random.nextDouble() - 0.5) * 0.1;

    if (cycleX < 15) return wander;

    // P wave (atrial depolarization)
    if (cycleX < 30) {
      return (-5 * math.sin((cycleX - 15) * math.pi / 15) * variation) + wander;
    }

    if (cycleX < 38) return wander;

    // QRS Complex
    if (cycleX < 42) {
      // Q wave (small dip)
      return (4 * math.sin((cycleX - 38) * math.pi / 4) * variation) + wander;
    }
    if (cycleX < 46) {
      // R spike (tall peak)
      double rHeight = -42 * math.sin((cycleX - 42) * math.pi / 4);
      return (rHeight * variation) + wander;
    }
    if (cycleX < 50) {
      // S wave (small dip)
      return (6 * math.sin((cycleX - 46) * math.pi / 4) * variation) + wander;
    }

    if (cycleX < 65) return wander;

    // T wave (ventricular repolarization)
    if (cycleX < 90) {
      return (-10 * math.sin((cycleX - 65) * math.pi / 25) * variation) +
          wander;
    }

    return wander;
  }

  @override
  bool shouldRepaint(covariant ECGMonitorPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      transition != oldDelegate.transition ||
      color != oldDelegate.color;
}
