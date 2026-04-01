import '../src/models/subject_mastery.dart';
import '../src/models/activity_data.dart';
import '../src/models/readiness_score.dart';
import '../src/models/smart_review_item.dart';

abstract class StudentContract {
  // --- Core Profile ---
  Future<void> addXP(int amount);
  Future<void> addCoins(int amount);
  Future<int> getXP();
  Future<int> getCoins();
  Future<int> getLevel();

  // --- Statistics & Mastery ---
  Future<void> fetchSummary();
  Future<void> fetchActivity(String timeframe);
  Future<void> fetchReadiness();
  Future<void> fetchSmartReview();
  
  List<SubjectMastery> get subjectMastery;
  List<ActivityData> get activityData;
  List<SmartReviewItem> get smartReview;
  ReadinessScore? get readinessScore;

  Future<int> getMistakeCount();
  Future<List<int>> getIncorrectQuestionIds();
}
