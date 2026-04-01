import 'package:flutter/foundation.dart';
import 'package:arbormed_core/arbormed_core.dart' hide QuestType;
import 'package:core_interop/core_interop.dart';
import 'package:drift/drift.dart';

class StudentService extends ChangeNotifier implements StudentContract, QuestContract {
  final AppDatabase _db;
  final ApiService _api = ApiService();
  
  StudentProfile? _profile;
  
  // --- Statistics State ---
  List<SubjectMastery> _subjectMastery = [];
  List<ActivityData> _activityData = [];
  List<SmartReviewItem> _smartReview = [];
  ReadinessScore? _readinessScore;
  bool _isLoading = false;
  bool _isInit = false;

  StudentService(this._db);

  StudentProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  // --- StudentContract Implementation ---

  @override
  List<SubjectMastery> get subjectMastery => _subjectMastery;

  @override
  List<ActivityData> get activityData => _activityData;

  @override
  List<SmartReviewItem> get smartReview => _smartReview;

  @override
  List<dynamic> get activeQuests => [];

  @override
  ReadinessScore? get readinessScore => _readinessScore;

  Future<void> loadProfile(String userId) async {
    final query = _db.select(_db.studentProfiles)..where((t) => t.userId.equals(userId));
    _profile = await query.getSingleOrNull();
    
    if (_profile == null) {
      final companion = StudentProfilesCompanion.insert(
        userId: userId,
        displayName: const Value('New Student'),
        xp: const Value(0),
        coins: const Value(0),
        level: const Value(1),
      );
      
      final id = await _db.into(_db.studentProfiles).insert(companion);
      _profile = await (_db.select(_db.studentProfiles)..where((t) => t.id.equals(id))).getSingle();
    }
    _isInit = true;
    notifyListeners();
  }

  @override
  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get(ApiEndpoints.statsSummary);
      if (data is List) {
        _subjectMastery = data.map((item) => SubjectMastery.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> fetchActivity(String timeframe) async {
    try {
      final data = await _api.get('${ApiEndpoints.statsActivity}?timeframe=$timeframe');
      if (data is List) {
        _activityData = data.map((item) => ActivityData.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
  }

  @override
  Future<void> fetchSmartReview() async {
    try {
      final data = await _api.get(ApiEndpoints.statsSmartReview);
      if (data != null && data['recommendations'] is List) {
        _smartReview = (data['recommendations'] as List)
            .map((e) => SmartReviewItem.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching smart review: $e');
    }
  }

  @override
  Future<void> fetchReadiness() async {
    try {
      final data = await _api.get(ApiEndpoints.statsReadiness);
      if (data != null) {
        _readinessScore = ReadinessScore.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching readiness: $e');
    }
  }

  @override
  Future<void> addXP(int amount) async {
    if (_profile == null) return;
    final newXP = _profile!.xp + amount;
    final newLevel = (newXP / 100).floor() + 1;
    
    await (_db.update(_db.studentProfiles)
      ..where((t) => t.id.equals(_profile!.id)))
      .write(StudentProfilesCompanion(
        xp: Value(newXP),
        level: Value(newLevel),
      ));
    
    await loadProfile(_profile!.userId);
  }

  @override
  Future<void> addCoins(int amount) async {
    if (_profile == null) return;
    final newCoins = _profile!.coins + amount;
    
    await (_db.update(_db.studentProfiles)
      ..where((t) => t.id.equals(_profile!.id)))
      .write(StudentProfilesCompanion(
        coins: Value(newCoins),
      ));
    
    await loadProfile(_profile!.userId);
  }

  @override
  Future<int> getXP() async => _profile?.xp ?? 0;

  @override
  Future<int> getCoins() async => _profile?.coins ?? 0;

  @override
  Future<int> getLevel() async => _profile?.level ?? 1;

  @override
  Future<void> fetchQuests() async {
    // Future: Fetch quests
  }

  @override
  Future<void> updateProgress(QuestType type, int amount) async {
    debugPrint('Quest Progress Updated: $type +$amount');
  }

  @override
  Future<int> getMistakeCount() async {
    return 3; 
  }

  @override
  Future<List<int>> getIncorrectQuestionIds() async {
    return [101, 102, 103]; 
  }
}
