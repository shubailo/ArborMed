import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:arbor_med/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestionProgress Table Tests', () {
    test('can insert and read a question progress record', () async {
      final now = DateTime.now().copyWith(millisecond: 0, microsecond: 0);

      final questionProgressId = await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(1),
              questionId: const drift.Value(100),
              box: const drift.Value(2),
              consecutiveCorrect: const drift.Value(3),
              mastered: const drift.Value(true),
              nextReviewAt: drift.Value(now.add(const Duration(days: 1))),
              lastAnsweredAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      final record = await (db.select(db.questionProgress)..where((t) => t.id.equals(questionProgressId))).getSingle();

      expect(record.id, questionProgressId);
      expect(record.userId, 1);
      expect(record.questionId, 100);
      expect(record.box, 2);
      expect(record.consecutiveCorrect, 3);
      expect(record.mastered, true);
      expect(record.nextReviewAt!.millisecondsSinceEpoch, now.add(const Duration(days: 1)).millisecondsSinceEpoch);
      expect(record.lastAnsweredAt!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(record.updatedAt!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('default values are applied correctly', () async {
      final questionProgressId = await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(2),
              questionId: const drift.Value(101),
            ),
          );

      final record = await (db.select(db.questionProgress)..where((t) => t.id.equals(questionProgressId))).getSingle();

      expect(record.box, 0);
      expect(record.consecutiveCorrect, 0);
      expect(record.mastered, false);
      expect(record.nextReviewAt, isNull);
      expect(record.lastAnsweredAt, isNull);
      expect(record.updatedAt, isNull);
    });

    test('uniqueKeys constraint prevents duplicates on userId and questionId', () async {
      await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(3),
              questionId: const drift.Value(102),
            ),
          );

      // Attempting to insert another record with the same userId and questionId should throw a SqliteException
      expect(
        () => db.into(db.questionProgress).insert(
              QuestionProgressCompanion.insert(
                userId: const drift.Value(3),
                questionId: const drift.Value(102),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('can update a question progress record', () async {
      final questionProgressId = await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(4),
              questionId: const drift.Value(103),
            ),
          );

      await (db.update(db.questionProgress)..where((t) => t.id.equals(questionProgressId))).write(
        const QuestionProgressCompanion(
          box: drift.Value(5),
          mastered: drift.Value(true),
        ),
      );

      final record = await (db.select(db.questionProgress)..where((t) => t.id.equals(questionProgressId))).getSingle();

      expect(record.box, 5);
      expect(record.mastered, true);
    });

    test('can delete a question progress record', () async {
      final questionProgressId = await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(5),
              questionId: const drift.Value(104),
            ),
          );

      var count = await db.select(db.questionProgress).get().then((v) => v.length);
      expect(count, 1);

      await (db.delete(db.questionProgress)..where((t) => t.id.equals(questionProgressId))).go();

      count = await db.select(db.questionProgress).get().then((v) => v.length);
      expect(count, 0);
    });

    test('clearUserData removes question progress records but keeps static tables', () async {
      // Insert Question (Static Table)
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              questionText: const drift.Value('What is the capital of France?'),
            ),
          );

      // Insert QuestionProgress (User Table)
      await db.into(db.questionProgress).insert(
            QuestionProgressCompanion.insert(
              userId: const drift.Value(1),
              questionId: const drift.Value(105),
            ),
          );

      // Ensure they exist
      var questionProgressCount = await db.select(db.questionProgress).get().then((v) => v.length);
      var questionsCount = await db.select(db.questions).get().then((v) => v.length);

      expect(questionProgressCount, 1);
      expect(questionsCount, 1);

      // Clear user data
      await db.clearUserData();

      // Verify question progress is gone, questions remain
      questionProgressCount = await db.select(db.questionProgress).get().then((v) => v.length);
      questionsCount = await db.select(db.questions).get().then((v) => v.length);

      expect(questionProgressCount, 0);
      expect(questionsCount, 1);
    });
  });
}
