import 'package:flutter/material.dart';
import 'dart:math' as math;

class ECGMonitorPainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;

  ECGMonitorPainter({
    required this.progress,
    required this.transition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double activeX = size.width * progress;
    
    // 1. Background Path (Faint)
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1 * (1.0 - transition))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path fullPath = Path();
    const int segments = 150;
    for (int i = 0; i <= segments; i++) {
        double x = (size.width / segments) * i;
        double y = _getStaticHeight(x);
        if (i == 0) {
          fullPath.moveTo(x, midY + y);
        } else {
          fullPath.lineTo(x, midY + y);
        }
    }
    canvas.drawPath(fullPath, backgroundPaint);

    // 2. The Active Trail (Comet effect)
    // We draw a path that ends at activeX and fades backwards
    final Paint activeLinePaint = Paint()
      ..color = color.withValues(alpha: 1.0 - transition)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint activeGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.5 * (1.0 - transition))
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Path trailPath = Path();
    // Only draw the last ~40 pixels of the path for the comet trail
    double trailStart = (activeX - 60).clamp(0, size.width);
    for (double x = trailStart; x <= activeX; x += 2) {
        double y = _getStaticHeight(x);
        if (x == trailStart) {
          trailPath.moveTo(x, midY + y);
        } else {
          trailPath.lineTo(x, midY + y);
        }
    }
    canvas.drawPath(trailPath, activeGlowPaint);
    canvas.drawPath(trailPath, activeLinePaint);

    // 3. The Traveling Dot (Brightest)
    final double currentY = midY + _getStaticHeight(activeX);
    canvas.drawCircle(
      Offset(activeX, currentY), 
      4.5, 
      Paint()..color = Colors.white.withValues(alpha: 1.0 - transition)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
    );
     canvas.drawCircle(
      Offset(activeX, currentY), 
      2.5, 
      Paint()..color = Colors.white
    );
  }

  double _getStaticHeight(double x) {
    // Normal ECG: P, QRS, T
    // Static cycle every 120 units
    double cycleX = x % 120;

    if (cycleX < 15) return 0;
    
    // P wave
    if (cycleX < 30) return -5 * math.sin((cycleX - 15) * math.pi / 15); 
    
    if (cycleX < 38) return 0;
    
    // QRS Complex
    if (cycleX < 42) return 4 * math.sin((cycleX - 38) * math.pi / 4);  // Q
    if (cycleX < 46) return -40 * math.sin((cycleX - 42) * math.pi / 4); // R Spike
    if (cycleX < 50) return 6 * math.sin((cycleX - 46) * math.pi / 4);  // S
    
    if (cycleX < 65) return 0;
    
    // T wave
    if (cycleX < 90) return -10 * math.sin((cycleX - 65) * math.pi / 25); 
    
    return 0;
  }

  @override
  bool shouldRepaint(covariant ECGMonitorPainter oldDelegate) => true;
}
