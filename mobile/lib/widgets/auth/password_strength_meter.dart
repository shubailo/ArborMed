import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/cozy_theme.dart';

class PasswordStrengthMeter extends StatefulWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  @override
  State<PasswordStrengthMeter> createState() => _PasswordStrengthMeterState();
}

class _PasswordStrengthMeterState extends State<PasswordStrengthMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  double _calculateStrength() {
    if (widget.password.isEmpty) return 0.0;
    
    double score = 0.0;
    if (widget.password.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(widget.password)) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(widget.password)) score += 0.25;
    if (RegExp(r'[@$!%*?&]').hasMatch(widget.password)) score += 0.25;
    
    return score;
  }

  Color _getStrengthColor(double strength, CozyPalette palette) {
    if (strength <= 0.25) return Colors.redAccent;
    if (strength <= 0.5) return Colors.orangeAccent;
    if (strength <= 0.75) return Colors.amber;
    return Colors.greenAccent;
  }

  String _getStrengthText(double strength) {
    if (widget.password.isEmpty) return "Enter password";
    if (strength <= 0.25) return "Very Weak";
    if (strength <= 0.5) return "Weak (Add Uppercase)";
    if (strength <= 0.75) return "Fair (Add Number)";
    if (strength < 1.0) return "Good (Add Special Char)";
    return "Strong Memory Lock";
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final strength = _calculateStrength();
    final color = _getStrengthColor(strength, palette);
    const double height = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Security Level",
              style: TextStyle(
                fontSize: 12,
                color: palette.textPrimary.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(end: strength),
          builder: (context, percentage, child) {
            return Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: palette.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(height),
                border: Border.all(
                  color: palette.textPrimary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _LiquidStrengthPainter(
                        animationValue: _waveController.value,
                        percentage: percentage,
                        color: color,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LiquidStrengthPainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color color;

  _LiquidStrengthPainter({
    required this.animationValue,
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (percentage <= 0) return;
    
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    
    double waveHeight = 2.0;
    double baseWidth = size.width * percentage;

    path.moveTo(0, size.height);
    path.lineTo(0, 0);

    for (double i = 0; i <= size.height; i++) {
      double dx = math.sin((animationValue * 2 * math.pi) + (i / 5)) * waveHeight;
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
  bool shouldRepaint(_LiquidStrengthPainter oldDelegate) => true;
}
