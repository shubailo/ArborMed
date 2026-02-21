import 'package:flutter/material.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/theme/app_theme.dart';

class CozyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  const CozyIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: CozyTheme.cardShadow,
        ),
        child: Icon(
          icon,
          color: color ?? AppTheme.warmBrown,
          size: size,
        ),
      ),
    );
  }
}
