import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/database/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Questions Table Tests', () {
    test('can insert and read a question with all fields populated', () async {
      // Drift (or SQLite) datetime precision might just be up to the second.
      // We will parse back from a rounded second to check equality.
      final now = DateTime.now().copyWith(millisecond: 0, microsecond: 0);

      final questionId = await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              serverId: const drift.Value(1),
              topicId: const drift.Value(2),
              questionText: const drift.Value('What is the capital of France?'),
              type: const drift.Value('multiple_choice'),
              options: const drift.Value('["Paris", "London", "Berlin", "Madrid"]'),
              correctAnswer: const drift.Value('Paris'),
              explanation: const drift.Value('Paris is the capital and most populous city of France.'),
              bloomLevel: const drift.Value(1),
              difficulty: const drift.Value(1),
              active: const drift.Value(true),
              lastFetched: drift.Value(now),
            ),
          );

      final question = await (db.select(db.questions)..where((t) => t.id.equals(questionId))).getSingle();

      expect(question.serverId, 1);
      expect(question.topicId, 2);
      expect(question.questionText, 'What is the capital of France?');
      expect(question.type, 'multiple_choice');
      expect(question.options, '["Paris", "London", "Berlin", "Madrid"]');
      expect(question.correctAnswer, 'Paris');
      expect(question.explanation, 'Paris is the capital and most populous city of France.');
      expect(question.bloomLevel, 1);
      expect(question.difficulty, 1);
      expect(question.active, true);

      expect(question.lastFetched!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('default values are applied correctly', () async {
      final questionId = await db.into(db.questions).insert(
            QuestionsCompanion.insert(),
          );

      final question = await (db.select(db.questions)..where((t) => t.id.equals(questionId))).getSingle();

      expect(question.active, true); // Default from boolean().withDefault(const Constant(true))()
      expect(question.serverId, isNull);
      expect(question.topicId, isNull);
    });

    test('unique constraint on serverId', () async {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              serverId: const drift.Value(100),
            ),
          );

      // Attempting to insert another question with the same serverId should throw a SqliteException
      expect(
        () => db.into(db.questions).insert(
              QuestionsCompanion.insert(
                serverId: const drift.Value(100),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('clearUserData does NOT clear questions table', () async {
      // Insert Question
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              questionText: const drift.Value('Static Question'),
            ),
          );

      // Insert UserItem (user specific data to verify clearUserData works)
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              name: const drift.Value('Item to keep'),
            ),
          );
      await db.into(db.userItems).insert(
            UserItemsCompanion.insert(
              userId: const drift.Value(1),
              itemId: drift.Value(itemId),
            ),
          );

      // Ensure they exist
      var questionsCount = await db.select(db.questions).get().then((v) => v.length);
      var userItemsCount = await db.select(db.userItems).get().then((v) => v.length);

      expect(questionsCount, 1);
      expect(userItemsCount, 1);

      // Clear user data
      await db.clearUserData();

      // Verify questions are NOT gone, but user items are gone
      questionsCount = await db.select(db.questions).get().then((v) => v.length);
      userItemsCount = await db.select(db.userItems).get().then((v) => v.length);

      expect(questionsCount, 1); // Questions is kept
      expect(userItemsCount, 0); // User items is cleared
    });
  });
}
