import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/quest.dart';

void main() {
  group('LearningQuest', () {
    group('progress', () {
      LearningQuest createQuest({required int currentCount, required int targetCount}) {
        return LearningQuest(
          id: 'test_quest',
          period: QuestPeriod.daily,
          type: QuestType.questionsAnswered,
          title: 'Test Quest',
          description: 'A test quest',
          targetCount: targetCount,
          currentCount: currentCount,
          rewardTokens: 10,
        );
      }

      test('returns 0.0 when currentCount is 0', () {
        final quest = createQuest(currentCount: 0, targetCount: 10);
        expect(quest.progress, 0.0);
      });

      test('returns correct fraction when 0 < currentCount < targetCount', () {
        final quest = createQuest(currentCount: 5, targetCount: 10);
        expect(quest.progress, 0.5);
      });

      test('returns 1.0 when currentCount == targetCount', () {
        final quest = createQuest(currentCount: 10, targetCount: 10);
        expect(quest.progress, 1.0);
      });

      test('returns 1.0 when currentCount > targetCount', () {
        final quest = createQuest(currentCount: 15, targetCount: 10);
        expect(quest.progress, 1.0);
      });

      test('returns 0.0 when currentCount < 0', () {
        final quest = createQuest(currentCount: -5, targetCount: 10);
        expect(quest.progress, 0.0);
      });

      test('handles division by zero when targetCount is 0 (NaN clamps to 1.0 in Dart)', () {
        final quest = createQuest(currentCount: 0, targetCount: 0);
        expect(quest.progress, 1.0);
      });

      test('handles division by zero when targetCount is 0 and currentCount > 0 (Infinity clamps to 1.0)', () {
        final quest = createQuest(currentCount: 5, targetCount: 0);
        expect(quest.progress, 1.0);
      });

      test('handles division by zero when targetCount is 0 and currentCount < 0 (-Infinity clamps to 0.0)', () {
        final quest = createQuest(currentCount: -5, targetCount: 0);
        expect(quest.progress, 0.0);
      });
    });
  });
}
