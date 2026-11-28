import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/features/profile/models/quest.dart';
import 'package:arbor_med/services/auth_provider.dart';

class QuestProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final DateTime Function() _clock;
  List<LearningQuest> _quests = [];
  int? _owner;
  String? _date;
  int _session = 0;
  int _request = 0;
  bool _isLoading = false;
  bool _refreshFailed = false;
  bool _disposed = false;
  Object? _claim;
  String? _claimDay;

  QuestProvider(this._authProvider, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        _owner = _authProvider.user?.id {
    _authProvider.addListener(_syncOwner);
  }

  String get _today =>
      _clock().toUtc().toIso8601String().substring(0, 10);
  List<LearningQuest> get quests =>
      _owner == _authProvider.user?.id && _date == _today ? _quests : const [];
  bool get isLoading => _isLoading;
  bool get refreshFailed => _refreshFailed;
  bool get isClaiming => _claim != null && _claimDay == _today;
  int get sessionRevision => _session;

  void _syncOwner() {
    if (_owner == _authProvider.user?.id) return;
    _owner = _authProvider.user?.id;
    _session++;
    _request++;
    _claim = null;
    _claimDay = null;
    _date = null;
    _quests = [];
    _isLoading = false;
    _refreshFailed = false;
    notifyListeners();
  }

  bool _current(int session, String date) =>
      !_disposed &&
      _owner != null &&
      _owner == _authProvider.user?.id &&
      _session == session &&
      _today == date;

  List<LearningQuest> _decode(dynamic snapshot, String date) {
    if (snapshot is! Map ||
        snapshot['date'] != date ||
        snapshot['quests'] is! List) {
      throw const FormatException('Invalid daily quest snapshot');
    }
    final result = (snapshot['quests'] as List)
        .map((item) => LearningQuest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (result.map((q) => q.id).toSet().length != result.length) {
      throw const FormatException('Duplicate daily quest');
    }
    return result;
  }

  Future<void> _save(int session, String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_current(session, date) || _date != date) return;
      await prefs.setString('daily_quests_$_owner',
          jsonEncode({'date': date, 'quests': _quests}));
    } catch (error) {
      debugPrint('Quest cache write failed: ${error.runtimeType}');
    }
  }

  Future<void> fetchQuests() async {
    if (_disposed || _owner == null) return;
    final session = _session;
    final date = _today;
    final request = ++_request;
    bool current() => request == _request && _current(session, date);
    _isLoading = true;
    _refreshFailed = false;
    notifyListeners();
    try {
      final response = await _authProvider.apiService.get('/quests/daily');
      if (!current()) return;
      final rows = _decode(response, date);
      _quests = rows;
      _date = date;
      await _save(session, date);
    } catch (error) {
      if (!current()) return;
      _refreshFailed = true;
      debugPrint('Quest refresh failed: ${error.runtimeType}');
      if (_date != date) {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (!current()) return;
          final raw = prefs.getString('daily_quests_$_owner');
          if (raw != null) {
            _quests = _decode(jsonDecode(raw), date);
            _date = date;
          }
        } catch (error) {
          debugPrint('Quest cache read failed: ${error.runtimeType}');
        }
      }
    } finally {
      if (!_disposed && request == _request) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<int> claimQuest(String questId) async {
    final index = quests.indexWhere((quest) => quest.id == questId);
    if (_disposed ||
        isClaiming ||
        index < 0 ||
        quests[index].status != QuestStatus.completed) {
      return 0;
    }
    final session = _session;
    final date = _date!;
    final token = _claim = Object();
    _claimDay = date;
    notifyListeners();
    try {
      final response = await _authProvider.apiService
          .post('/quests/claim', {'questId': questId, 'date': date});
      if (!_current(session, date)) return 0;
      final balance = response['newBalance'];
      // Older servers confirm the balance but do not say whether this was a replay.
      final awarded = response['awardedTokens'] ?? 0;
      if (balance is! int ||
          balance < 0 ||
          awarded is! int ||
          awarded < 0 ||
          (response['date'] != null && response['date'] != date)) {
        throw const FormatException('Invalid daily claim receipt');
      }
      ++_request;
      _isLoading = false;
      for (final quest in quests.where((q) => q.id == questId)) {
        quest.status = QuestStatus.claimed;
      }
      _authProvider.updateCoinBalance(balance);
      await _save(session, date);
      return _current(session, date) ? awarded : 0;
    } catch (error) {
      if (!_current(session, date)) return 0;
      debugPrint('Quest claim failed: ${error.runtimeType}');
      rethrow;
    } finally {
      if (!_disposed && identical(_claim, token)) {
        _claim = null;
        _claimDay = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authProvider.removeListener(_syncOwner);
    super.dispose();
  }
}
