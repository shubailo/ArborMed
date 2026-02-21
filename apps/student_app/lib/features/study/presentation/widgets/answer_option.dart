import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AnswerState { idle, selected, correct, incorrect }

class AnswerOption extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerOption({
    super.key,
    required this.text,
    this.state = AnswerState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    IconData leadingIcon;
    Color iconColor;

    switch (state) {
      case AnswerState.idle:
        borderColor = const Color(0xFFEFE8D8);
        backgroundColor = Colors.white;
        textColor = const Color(0xFF4A3E31);
        leadingIcon = Icons.radio_button_unchecked;
        iconColor = const Color(0xFFB5A79E);
        break;
      case AnswerState.selected:
        borderColor = const Color(0xFFD4C9BA);
        backgroundColor = const Color(0xFFF7F3EB);
        textColor = const Color(0xFF4A3E31);
        leadingIcon = Icons.radio_button_checked;
        iconColor = const Color(0xFF8B7B61);
        break;
      case AnswerState.correct:
        borderColor = const Color(0xFF10B981); // Emerald Green
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF065F46);
        leadingIcon = Icons.check_circle;
        iconColor = const Color(0xFF10B981);
        break;
      case AnswerState.incorrect:
        borderColor = const Color(0xFFEF4444); // Red
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFF991B1B);
        leadingIcon = Icons.cancel;
        iconColor = const Color(0xFFEF4444);
        break;
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null && state == AnswerState.idle) {
          HapticFeedback.mediumImpact(); // Immediate tactile haptic feedback
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(leadingIcon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
