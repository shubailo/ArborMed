import 'package:flutter_test/flutter_test.dart';
import 'package:feature_practice/src/application/practice_service.dart';

void main() {
  group('PracticeService', () {
    late PracticeService service;

    setUp(() {
      service = PracticeService();
    });

    test('initial state should be configured for 5 cases', () {
      expect(service.state.currentCaseIndex, 0);
      expect(service.state.totalCases, 5);
      expect(service.state.xpEarned, 0);
      expect(service.state.isCompleted, false);
    });

    test('startSession should reset state', () {
      service.completeCurrentCase(xpReward: 20);
      service.startSession(totalCases: 3);

      expect(service.state.currentCaseIndex, 0);
      expect(service.state.totalCases, 3);
      expect(service.state.xpEarned, 0);
      expect(service.state.isCompleted, false);
    });

    test('completeCurrentCase increments index and XP', () {
      service.completeCurrentCase(xpReward: 15);

      expect(service.state.currentCaseIndex, 1);
      expect(service.state.xpEarned, 15);
      expect(service.state.isCompleted, false);
    });

    test('completing all cases sets isCompleted flag', () {
      service.startSession(totalCases: 2);
      
      service.completeCurrentCase(); // index 0 completed -> index 1
      expect(service.state.isCompleted, false);
      
      service.completeCurrentCase(); // index 1 completed -> isCompleted = true
      expect(service.state.isCompleted, true);
      expect(service.state.currentCaseIndex, 1); // should not exceed bounds
    });
  });
}
