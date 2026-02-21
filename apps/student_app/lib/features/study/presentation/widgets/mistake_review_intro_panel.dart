import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/presentation/pages/quiz_page.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';

class MistakeReviewIntroPanel extends ConsumerWidget {
  const MistakeReviewIntroPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(CozyTheme.spacingLarge),
      decoration: const BoxDecoration(
        color: AppTheme.ivoryCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.history_edu_outlined,
            size: 64,
            color: AppTheme.warmBrown,
          ),
          const SizedBox(height: 16),
          Text(
            'Mistake Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.warmBrown,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Review questions you previously struggled with to build confidence and mastery. We will focus on your recent mistakes from the last 14 days.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.softClay,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: CozyTheme.borderMedium,
              ),
            ),
            onPressed: () {
              ref.read(studyModeProvider.notifier).state = 'MISTAKE_REVIEW';
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizPage()),
              ).then((_) {
                // Reset mode when returning
                ref.read(studyModeProvider.notifier).state = 'NORMAL';
              });
            },
            child: const Text(
              'Start Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
