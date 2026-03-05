import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arbor_med/database/database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase tests', () {
    test('Questions can be inserted and fetched', () async {
      final question = QuestionsCompanion.insert(
        serverId: const Value(1),
        questionText: const Value('What is 2+2?'),
        correctAnswer: const Value('4'),
      );

      await db.into(db.questions).insert(question);

      final allQuestions = await db.select(db.questions).get();
      expect(allQuestions.length, 1);
      expect(allQuestions.first.questionText, 'What is 2+2?');
    });

    test('clearUserData clears specific tables but leaves others', () async {
      // 1. Insert data into all tables
      await db.into(db.questions).insert(QuestionsCompanion.insert(
        serverId: const Value(1),
        questionText: const Value('Q1'),
      ));
      await db.into(db.items).insert(ItemsCompanion.insert(
        serverId: const Value(1),
        name: const Value('Item1'),
      ));
      await db.into(db.topicProgress).insert(TopicProgressCompanion.insert(
        topicSlug: const Value('topic1'),
      ));
      await db.into(db.questionProgress).insert(QuestionProgressCompanion.insert(
        questionId: const Value(1),
      ));
      await db.into(db.userItems).insert(UserItemsCompanion.insert(
        serverId: const Value(1),
      ));

      // 2. Verify data is there
      expect((await db.select(db.questions).get()).length, 1);
      expect((await db.select(db.items).get()).length, 1);
      expect((await db.select(db.topicProgress).get()).length, 1);
      expect((await db.select(db.questionProgress).get()).length, 1);
      expect((await db.select(db.userItems).get()).length, 1);

      // 3. Clear user data
      await db.clearUserData();

      // 4. Verify specific tables are cleared
      expect((await db.select(db.topicProgress).get()).length, 0);
      expect((await db.select(db.questionProgress).get()).length, 0);
      expect((await db.select(db.userItems).get()).length, 0);

      // 5. Verify others are NOT cleared
      expect((await db.select(db.questions).get()).length, 1);
      expect((await db.select(db.items).get()).length, 1);
    });
  });

  group('Data Class Serialization tests', () {
    test('Question fromJson/toJson', () {
      final json = {
        'id': 1,
        'serverId': 101,
        'topicId': 5,
        'questionText': 'Test Question',
        'type': 'multiple_choice',
        'options': '["a", "b"]',
        'correctAnswer': 'a',
        'explanation': 'Because...',
        'bloomLevel': 2,
        'difficulty': 3,
        'active': true,
        'lastFetched': '2023-10-27T10:00:00.000Z',
      };

      final question = Question.fromJson(json);

      expect(question.id, 1);
      expect(question.serverId, 101);
      expect(question.questionText, 'Test Question');
      expect(question.active, true);
      expect(question.lastFetched, DateTime.parse('2023-10-27T10:00:00.000Z'));

      final backToJson = question.toJson();
      expect(backToJson['id'], 1);
      expect(backToJson['questionText'], 'Test Question');
      expect(backToJson['lastFetched'], DateTime.parse('2023-10-27T10:00:00.000Z').millisecondsSinceEpoch);
    });

    test('TopicProgressData fromJson/toJson', () {
      final json = {
        'id': 1,
        'userId': 42,
        'topicSlug': 'cardiology',
        'currentBloomLevel': 1,
        'currentStreak': 5,
        'consecutiveWrong': 0,
        'totalAnswered': 10,
        'correctAnswered': 8,
        'masteryScore': 75,
        'unlockedBloomLevel': 2,
        'questionsMastered': 3,
        'lastStudiedAt': '2023-10-27T11:00:00.000Z',
      };

      final data = TopicProgressData.fromJson(json);

      expect(data.id, 1);
      expect(data.userId, 42);
      expect(data.topicSlug, 'cardiology');
      expect(data.currentStreak, 5);
      expect(data.lastStudiedAt, DateTime.parse('2023-10-27T11:00:00.000Z'));

      final backToJson = data.toJson();
      expect(backToJson['id'], 1);
      expect(backToJson['topicSlug'], 'cardiology');
      expect(backToJson['currentStreak'], 5);
      expect(backToJson['lastStudiedAt'], DateTime.parse('2023-10-27T11:00:00.000Z').millisecondsSinceEpoch);
    });
  });
}
