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
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 1.0 - transition)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1.0 - transition))
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path path = Path();
    final double midY = size.height / 2;
    
    // Technical Data in Corners (BPM, etc)
    _drawTechnicalData(canvas, size);

    // Grid (Medical Paper feel)
    _drawGrid(canvas, size);

    // The ECG Waveform
    // We'll generate a repeating P-QRS-T complex
    for (double x = 0; x < size.width; x++) {
      double y = _getECGHeight(x, size.width, progress, transition);
      if (x == 0) {
        path.moveTo(x, midY + y);
      } else {
        path.lineTo(x, midY + y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Draw a "lead" dot at the head of the line
    // Actually let's just make it a continuous wave for simplicity
    final double activeX = size.width * progress; 
    canvas.drawCircle(
      Offset(activeX, midY + _getECGHeight(activeX, size.width, progress, transition)), 
      3, 
      linePaint..style = PaintingStyle.fill
    );
  }

  double _getECGHeight(double x, double totalWidth, double progress, double transition) {
    // Normal ECG: P (small bump), Q (dip), R (spike), S (dip), T (medium bump)
    // Wrap x to create a repeating cycle
    double cycleX = (x + (progress * 100)) % 100;
    
    // Shut-off effect: flatten line as transition increases
    if (transition > 0.1) return 0;

    if (cycleX < 10) return 0; // Flat baseline
    if (cycleX < 20) return -5 * math.sin((cycleX - 10) * math.pi / 10); // P wave
    if (cycleX < 25) return 0;
    if (cycleX < 28) return 5 * math.sin((cycleX - 25) * math.pi / 3);  // Q dip
    if (cycleX < 32) return -40 * math.sin((cycleX - 28) * math.pi / 4); // R spike
    if (cycleX < 35) return 8 * math.sin((cycleX - 32) * math.pi / 3);  // S dip
    if (cycleX < 45) return 0;
    if (cycleX < 60) return -10 * math.sin((cycleX - 45) * math.pi / 15); // T wave
    
    return 0;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  void _drawTechnicalData(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.black26, 
      fontSize: 10, 
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace'
    );

    _drawText(canvas, "BPM: 72", const Offset(10, 10), textStyle);
    _drawText(canvas, "SpO2: 98%", Offset(size.width - 60, 10), textStyle);
    _drawText(canvas, "SYS/DIA: 120/80", Offset(10, size.height - 20), textStyle);
    _drawText(canvas, "TEMP: 36.6 C", Offset(size.width - 80, size.height - 20), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant ECGMonitorPainter oldDelegate) => true;
}
