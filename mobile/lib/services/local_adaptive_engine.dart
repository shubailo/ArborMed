import 'dart:math' as math;
import 'package:drift/drift.dart';
import '../database/database.dart';

class LocalAdaptiveEngine {
  static final LocalAdaptiveEngine _instance = LocalAdaptiveEngine._internal();
  factory LocalAdaptiveEngine() => _instance;
  LocalAdaptiveEngine._internal();

  final AppDatabase _db = AppDatabase();

  /// Get the next best question for a user based on Bloom Level and SRS.
  Future<Question?> getNextQuestion(int userId, String topicSlug, {List<int> excludedIds = const []}) async {
    // 1. SRS PRIORITY: Check for "Due" questions first
    final dueReview = await (_db.select(_db.questionProgress)
          ..where((p) => p.userId.equals(userId) & p.nextReviewAt.isSmallerThanValue(DateTime.now())))
        .get();

    if (dueReview.isNotEmpty) {
      final dueIds = dueReview.map((p) => p.questionId!).where((id) => !excludedIds.contains(id)).toList();
      if (dueIds.isNotEmpty) {
        final questions = await (_db.select(_db.questions)
              ..where((q) => q.serverId.isIn(dueIds) & q.active.equals(true)))
            .get();
        
        if (questions.isNotEmpty) {
          return questions[math.Random().nextInt(questions.length)];
        }
      }
    }

    // 2. NEW CONTENT: Bloom Climber Logic
    final topicProgress = await (_db.select(_db.topicProgress)
          ..where((tp) => tp.userId.equals(userId) & tp.topicSlug.equals(topicSlug)))
        .getSingleOrNull();

    int currentBloom = topicProgress?.currentBloomLevel ?? 1;

    // Fetch Question for this Level
    final potentialQuestions = await (_db.select(_db.questions)
          ..where((q) => q.bloomLevel.equals(currentBloom) & q.active.equals(true)))
        .get();

    // Filter out already answered ones (that are in progress)
    final answeredProgress = await (_db.select(_db.questionProgress)
          ..where((p) => p.userId.equals(userId)))
        .get();
    final answeredIds = answeredProgress.map((p) => p.questionId).toSet();

    final remaining = potentialQuestions
        .where((q) => !answeredIds.contains(q.serverId) && !excludedIds.contains(q.serverId!))
        .toList();

    if (remaining.isNotEmpty) {
      return remaining[math.Random().nextInt(remaining.length)];
    }

    // Fallback: Any level not yet mastered
    final fallback = await (_db.select(_db.questions)
          ..where((q) => q.active.equals(true)))
        .get();
    
    final finalRemaining = fallback
        .where((q) => !answeredIds.contains(q.serverId) && !excludedIds.contains(q.serverId!))
        .toList();

    if (finalRemaining.isNotEmpty) {
      return finalRemaining[math.Random().nextInt(finalRemaining.length)];
    }

    // Last Resort: Randomized from topic
    final filteredLastResort = fallback.where((q) => !excludedIds.contains(q.serverId!)).toList();
    
    if (filteredLastResort.isNotEmpty) {
      return filteredLastResort[math.Random().nextInt(filteredLastResort.length)];
    }

    return null;
  }

  /// Process answer result and update local progress/SRS
  Future<Map<String, dynamic>> processAnswerResult(int userId, String topicSlug, bool isCorrect, int questionId) async {
    // 1. Update SRS State
    await _updateSRS(userId, questionId, isCorrect);

    // 2. Fetch Topic State
    var progress = await (_db.select(_db.topicProgress)
          ..where((tp) => tp.userId.equals(userId) & tp.topicSlug.equals(topicSlug)))
        .getSingleOrNull();

    if (progress == null) {
      final id = await _db.into(_db.topicProgress).insert(TopicProgressCompanion.insert(
        userId: Value(userId),
        topicSlug: Value(topicSlug),
        isDirty: const Value(true),
      ));
      progress = await (_db.select(_db.topicProgress)..where((t) => t.id.equals(id))).getSingle();
    }

    // Update stats
    final updatedTC = TopicProgressCompanion(
      totalAnswered: Value(progress.totalAnswered + 1),
      correctAnswered: Value(isCorrect ? progress.correctAnswered + 1 : progress.correctAnswered),
      lastStudiedAt: Value(DateTime.now()),
      isDirty: const Value(true),
    );

    // Calculate Mastery (Weighted)
    final allQuestions = await _db.select(_db.questions).get(); 
    final totalTopicCount = allQuestions.length.clamp(1, 10000);
    
    final masteredProgress = await (_db.select(_db.questionProgress)
          ..where((p) => p.userId.equals(userId) & p.mastered.equals(true)))
        .get();
    final masteredIds = masteredProgress.map((p) => p.questionId).toSet();
    
    final masteredCount = masteredIds.length;
    final learningProgress = await (_db.select(_db.questionProgress)
          ..where((p) => p.userId.equals(userId) & p.mastered.equals(false) & p.consecutiveCorrect.isBiggerThanValue(0)))
        .get();
    final learningCount = learningProgress.length;

    final masteryPoints = (masteredCount * 1.0) + (learningCount * 0.5);
    final masteryScore = ((masteryPoints / totalTopicCount) * 100).round().clamp(0, 100);

    String? event;
    int nextBloom = progress.currentBloomLevel;
    int nextStreak = isCorrect ? progress.currentStreak + 1 : 0;
    int nextWrong = isCorrect ? 0 : progress.consecutiveWrong + 1;

    // 4. Bloom Promotion Logic
    if (isCorrect) {
      // Promotion check (> 80% coverage in level)
      final levelQuestions = allQuestions.where((q) => q.bloomLevel == progress!.currentBloomLevel).length;
      final masteredInLevel = allQuestions
          .where((q) => q.bloomLevel == progress!.currentBloomLevel && masteredIds.contains(q.serverId))
          .length;

      final coverage = masteredInLevel / (levelQuestions > 0 ? levelQuestions : 1);

      if ((coverage >= 0.8 || nextStreak >= 20) && nextBloom < 6) {
        nextBloom++;
        nextStreak = 0;
        event = 'PROMOTION';
      } else if (nextStreak > 1) {
        event = 'STREAK_EXTENDED';
      }
    } else {
      if (nextWrong >= 3 && nextBloom > 1) {
        nextBloom--;
        nextWrong = 0;
        event = 'DEMOTION';
      }
    }

    await (_db.update(_db.topicProgress)..where((t) => t.id.equals(progress!.id))).write(
      updatedTC.copyWith(
        currentBloomLevel: Value(nextBloom),
        currentStreak: Value(nextStreak),
        consecutiveWrong: Value(nextWrong),
        masteryScore: Value(masteryScore),
        questionsMastered: Value(masteredCount),
        unlockedBloomLevel: Value(math.max(progress.unlockedBloomLevel, nextBloom)),
      ),
    );

    return {
      'newLevel': nextBloom,
      'streak': nextStreak,
      'event': event,
      'mastered': masteredCount,
      'coverage': masteryScore
    };
  }

  Future<void> _updateSRS(int userId, int questionId, bool isCorrect) async {
    var p = await (_db.select(_db.questionProgress)
          ..where((t) => t.userId.equals(userId) & t.questionId.equals(questionId)))
        .getSingleOrNull();

    if (p == null) {
      final id = await _db.into(_db.questionProgress).insert(QuestionProgressCompanion.insert(
        userId: Value(userId),
        questionId: Value(questionId),
      ));
      p = await (_db.select(_db.questionProgress)..where((t) => t.id.equals(id))).getSingle();
    }

    int nextBox = isCorrect ? (p.box + 1).clamp(0, 5) : 1;
    int nextConsecutive = isCorrect ? p.consecutiveCorrect + 1 : 0;

    // Interval logic
    Duration interval;
    if (!isCorrect) {
      interval = const Duration(minutes: 5);
    } else {
      switch (nextBox) {
        case 1: interval = const Duration(days: 1); break;
        case 2: interval = const Duration(days: 3); break;
        case 3: interval = const Duration(days: 7); break;
        case 4: interval = const Duration(days: 14); break;
        case 5: interval = const Duration(days: 30); break;
        default: interval = const Duration(minutes: 0);
      }
    }

    await (_db.update(_db.questionProgress)..where((t) => t.id.equals(p!.id))).write(
      QuestionProgressCompanion(
        box: Value(nextBox),
        consecutiveCorrect: Value(nextConsecutive),
        mastered: Value(nextConsecutive >= 3),
        nextReviewAt: Value(DateTime.now().add(interval)),
        lastAnsweredAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
      ),
    );
  }
}
