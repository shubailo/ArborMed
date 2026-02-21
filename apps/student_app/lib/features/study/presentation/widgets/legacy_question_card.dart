import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/ui/cozy_panel.dart';

class LegacyQuestionCard extends StatelessWidget {
  final Widget question;
  final Widget answers;
  final String? title;

  const LegacyQuestionCard({
    super.key,
    required this.question,
    required this.answers,
    this.title = "KÉRDÉS",
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          CozyPanel(
            title: title,
            variant: CozyPanelVariant.cream,
            hasTexture: true,
            animateIn: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                question,
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: AppTheme.warmBrown, thickness: 0.5, height: 1),
                ),
                answers,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
