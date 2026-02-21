import 'package:flutter/material.dart';
import 'package:student_app/core/theme/cozy_theme.dart';

class CozyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const CozyBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
