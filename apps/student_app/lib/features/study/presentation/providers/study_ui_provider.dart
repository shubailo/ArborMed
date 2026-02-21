import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';

sealed class StudyUiState {}

class StudyUiLoading extends StudyUiState {}

class StudyUiShowingQuestion extends StudyUiState {}

class StudyUiSubmitting extends StudyUiState {
  final int selectedIndex;
  StudyUiSubmitting(this.selectedIndex);
}

class StudyUiFeedback extends StudyUiState {
  final int selectedIndex;
  final int correctIndex;
  StudyUiFeedback(this.selectedIndex, this.correctIndex);
}

class StudyUiError extends StudyUiState {
  final String message;
  StudyUiError(this.message);
}

class StudyUiNotifier extends StateNotifier<StudyUiState> {
  final Ref ref;

  StudyUiNotifier(this.ref) : super(StudyUiLoading()) {
    // Automatically transition to showing question when future provider resolves
    ref.listen<AsyncValue<Map<String, dynamic>?>>(questionProvider, (
      previous,
      next,
    ) {
      if (next.isLoading) {
        state = StudyUiLoading();
      } else if (next.hasError) {
        state = StudyUiError(next.error.toString());
      } else if (next.hasValue && next.value != null) {
        state = StudyUiShowingQuestion();
      }
    });
  }

  Future<void> submitAnswer(
    String questionId,
    int selectedIndex,
    List options,
  ) async {
    if (state is! StudyUiShowingQuestion) return;

    state = StudyUiSubmitting(selectedIndex);

    final correctIndex = options.indexWhere((o) => o['isCorrect'] == true);

    // In a real app we might await the API call here.
    // In current implementation, studyControllerProvider.submitAnswer triggers a ref.invalidate which
    // immediately loads the next question. We want to show Feedback state first.

    // Send background analytics or answer to backend, but do not invalidate yet so we stay on this question.
    // For now we just call API directly passing the controller:
    try {
      final api = ref.read(apiClientProvider);
      final quality = selectedIndex == correctIndex ? 5 : 0;
      final newBalance = await api.submitAnswer(
        questionId,
        quality,
        courseId: 'hema',
      );

      // M3: Update Reward Balance immediately
      ref.read(rewardBalanceProvider.notifier).state = newBalance;

      // Show feedback
      state = StudyUiFeedback(selectedIndex, correctIndex);

      // Auto-advance after 3 seconds if user doesn't press "Next"
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && state is StudyUiFeedback) {
          nextQuestion();
        }
      });
    } catch (e) {
      state = StudyUiError('Failed to submit: $e');
    }
  }

  void nextQuestion() {
    state = StudyUiLoading(); // Optionally switch to loading manually
    ref.invalidate(questionProvider);
  }

  void retry() {
    state = StudyUiLoading();
    ref.invalidate(questionProvider);
  }
}

final studyUiProvider = StateNotifierProvider<StudyUiNotifier, StudyUiState>((
  ref,
) {
  return StudyUiNotifier(ref);
});
