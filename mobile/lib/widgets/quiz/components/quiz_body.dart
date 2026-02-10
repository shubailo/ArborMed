import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../widgets/cozy/cozy_panel.dart';
import '../../../../widgets/cozy/liquid_button.dart';
import '../../../providers/quiz_controller.dart';
import '../../../../widgets/questions/question_renderer_registry.dart';

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
            child: CircularProgressIndicator(
              color: palette.primary,
            ),
          );
        }

        if (state.currentQuestion == null) {
           return Center(
             child: Text("No questions found!",
                 style: TextStyle(color: palette.textSecondary)),
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
