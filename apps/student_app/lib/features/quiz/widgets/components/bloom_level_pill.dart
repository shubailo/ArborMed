import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/features/quiz/providers/quiz_controller.dart';

class BloomLevelPill extends StatefulWidget {
  const BloomLevelPill({super.key});

  @override
  State<BloomLevelPill> createState() => _BloomLevelPillState();
}

class _BloomLevelPillState extends State<BloomLevelPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  String _lastDirection = 'NONE';
  int _lastLevel = 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final controller = Provider.of<QuizController>(context);
    final currentLevel = controller.state.currentBloomLevel;
    final direction = controller.state.levelDirection;

    // Trigger animation if direction changed or level changed
    if (direction != _lastDirection && (direction == 'UP' || direction == 'DOWN')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerPulse();
      });
      _lastDirection = direction;
      _lastLevel = currentLevel;
    } else if (currentLevel != _lastLevel) {
      _lastLevel = currentLevel;
    }

    // Styling based on levelDirection
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? indicatorIcon;

    if (direction == 'UP') {
      bgColor = const Color(0xFFE8F5E9); // soft green
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF2E7D32);
      indicatorIcon = Icons.arrow_upward_rounded;
    } else if (direction == 'DOWN') {
      bgColor = const Color(0xFFFFEBEE); // soft red
      borderColor = const Color(0xFFEF5350);
      textColor = const Color(0xFFC62828);
      indicatorIcon = Icons.arrow_downward_rounded;
    } else {
      bgColor = palette.paperWhite.withValues(alpha: 0.85);
      borderColor = palette.textPrimary.withValues(alpha: 0.08);
      textColor = palette.textSecondary;
      indicatorIcon = null;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: (direction == 'UP' || direction == 'DOWN')
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (indicatorIcon != null) ...[
              Icon(indicatorIcon, size: 14, color: textColor),
              const SizedBox(width: 4),
            ] else ...[
              Icon(Icons.workspace_premium_outlined, size: 14, color: palette.accent),
              const SizedBox(width: 4),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                "Bloom L$currentLevel",
                key: ValueKey<int>(currentLevel),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

