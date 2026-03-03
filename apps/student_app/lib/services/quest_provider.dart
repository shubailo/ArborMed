import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest.dart';
import 'auth_provider.dart';

class QuestProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<LearningQuest> _quests = [];
  bool _isLoading = false;

  List<LearningQuest> get quests => _quests;
  bool get isLoading => _isLoading;

  // Constructor now accepts AuthProvider to handle rewards
  QuestProvider(this._authProvider) {
    _initQuests();
  }

  Future<void> fetchQuests() => _initQuests();

  Future<void> _initQuests() async {
    _isLoading = true;
    notifyListeners();

    await _checkDailyReset();
    await _loadQuests();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('last_quest_reset');
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (lastResetStr != todayStr) {
      await _generateDailyQuests();
      await prefs.setString('last_quest_reset', todayStr);
    }
  }

  Future<void> _generateDailyQuests() async {
    // Generate 3 random quests
    final newQuests = [
      LearningQuest(
        id: 'daily_1_${DateTime.now().millisecondsSinceEpoch}',
        period: QuestPeriod.daily,
        type: QuestType.questionsAnswered,
        title: 'Daily Practice',
        description: 'Complete 10 questions today',
        targetCount: 10,
        rewardTokens: 10,
      ),
      LearningQuest(
        id: 'daily_2_${DateTime.now().millisecondsSinceEpoch}',
        period: QuestPeriod.daily,
        type: QuestType.correctAnswers,
        title: 'Accuracy Master',
        description: 'Get 5 correct answers',
        targetCount: 5,
        rewardTokens: 20,
      ),
      LearningQuest(
        id: 'daily_3_${DateTime.now().millisecondsSinceEpoch}',
        period: QuestPeriod.daily,
        type: QuestType.perfectScore,
        title: 'Perfectionist',
        description: 'Get a perfect score in a session',
        targetCount: 1,
        rewardTokens: 30,
      ),
    ];

    _quests = newQuests;
    await _saveQuests();
  }

  Future<void> _loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final questsJson = prefs.getString('quests_data');
    if (questsJson != null) {
      final List<dynamic> decoded = jsonDecode(questsJson);
      _quests = decoded.map((q) => LearningQuest.fromJson(q)).toList();
    } else {
      await _generateDailyQuests();
    }
  }

  Future<void> _saveQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_quests.map((q) => q.toJson()).toList());
    await prefs.setString('quests_data', encoded);
  }

  void updateProgress(QuestType type, int amount) {
    bool changed = false;
    for (var quest in _quests) {
      if (quest.status == QuestStatus.active && quest.type == type) {
        quest.currentCount += amount;
        if (quest.currentCount >= quest.targetCount) {
          quest.currentCount = quest.targetCount;
          quest.status = QuestStatus.completed;
        }
        changed = true;
      }
    }

    if (changed) {
      _saveQuests();
      notifyListeners();
    }
  }

  Future<int> claimQuest(String questId) async {
    final questIndex = _quests.indexWhere((q) => q.id == questId);
    if (questIndex == -1) return 0;

    final quest = _quests[questIndex];
    if (quest.status != QuestStatus.completed) return 0;

    quest.status = QuestStatus.claimed;
    await _saveQuests();
    notifyListeners();

    // Reward the user via Backend API
    try {
      final response = await _authProvider.apiService.post('/quests/claim', {
        'questId': quest.id,
        'rewardTokens': quest.rewardTokens,
      });

      if (response != null && response['newBalance'] != null) {
         // Sync local user state with the new backend truth
         _authProvider.earnReward(quest.rewardTokens); // Alternatively, _authProvider.setCoins(response['newBalance'])
      }
    } catch (e) {
      debugPrint("❌ Failed to claim quest on backend: $e");
      // Revert status if backend failed
      quest.status = QuestStatus.completed;
      await _saveQuests();
      notifyListeners();
      return 0; // Did not successfully claim
    }

    return quest.rewardTokens;
  }
}
