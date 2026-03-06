import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TopicProgress Table Tests', () {
    test('can insert and read a topic progress record', () async {
      final now = DateTime.now().copyWith(millisecond: 0, microsecond: 0);

      final topicProgressId = await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(1),
              topicSlug: const drift.Value('cardiology'),
              currentBloomLevel: const drift.Value(2),
              currentStreak: const drift.Value(5),
              consecutiveWrong: const drift.Value(1),
              totalAnswered: const drift.Value(20),
              correctAnswered: const drift.Value(15),
              masteryScore: const drift.Value(85),
              unlockedBloomLevel: const drift.Value(3),
              questionsMastered: const drift.Value(10),
              lastStudiedAt: drift.Value(now),
            ),
          );

      final record = await (db.select(db.topicProgress)..where((t) => t.id.equals(topicProgressId))).getSingle();

      expect(record.id, topicProgressId);
      expect(record.userId, 1);
      expect(record.topicSlug, 'cardiology');
      expect(record.currentBloomLevel, 2);
      expect(record.currentStreak, 5);
      expect(record.consecutiveWrong, 1);
      expect(record.totalAnswered, 20);
      expect(record.correctAnswered, 15);
      expect(record.masteryScore, 85);
      expect(record.unlockedBloomLevel, 3);
      expect(record.questionsMastered, 10);
      expect(record.lastStudiedAt!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('default values are applied correctly', () async {
      final topicProgressId = await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(2),
              topicSlug: const drift.Value('neurology'),
            ),
          );

      final record = await (db.select(db.topicProgress)..where((t) => t.id.equals(topicProgressId))).getSingle();

      expect(record.currentBloomLevel, 1);
      expect(record.currentStreak, 0);
      expect(record.consecutiveWrong, 0);
      expect(record.totalAnswered, 0);
      expect(record.correctAnswered, 0);
      expect(record.masteryScore, 0);
      expect(record.unlockedBloomLevel, 1);
      expect(record.questionsMastered, 0);
      expect(record.lastStudiedAt, isNull);
    });

    test('uniqueKeys constraint prevents duplicates on userId and topicSlug', () async {
      await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(3),
              topicSlug: const drift.Value('pulmonology'),
            ),
          );

      // Attempting to insert another record with the same userId and topicSlug should throw a SqliteException
      expect(
        () => db.into(db.topicProgress).insert(
              TopicProgressCompanion.insert(
                userId: const drift.Value(3),
                topicSlug: const drift.Value('pulmonology'),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('can update a topic progress record', () async {
      final topicProgressId = await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(4),
              topicSlug: const drift.Value('gastroenterology'),
            ),
          );

      await (db.update(db.topicProgress)..where((t) => t.id.equals(topicProgressId))).write(
        const TopicProgressCompanion(
          currentBloomLevel: drift.Value(3),
          masteryScore: drift.Value(95),
        ),
      );

      final record = await (db.select(db.topicProgress)..where((t) => t.id.equals(topicProgressId))).getSingle();

      expect(record.currentBloomLevel, 3);
      expect(record.masteryScore, 95);
    });

    test('can delete a topic progress record', () async {
      final topicProgressId = await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(5),
              topicSlug: const drift.Value('endocrinology'),
            ),
          );

      var count = await db.select(db.topicProgress).get().then((v) => v.length);
      expect(count, 1);

      await (db.delete(db.topicProgress)..where((t) => t.id.equals(topicProgressId))).go();

      count = await db.select(db.topicProgress).get().then((v) => v.length);
      expect(count, 0);
    });

    test('clearUserData removes topic progress records but keeps static tables', () async {
      // Insert Question (Static Table)
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              questionText: const drift.Value('What is the capital of France?'),
            ),
          );

      // Insert TopicProgress (User Table)
      await db.into(db.topicProgress).insert(
            TopicProgressCompanion.insert(
              userId: const drift.Value(1),
              topicSlug: const drift.Value('geography'),
            ),
          );

      // Ensure they exist
      var topicProgressCount = await db.select(db.topicProgress).get().then((v) => v.length);
      var questionsCount = await db.select(db.questions).get().then((v) => v.length);

      expect(topicProgressCount, 1);
      expect(questionsCount, 1);

      // Clear user data
      await db.clearUserData();

      // Verify topic progress is gone, questions remain
      topicProgressCount = await db.select(db.topicProgress).get().then((v) => v.length);
      questionsCount = await db.select(db.questions).get().then((v) => v.length);

      expect(topicProgressCount, 0);
      expect(questionsCount, 1);
    });
  });
}
