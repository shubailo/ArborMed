import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/features/progress/presentation/providers/daily_prescription_provider.dart';
import 'package:student_app/core/ui/cozy_modal_scaffold.dart';
import 'package:student_app/core/ui/cozy_button.dart';

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
                        color: AppTheme.ivoryCream,
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
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warmBrown.withValues(alpha: 0.5),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CozyModalScaffold(
        title: 'Daily Prescription',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                color: AppTheme.sageGreen,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Today\'s prescription: $target questions.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Consistency is better than perfection. Try to complete your '
                'prescription every day to build a healthy learning habit.',
                style: TextStyle(
                  color: AppTheme.warmBrown.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CozyButton(
                label: 'GOT IT',
                onTap: () => Navigator.pop(context),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
