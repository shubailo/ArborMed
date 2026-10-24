import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/cozy_panel.dart';
import 'package:arbor_med/widgets/cozy/liquid_button.dart';
import 'package:arbor_med/features/quiz/providers/quiz_controller.dart';
import '../../../../features/quiz/widgets/questions/question_renderer_registry.dart';

import 'package:google_fonts/google_fonts.dart';

class QuizBody extends StatelessWidget {
  final String systemName;

  const QuizBody({super.key, required this.systemName});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    
    return Consumer<QuizController>(
      builder: (context, controller, child) {
        final state = controller.state;
        
        if (state.isLoading && state.currentQuestion == null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CozyPanel(
                  title: systemName.toUpperCase(),
                  variant: CozyPanelVariant.cream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: palette.textPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                          color: palette.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 28),
                      for (int i = 0; i < 4; i++) ...[
                        Container(
                          height: 52,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: palette.paperWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: palette.textPrimary.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (state.isReviewComplete) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: CozyPanel(
                title: "REVIEW COMPLETED",
                variant: CozyPanelVariant.cream,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: palette.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline_rounded,
                          color: palette.success, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "All Mistakes Reviewed!",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You have worked through all flagged review questions for this module.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LiquidButton(
                      label: "FINISH REVIEW",
                      variant: LiquidButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.currentQuestion == null) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: CozyPanel(
                title: "NO QUESTIONS",
                variant: CozyPanelVariant.cream,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        color: palette.textSecondary.withValues(alpha: 0.5), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "No Questions Available",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We couldn't load questions for this topic right now. Please check your connection and retry.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LiquidButton(
                      label: "RETRY",
                      variant: LiquidButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () => controller.loadNextQuestion(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final q = state.currentQuestion!;
        final qType = q['question_type'] ?? 'single_choice';
        final renderer = QuestionRendererRegistry.getRenderer(qType);
        final hasAnswer = renderer.hasAnswer(state.userAnswer);

        // Determine if we should show the submit button for this question type
        final showSubmitButton = const {
          'multiple_choice',
          'relation_analysis',
          'matching',
          'case_study'
        }.contains(qType);

        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final inAnimation = Tween<Offset>(
                        begin: const Offset(1.2, 0.0),
                        end: const Offset(0.0, 0.0),
                      ).animate(animation);

                      return SlideTransition(
                        position: inAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: CozyPanel(
                      key: ValueKey(q['id']),
                      title: systemName.toUpperCase(),
                      variant: CozyPanelVariant.cream,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Delegate Content Rendering
                          renderer.buildQuestion(context, q),

                          const SizedBox(height: 24),

                          // Delegate Answer Input Rendering
                          renderer.buildAnswerInput(
                            context,
                            q,
                            state.userAnswer,
                            state.isAnswerChecked
                                ? (_) {} // Disable input if checked
                                : (val) {
                                    controller.selectAnswer(val);
                                    // Auto-submit for specific types
                                    if (qType == 'single_choice' || qType == 'true_false') {
                                      controller.submitAnswer();
                                    }
                                  },
                            isChecked: state.isAnswerChecked,
                            correctAnswer: state.correctAnswer,
                          ),

                          const SizedBox(height: 32),
                          // Submit Button
                          if (showSubmitButton)
                            LiquidButton(
                              label: "Submit Answer",
                              onPressed: hasAnswer &&
                                      !state.isAnswerChecked &&
                                      !state.isSubmitting
                                  ? controller.submitAnswer
                                  : null,
                              variant: hasAnswer
                                  ? LiquidButtonVariant.primary
                                  : LiquidButtonVariant.outline,
                              fullWidth: true,
                              icon: Icons.send_rounded,
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Loading Overlay (Subtle)
            if (state.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
