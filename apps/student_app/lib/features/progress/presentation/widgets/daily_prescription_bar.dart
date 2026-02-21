import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/features/progress/presentation/providers/daily_prescription_provider.dart';

class DailyPrescriptionBar extends ConsumerWidget {
  const DailyPrescriptionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyGoal = ref.watch(dailyPrescriptionProvider);

    return dailyGoal.when(
      data: (goal) {
        final isComplete = goal.completionRate >= 1.0;
        final barColor = isComplete ? AppTheme.sageGreen : AppTheme.softClay;
        final text = '${goal.answeredToday} / ${goal.targetQuestions} today';

        return GestureDetector(
          onTap: () => _showExplainPanel(context, goal.targetQuestions),
          child: Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: CozyTheme.borderMedium,
              boxShadow: CozyTheme.panelShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Goal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmBrown,
                      ),
                    ),
                    if (isComplete)
                      const Icon(Icons.check_circle, color: AppTheme.sageGreen, size: 12)
                  ],
                ),
                const SizedBox(height: 4),
                // Pill Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: goal.completionRate.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB5A79E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 140,
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox(),
    );
  }

  void _showExplainPanel(BuildContext context, int target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: CozyTheme.borderLarge),
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_outlined, color: AppTheme.sageGreen),
            SizedBox(width: 8),
            Text('Daily Prescription', style: TextStyle(color: AppTheme.warmBrown)),
          ],
        ),
        content: Text(
          'Today\'s prescription: $target questions.\n\n'
          'Consistency is better than perfection. Try to complete your '
          'prescription every day to build a healthy learning habit.',
          style: const TextStyle(color: Color(0xFFB5A79E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppTheme.sageGreen)),
          ),
        ],
      ),
    );
  }
}
