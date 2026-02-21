import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'dart:math' as math;

class ECGMonitorWidget extends StatefulWidget {
  final Color? color;
  final double height;
  final double width;

  const ECGMonitorWidget({
    super.key,
    this.color,
    this.height = 120,
    this.width = 240,
  });

  @override
  State<ECGMonitorWidget> createState() => _ECGMonitorWidgetState();
}

class _ECGMonitorWidgetState extends State<ECGMonitorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ECGMonitorPainter(
              progress: _controller.value,
              transition: 0.0,
              color: widget.color ?? AppTheme.sageGreen,
            ),
          );
        },
      ),
    );
  }
}

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


  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    const double bezelPadding = 8;
    const double bezelRadius = 12;
    final Rect monitorRect = Rect.fromLTWH(
      bezelPadding,
      bezelPadding,
      size.width - bezelPadding * 2,
      size.height - bezelPadding * 2,
    );

    _drawMonitorFrame(canvas, monitorRect, bezelRadius, opacity);
    _drawGrid(canvas, monitorRect, bezelRadius, opacity);

    final double midY = size.height / 2;
    final double activeX = monitorRect.left + monitorRect.width * progress;

    _drawBackgroundTrace(canvas, monitorRect, midY, opacity);
    _drawActiveTrail(canvas, monitorRect, midY, activeX, opacity);
    _drawRSpikePulse(canvas, size, midY, activeX, opacity);
    _drawTravelingDot(canvas, midY, activeX, opacity);
  }

  void _drawMonitorFrame(
      Canvas canvas, Rect rect, double radius, double opacity) {
    final Paint bezelPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      bezelPaint,
    );

    final Paint screenPaint = Paint()
      ..color = const Color(0xFF0D1810).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(radius - 2)),
      screenPaint,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect, double radius, double opacity) {
    final Paint gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08 * opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(radius - 2)));

    const double gridSpacing = 20;
    for (double x = rect.left; x <= rect.right; x += gridSpacing) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
    for (double y = rect.top; y <= rect.bottom; y += gridSpacing) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
    canvas.restore();
  }

  void _drawBackgroundTrace(
      Canvas canvas, Rect rect, double midY, double opacity) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.12 * opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Path fullPath = Path();
    const int segments = 100;
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
    const double trailLength = 60;
    double trailStart = (activeX - trailLength).clamp(rect.left, rect.right);

    final Paint trailPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    trailPaint.shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8 * opacity),
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromLTRB(trailStart, 0, activeX, 1));

    final Path trailPath = Path();
    bool started = false;
    for (double x = trailStart; x <= activeX; x += 2) {
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

  void _drawRSpikePulse(Canvas canvas, Size size, double midY, double activeX,
      double opacity) {
    double cycleX = (activeX - 12) % 120;
    bool nearRSpike = cycleX >= 42 && cycleX <= 50;

    if (nearRSpike) {
      double pulseIntensity = 1.0 - ((cycleX - 46).abs() / 4).clamp(0.0, 1.0);
      final Paint pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.15 * pulseIntensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(activeX, midY), 40, pulsePaint);
    }
  }

  void _drawTravelingDot(
      Canvas canvas, double midY, double activeX, double opacity) {
    final double currentY = midY + _getOrganicHeight(activeX, 12);
    canvas.drawCircle(
      Offset(activeX, currentY),
      4,
      Paint()
        ..color = color.withValues(alpha: 0.8 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(activeX, currentY),
      2,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  double _getOrganicHeight(double x, double offset) {
    double cycleX = (x - offset) % 120;
    double wander = math.sin(x * 0.02) * 2;
    if (cycleX < 30 && cycleX > 15) {
      return (-5 * math.sin((cycleX - 15) * math.pi / 15)) + wander;
    }
    if (cycleX >= 38 && cycleX < 42) {
      return (4 * math.sin((cycleX - 38) * math.pi / 4)) + wander;
    }
    if (cycleX >= 42 && cycleX < 46) {
      return (-42 * math.sin((cycleX - 42) * math.pi / 4)) + wander;
    }
    if (cycleX >= 46 && cycleX < 50) {
      return (6 * math.sin((cycleX - 46) * math.pi / 4)) + wander;
    }
    if (cycleX >= 65 && cycleX < 90) {
      return (-10 * math.sin((cycleX - 65) * math.pi / 25)) + wander;
    }
    return wander;
  }

  @override
  bool shouldRepaint(covariant ECGMonitorPainter oldDelegate) => true;
}
