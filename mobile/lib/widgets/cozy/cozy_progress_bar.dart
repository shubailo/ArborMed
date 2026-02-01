import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/cozy_theme.dart';

class CozyProgressBar extends StatefulWidget {
  final int current;
  final int total;
  final double height;

  const CozyProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.height = 14, // Slightly thicker for liquid effect
  });

  @override
  createState() => _CozyProgressBarState();
}

class _CozyProgressBarState extends State<CozyProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 2)
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percentage = (widget.current / widget.total).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: CozyTheme.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(widget.height),
        // Glass border effect
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.0),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)) // Inner shadow sim
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height),
        child: Stack(
          children: [
            // Background Water (Darker, Slower)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                   painter: _LiquidPainter(
                     animationValue: _controller.value,
                     percentage: percentage,
                     color: CozyTheme.primary.withValues(alpha: 0.5),
                     waveSpeed: 1.0,
                     waveOffset: 0.0,
                   ),
                   size: Size.infinite,
                );
              },
            ),
            
            // Foreground Water (Lighter, Faster)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                 return CustomPaint(
                   painter: _LiquidPainter(
                     animationValue: _controller.value,
                     percentage: percentage,
                     color: CozyTheme.primary,
                     waveSpeed: 1.5,
                     waveOffset: math.pi,
                   ),
                   size: Size.infinite,
                 );
              },
            ),

            // Top Glare (Glass Tube Effect)
            Container(
              height: widget.height / 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)]
                 ),
                 borderRadius: BorderRadius.circular(widget.height),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color color;
  final double waveSpeed;
  final double waveOffset;

  _LiquidPainter({
    required this.animationValue,
    required this.percentage,
    required this.color,
    this.waveSpeed = 1.0,
    this.waveOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();

    // 0% -> Flat, 100% -> Flat. Waves only in between.
    // Dampen waves at extremes to avoid clipping weirdness
    double waveHeight = 2.0; 
    if (percentage < 0.05 || percentage > 0.95) waveHeight = 0.5;

    double baseWidth = size.width * percentage;
    
    path.moveTo(0, size.height);
    path.lineTo(0, 0); // Start top-left (ish) - actually we fill from left

    // Draw wave along the right edge of the fill
    // Actually, for a horizontal bar, the "Top" surface doesn't wave... the "Right" edge waves?
    // Wait, typical liquid bars fill vertical. 
    // For horizontal, maybe we just want the 'texture' to wave? 
    // User asked for "Liquid". Let's make the *fill* wobble.
    
    // Changing approach: Draw a rect that IS the fill, but the right edge is a wave?
    // Or just a texture moving inside?
    // Let's do: Right edge is vertical, but the Top edge is a wave? NO, that's for vertical fill.
    
    // Horizontal fill liquid effect:
    // Usually means the "surface" is on the right. So the right edge should curve.
    
    for (double i = 0; i <= size.height; i++) {
       // Wave equation
       double dx = math.sin((animationValue * 2 * math.pi * waveSpeed) + (i / 10) + waveOffset) * waveHeight;
       // Add to base width
       if (i == 0) {
         path.lineTo(baseWidth + dx, 0);
       } else {
         path.lineTo(baseWidth + dx, i);
       }
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) => true;
}
