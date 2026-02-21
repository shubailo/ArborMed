import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/study_providers.dart';
import 'providers/study_ui_provider.dart';
import 'widgets/answer_option.dart';

class StudyBody extends ConsumerWidget {
  const StudyBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We listen to the UI State Machine
    final uiState = ref.watch(studyUiProvider);
    final uiNotifier = ref.read(studyUiProvider.notifier);

    // And we also listen to the raw question data
    final questionAsyncObj = ref.watch(questionProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildStateView(context, uiState, questionAsyncObj, uiNotifier),
    );
  }

  Widget _buildStateView(
    BuildContext context,
    StudyUiState uiState,
    AsyncValue<Map<String, dynamic>?> questionObj,
    StudyUiNotifier notifier,
  ) {
    // If the API call is loading or threw an error, handle it
    if (questionObj.isLoading && uiState is StudyUiLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Color(0xFF059669)),
      );
    }

    if (questionObj.hasError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${questionObj.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final q = questionObj.value;
    if (q == null) {
      return const Center(
        key: ValueKey('empty'),
        child: Text('No questions available.'),
      );
    }

    // Active UI states (Question, Submitting, Feedback)
    return _buildQuestionLayout(context, q, uiState, notifier);
  }

  Widget _buildQuestionLayout(
    BuildContext context,
    Map<String, dynamic> question,
    StudyUiState uiState,
    StudyUiNotifier notifier,
  ) {
    final options = question['options'] as List;

    return Padding(
      key: ValueKey('question_${question['id']}'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAF5), // Cream background
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Topic Tag Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6E5B9), // Yellow-ish cream
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        (question['topicId'] ?? 'General')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF8B7B61),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Question Content
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 24,
                        bottom: 24,
                      ),
                      child: Text(
                        question['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3E31), // Dark brown
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final opt = entry.value;

                          AnswerState answerState = AnswerState.idle;
                          if (uiState is StudyUiSubmitting &&
                              uiState.selectedIndex == idx) {
                            answerState = AnswerState.selected;
                          } else if (uiState is StudyUiFeedback) {
                            if (idx == uiState.correctIndex) {
                              answerState = AnswerState.correct;
                            } else if (idx == uiState.selectedIndex) {
                              answerState = AnswerState.incorrect;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: AnswerOption(
                              text: opt['text'],
                              state: answerState,
                              onTap: (uiState is StudyUiShowingQuestion)
                                  ? () => notifier.submitAnswer(
                                      question['id'],
                                      idx,
                                      options,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24), // Bottom padding for card
                  ],
                ),
              ),

              if (uiState is StudyUiFeedback) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => notifier.nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next Question',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
