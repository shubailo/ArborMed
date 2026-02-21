import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/presentation/pages/quiz_page.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/ui/cozy_button.dart';
import 'package:student_app/core/ui/cozy_modal_scaffold.dart';

class MistakeReviewIntroPanel extends ConsumerWidget {
  const MistakeReviewIntroPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CozyModalScaffold(
      title: 'Mistake Review',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_edu_outlined,
              size: 72,
              color: AppTheme.warmBrown,
            ),
            const SizedBox(height: 24),
            const Text(
              'Review questions you previously struggled with to build confidence and mastery. We will focus on your recent mistakes from the last 14 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.softClay,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            CozyButton(
              label: 'START REVIEW',
              fullWidth: true,
              onTap: () {
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
            ),
          ],
        ),
      ),
    );
  }
}
