import 'package:flutter/material.dart';
import 'dart:math' as math;

class StethoscopePainter extends CustomPainter {
  final double progress;
  final double transition;
  final Color color;

  StethoscopePainter({
    required this.progress,
    required this.transition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - transition;
    if (opacity <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw sound waves emanating from chest piece
    _drawSoundWaves(canvas, center, opacity);

    // Draw stethoscope
    _drawStethoscope(canvas, center, size, opacity);
  }

  void _drawSoundWaves(Canvas canvas, Offset center, double opacity) {
    double beatCycle = (progress * 3) % 1.0;
    bool isBeating = beatCycle < 0.15 || (beatCycle > 0.2 && beatCycle < 0.35);

    if (isBeating) {
      double waveIntensity = beatCycle < 0.15
          ? math.sin(beatCycle / 0.15 * math.pi)
          : math.sin((beatCycle - 0.2) / 0.15 * math.pi) * 0.6;

      final Offset chestPieceCenter = Offset(center.dx, center.dy + 35);

      for (int i = 0; i < 3; i++) {
        double waveProgress = ((progress * 6 - i * 0.15) % 1.0);
        if (waveProgress < 0.5) {
          double radius = 25 + waveProgress * 40;
          double waveAlpha = (1 - waveProgress / 0.5) * 0.35 * waveIntensity;

          canvas.drawCircle(
            chestPieceCenter,
            radius,
            Paint()
              ..color = color.withValues(alpha: waveAlpha * opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 + (1 - waveProgress / 0.5) * 2
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
      }
    }
  }

  void _drawStethoscope(
      Canvas canvas, Offset center, Size size, double opacity) {
    // Positions - stethoscope hangs down with chest piece at bottom
    final Offset chestPieceCenter = Offset(center.dx, center.dy + 35);

    // Draw chest piece first (at bottom)
    _drawChestPiece(canvas, chestPieceCenter, opacity);

    // Draw the main tubing loop
    _drawTubing(canvas, center, chestPieceCenter, opacity);

    // Draw ear pieces at top
    _drawEarPieces(canvas, center, opacity);

    // Draw the binaurals (metal tubes connecting to earpieces)
    _drawBinaurals(canvas, center, opacity);
  }

  void _drawChestPiece(Canvas canvas, Offset center, double opacity) {
    const double outerRadius = 24;
    const double innerRadius = 18;

    // Shadow
    canvas.drawCircle(
      Offset(center.dx + 2, center.dy + 3),
      outerRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Outer metal ring (chrome/silver look)
    final Paint metalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFD8D8D8).withValues(alpha: opacity),
          const Color(0xFFFFFFFF).withValues(alpha: opacity),
          const Color(0xFFB0B0B0).withValues(alpha: opacity),
          const Color(0xFF888888).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, metalPaint);

    // Inner diaphragm (dark gray membrane)
    final Paint diaphragmPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF505050).withValues(alpha: opacity),
          const Color(0xFF303030).withValues(alpha: opacity),
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawCircle(center, innerRadius, diaphragmPaint);

    // Diaphragm texture rings
    for (int i = 1; i <= 2; i++) {
      canvas.drawCircle(
        center,
        innerRadius * (i / 3),
        Paint()
          ..color = const Color(0xFF606060).withValues(alpha: 0.4 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Metal ring highlight
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius - 2),
      -math.pi * 0.8,
      math.pi * 0.5,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Small stem connecting to tubing
    canvas.drawRRect(
      RRect.fromLTRBR(
        center.dx - 4,
        center.dy - outerRadius - 8,
        center.dx + 4,
        center.dy - outerRadius + 2,
        const Radius.circular(2),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFB0B0B0).withValues(alpha: opacity),
            const Color(0xFF808080).withValues(alpha: opacity),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(center.dx - 4, center.dy - outerRadius - 8, 8, 10)),
    );
  }

  void _drawTubing(
      Canvas canvas, Offset center, Offset chestPiece, double opacity) {
    // Main flexible tubing from chest piece going up and splitting
    final Offset tubeStart = Offset(chestPiece.dx, chestPiece.dy - 32);
    final Offset splitPoint = Offset(center.dx, center.dy - 25);

    // Tubing style (black rubber)
    final Paint tubePaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final Paint tubeHighlight = Paint()
      ..color = const Color(0xFF404040).withValues(alpha: 0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Main stem with slight curve
    final Path mainTube = Path()
      ..moveTo(tubeStart.dx, tubeStart.dy)
      ..quadraticBezierTo(
        tubeStart.dx - 5,
        (tubeStart.dy + splitPoint.dy) / 2,
        splitPoint.dx,
        splitPoint.dy,
      );

    canvas.drawPath(mainTube, tubePaint);
    canvas.drawPath(mainTube.shift(const Offset(-2, 0)), tubeHighlight);
  }

  void _drawBinaurals(Canvas canvas, Offset center, double opacity) {
    // The metal Y-shaped tubes that connect to ear pieces
    final Offset splitPoint = Offset(center.dx, center.dy - 25);
    final Offset leftEar = Offset(center.dx - 35, center.dy - 60);
    final Offset rightEar = Offset(center.dx + 35, center.dy - 60);

    // Metal binaural paint
    final Paint binauralPaint = Paint()
      ..color = const Color(0xFF909090).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final Paint binauralHighlight = Paint()
      ..color = const Color(0xFFD0D0D0).withValues(alpha: 0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left binaural
    final Path leftBinaural = Path()
      ..moveTo(splitPoint.dx, splitPoint.dy)
      ..quadraticBezierTo(
        splitPoint.dx - 25,
        splitPoint.dy - 10,
        leftEar.dx,
        leftEar.dy,
      );

    canvas.drawPath(leftBinaural, binauralPaint);
    canvas.drawPath(leftBinaural.shift(const Offset(-1, -0.5)), binauralHighlight);

    // Right binaural
    final Path rightBinaural = Path()
      ..moveTo(splitPoint.dx, splitPoint.dy)
      ..quadraticBezierTo(
        splitPoint.dx + 25,
        splitPoint.dy - 10,
        rightEar.dx,
        rightEar.dy,
      );

    canvas.drawPath(rightBinaural, binauralPaint);
    canvas.drawPath(rightBinaural.shift(const Offset(1, -0.5)), binauralHighlight);

    // Center connector piece
    canvas.drawCircle(
      splitPoint,
      6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB0B0B0).withValues(alpha: opacity),
            const Color(0xFF707070).withValues(alpha: opacity),
          ],
        ).createShader(Rect.fromCircle(center: splitPoint, radius: 6)),
    );
  }

  void _drawEarPieces(Canvas canvas, Offset center, double opacity) {
    final Offset leftEar = Offset(center.dx - 35, center.dy - 60);
    final Offset rightEar = Offset(center.dx + 35, center.dy - 60);

    for (final earPos in [leftEar, rightEar]) {
      bool isLeft = earPos.dx < center.dx;

      // Ear piece metal body
      final Paint earMetalPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFD0D0D0).withValues(alpha: opacity),
            const Color(0xFF909090).withValues(alpha: opacity),
          ],
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        ).createShader(Rect.fromCircle(center: earPos, radius: 7));

      canvas.drawCircle(earPos, 7, earMetalPaint);

      // Ear tip (soft black rubber, angled outward)
      final Offset tipOffset = Offset(
        earPos.dx + (isLeft ? -4 : 4),
        earPos.dy - 5,
      );

      canvas.drawOval(
        Rect.fromCenter(center: tipOffset, width: 8, height: 10),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF404040).withValues(alpha: opacity),
              const Color(0xFF202020).withValues(alpha: opacity),
            ],
          ).createShader(Rect.fromCenter(center: tipOffset, width: 8, height: 10)),
      );

      // Highlight on metal
      canvas.drawCircle(
        Offset(earPos.dx + (isLeft ? 2 : -2), earPos.dy - 2),
        2,
        Paint()..color = Colors.white.withValues(alpha: 0.4 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StethoscopePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      transition != oldDelegate.transition ||
      color != oldDelegate.color;
}
