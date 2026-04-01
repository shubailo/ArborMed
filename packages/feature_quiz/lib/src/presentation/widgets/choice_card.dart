import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class ChoiceCard extends StatelessWidget {
  final QuestionChoice choice;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const ChoiceCard({
    super.key,
    required this.choice,
    required this.isSelected,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    
    Color borderColor = theme.primary.withValues(alpha: 0.1);
    Color? backgroundColor = theme.paperWhite;
    Color textColor = theme.textPrimary;

    if (isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
    } else if (isWrong) {
      borderColor = theme.accent;
      backgroundColor = theme.accent.withValues(alpha: 0.1);
    } else if (isSelected) {
      borderColor = theme.primary;
      backgroundColor = theme.primary.withValues(alpha: 0.05);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected ? theme.shadowSmall : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.text,
                style: theme.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            if (isCorrect)
               const Icon(Icons.check_circle, color: Colors.green)
            else if (isWrong)
               Icon(Icons.cancel, color: theme.accent)
            else if (isSelected)
               Icon(Icons.radio_button_checked, color: theme.primary)
            else
               Icon(Icons.radio_button_off, color: theme.textSecondary.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
