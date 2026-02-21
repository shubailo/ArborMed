import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/network/api_client.dart';
import 'package:student_app/database/database.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authStateProvider = StateProvider<String?>((ref) => null);

final studyModeProvider = StateProvider<String>((ref) => 'NORMAL');

final questionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(authStateProvider);
  final mode = ref.watch(studyModeProvider);
  if (userId == null) return null;

  final api = ref.read(apiClientProvider);
  final db = ref.read(databaseProvider);

  try {
    // 1. Fetch next from API
    final questionData = await api.fetchNextQuestion(
      userId,
      courseId: 'hema',
      mode: mode,
    );

    // 2. Cache in local Drift DB
    await db
        .into(db.questions)
        .insertOnConflictUpdate(
          QuestionsCompanion.insert(
            serverId: questionData['id'],
            topicId: questionData['topicId'],
            bloomLevel: questionData['bloomLevel'],
            content: questionData['content'],
            optionsJson: questionData['options'].toString(),
          ),
        );

    return questionData;
  } catch (e) {
    // print('Failed to fetch question: $e');
    return null;
  }
});

class StudyController {
  final Ref ref;
  StudyController(this.ref);

  Future<void> submitAnswer(
    String questionId,
    int selectedIndex,
    int correctIndex,
  ) async {
    final api = ref.read(apiClientProvider);
    // Simple quality heuristic: 5 if correct, 0 if wrong. M1 AdaptiveEngine needs 0-5.
    final quality = selectedIndex == correctIndex ? 5 : 0;

    final newBalance = await api.submitAnswer(
      questionId,
      quality,
      courseId: 'hema',
    );

    // M3: Update Reward Balance
    ref.read(rewardBalanceProvider.notifier).state = newBalance;

    // Refresh to get the next question
    ref.invalidate(questionProvider);
  }

  Future<void> login() async {
    final api = ref.read(apiClientProvider);
    final userId = await api.login();
    ref.read(authStateProvider.notifier).state = userId;
  }
}

final studyControllerProvider = Provider<StudyController>((ref) {
  return StudyController(ref);
});
