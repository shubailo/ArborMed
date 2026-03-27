import 'package:flutter/material.dart';
import '../../../../widgets/quiz/feedback_bottom_sheet.dart';
import '../../../services/quiz_controller.dart';
import 'package:provider/provider.dart';

class QuizFeedbackOverlay extends StatelessWidget {
  const QuizFeedbackOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizController>(
      builder: (context, controller, child) {
        if (!controller.state.isAnswerChecked) return const SizedBox.shrink();

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FeedbackBottomSheet(
            isCorrect: controller.state.isCorrect,
            explanation: controller.state.explanation,
            onContinue: controller.loadNextQuestion,
            questionId: controller.state.currentQuestion?['id'],
          ),
        );
      },
    );
  }
}
