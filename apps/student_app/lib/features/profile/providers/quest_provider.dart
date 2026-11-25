import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/features/profile/models/quest.dart';
import 'package:arbor_med/services/auth_provider.dart';

class QuestProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<LearningQuest> _quests = [];
  int? _owner;
  String? _date;
  int _request = 0;
  bool _isLoading = false;
  final Set<String> _claiming = {};

  QuestProvider(this._authProvider);

  String get _today => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  List<LearningQuest> get quests =>
      _owner == _authProvider.user?.id && _date == _today ? _quests : [];
  bool get isLoading => _isLoading;

  Future<void> fetchQuests() async {
    final userId = _authProvider.user?.id;
    final generation = ++_request;
    if (userId == null) {
      _quests = [];
      _owner = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    final key = 'daily_quests_$userId';
    bool current() => generation == _request && userId == _authProvider.user?.id;
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> snapshot;
      try {
        final result = await _authProvider.apiService.get('/quests/daily');
        snapshot = Map<String, dynamic>.from(result);
        if (!current()) return;
        await prefs.setString(key, jsonEncode(snapshot));
      } catch (error) {
        debugPrint('Unable to refresh quests: $error');
        final cached = prefs.getString(key);
        if (cached == null) return;
        snapshot = Map<String, dynamic>.from(jsonDecode(cached));
      }
      if (!current() || snapshot['date'] != _today) return;
      _quests = (snapshot['quests'] as List)
          .map((q) => LearningQuest(
                id: q['id'],
                period: QuestPeriod.daily,
                type: QuestType.values.byName(q['type']),
                title: q['title'],
                description: q['description'],
                targetCount: q['targetCount'],
                currentCount: q['currentCount'],
                rewardTokens: q['rewardTokens'],
                status: QuestStatus.values.byName(q['status']),
              ))
          .toList();
      _date = snapshot['date'];
      _owner = userId;
    } finally {
      if (generation == _request) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<int> claimQuest(String questId) async {
    final userId = _authProvider.user?.id;
    final index = quests.indexWhere((quest) => quest.id == questId);
    if (userId == null || index == -1) return 0;
    final quest = quests[index];
    final key = '$userId-$questId';
    if (quest.status != QuestStatus.completed || !_claiming.add(key)) return 0;
    try {
      final response = await _authProvider.apiService.post('/quests/claim', {'questId': quest.id});
      final balance = response?['newBalance'];
      if (balance is! num || userId != _authProvider.user?.id) return 0;
      _authProvider.updateCoinBalance(balance.toInt());
      quest.status = QuestStatus.claimed;
      notifyListeners();
      await fetchQuests();
      return userId == _authProvider.user?.id ? quest.rewardTokens : 0;
    } catch (error) {
      debugPrint('Failed to claim quest: $error');
      return 0;
    } finally {
      _claiming.remove(key);
    }
  }
}
