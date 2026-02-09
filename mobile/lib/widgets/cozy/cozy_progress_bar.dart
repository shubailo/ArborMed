import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/cozy_theme.dart';

class CozyProgressBar extends StatefulWidget {
  final int current;
  final int total;
  final double height;
  /// Optional notifier that triggers a pulse animation (e.g., on level-up)
  final ChangeNotifier? pulseNotifier;

  const CozyProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.height = 14,
    this.pulseNotifier,
  });

  @override
  createState() => _CozyProgressBarState();
}

class _CozyProgressBarState extends State<CozyProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    // Pulse animation for level-up celebration
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic));

    widget.pulseNotifier?.addListener(_onPulse);
  }

  void _onPulse() {
    _pulseController.forward(from: 0);
  }

  @override
  void didUpdateWidget(CozyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseNotifier != widget.pulseNotifier) {
      oldWidget.pulseNotifier?.removeListener(_onPulse);
      widget.pulseNotifier?.addListener(_onPulse);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    widget.pulseNotifier?.removeListener(_onPulse);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(
              end: widget.total > 0
                  ? (widget.current / widget.total).clamp(0.0, 1.0)
                  : 0.0,
            ),
            builder: (context, percentage, child) {
              return Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: palette.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(widget.height),
                  border: Border.all(
                    color: palette.textPrimary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ],
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
                              color: palette.primary.withValues(alpha: 0.4),
                              waveSpeed: 0.8,
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
                              color: palette.primary,
                              waveSpeed: 1.2,
                              waveOffset: math.pi,
                            ),
                            size: Size.infinite,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
    path.lineTo(0, 0);

    for (double i = 0; i <= size.height; i++) {
      double dx = math.sin((animationValue * 2 * math.pi * waveSpeed) +
              (i / 10) +
              waveOffset) *
          waveHeight;
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
