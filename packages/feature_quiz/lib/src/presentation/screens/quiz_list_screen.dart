import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:arbormed_core/generated/l10n/app_localizations.dart';
import '../widgets/quiz_card.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ArborColors.background,
      appBar: AppBar(
        title: Text(l10n.availableQuizzes, style: const TextStyle(color: ArborColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: ArborColors.surface,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return QuizCard(
            title: l10n.medicalQuizTitle(index + 1),
            description: l10n.medicalQuizDescription,
            questionsCount: 20,
            durationMinutes: 30,
            onTap: () {
              // Navigate to QuizDetailScreen
            },
          );
        },
      ),
    );
  }
}
