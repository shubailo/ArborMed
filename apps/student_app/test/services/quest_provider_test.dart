import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/services/quest_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/models/quest.dart';
import 'package:arbor_med/services/api_service.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  @override
  Future<dynamic> post(String? endpoint, Map<String, dynamic>? data) async {
    return {'newBalance': 100};
  }
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;

  @override
  void earnReward(int amount) {
    // Just mock it
  }
}

void main() {
  late QuestProvider questProvider;
  late MockAuthProvider mockAuth;

  setUp(() {
    SharedPreferences.setMockInitialValues({}); // Reset prefs
    mockAuth = MockAuthProvider();
    questProvider = QuestProvider(mockAuth);
  });

  test('Initializes with daily quests', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(questProvider.quests.length, 3);
    expect(questProvider.quests.any((q) => q.type == QuestType.questionsAnswered), true);
  });

  test('Updates progress correctly', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final quest = questProvider.quests.firstWhere((q) => q.type == QuestType.questionsAnswered);
    final initial = quest.currentCount;

    questProvider.updateProgress(QuestType.questionsAnswered, 1);

    expect(quest.currentCount, initial + 1);
  });

  test('Completes quest when target reached', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final quest = questProvider.quests.firstWhere((q) => q.type == QuestType.questionsAnswered);

    questProvider.updateProgress(QuestType.questionsAnswered, quest.targetCount);

    expect(quest.status, QuestStatus.completed);
  });

  test('Claiming quest rewards user', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final quest = questProvider.quests.firstWhere((q) => q.type == QuestType.questionsAnswered);
    quest.status = QuestStatus.completed; // Force complete

    final reward = await questProvider.claimQuest(quest.id);

    expect(reward, quest.rewardTokens);
    expect(quest.status, QuestStatus.claimed);
  });
}
