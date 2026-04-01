import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class FeedbackSheet extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback onNext;

  const FeedbackSheet({
    super.key,
    required this.isCorrect,
    this.explanation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final statusColor = isCorrect ? Colors.green : theme.accent;
    final statusBgColor = isCorrect ? Colors.green.withValues(alpha: 0.1) : theme.accent.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusBgColor,
                  child: Icon(isCorrect ? Icons.check : Icons.close, color: statusColor),
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: theme.headingLarge.copyWith(color: statusColor),
                ),
              ],
            ),
            if (explanation != null) ...[
              const SizedBox(height: 16),
              Text('EXPLANATION', style: theme.bodySmall.copyWith(fontWeight: FontWeight.bold, color: theme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(explanation!, style: theme.bodyMedium),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
