import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';

class CozyProgressBar extends StatelessWidget {
  final double value;
  final bool pulse;

  const CozyProgressBar({super.key, required this.value, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.warmBrown.withValues(alpha: 0.1),
        borderRadius: CozyTheme.borderSmall,
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: MediaQuery.of(context).size.width * value,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.sageGreen, Color(0xFFA8C6A8)],
              ),
              borderRadius: CozyTheme.borderSmall,
              boxShadow: pulse
                  ? [
                      BoxShadow(
                        color: AppTheme.sageGreen.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
