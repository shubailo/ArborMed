import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/question_cache_service.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'question_cache_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late QuestionCacheService cacheService;

  setUp(() {
    mockApiService = MockApiService();
    cacheService = QuestionCacheService(mockApiService);
  });

  group('QuestionCacheService', () {
    test('init() fetches initial batch of questions', () async {
      // Arrange
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});

      // Act
      await cacheService.init('cardiology');

      // Assert
      expect(cacheService.queueSize, greaterThan(0));
      verify(mockApiService.get(argThat(contains('topic=cardiology')))).called(greaterThan(0));
    });

    test('next() returns question and removes from queue', () async {
      // Arrange
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');
      // Wait for background fetch to maximize queue? No, init awaits 1st.
      // But background fetch might still be running and looping if we don't return unique IDs.
      // With the fix above, it should be fine.
      
      final initialSize = cacheService.queueSize;

      // Act
      final q = cacheService.next();

      // Assert
      expect(q, isNotNull);
      expect(q!['id'], 1); // First one
      expect(cacheService.queueSize, initialSize - 1);
    });

    test('next() adds ID to session history', () async {
      // Arrange
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');

      // Act
      cacheService.next();

      // Assert
      expect(cacheService.sessionHistoryIds.contains(1), isTrue);
    });

    test('updateStreak() triggers predictive fetch at 15 streak', () async {
      // Arrange
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');
      // Wait for background fetch from init() to complete so _isFetching becomes false
      await Future.delayed(const Duration(milliseconds: 100));
      clearInteractions(mockApiService); // Clear init calls

      // Act
      cacheService.updateStreak(15, true);

      // Assert
      verify(mockApiService.get(argThat(contains('bloomLevel=2')))).called(greaterThan(0));
    });

    test('clear() resets state', () async {
      // Arrange
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');

      // Act
      cacheService.clear();

      // Assert
      expect(cacheService.queueSize, 0);
      expect(cacheService.sessionHistoryIds, isEmpty); 
    });

    test('next() returns null when queue is empty', () {
      expect(cacheService.next(), isNull);
    });

    test('next() fetches more questions when buffer drops to 5', () async {
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');
      await Future.delayed(const Duration(milliseconds: 200)); // Wait for background init fetch
      clearInteractions(mockApiService);

      // Initially 10 items. Pop 4 to get to 6 items remaining.
      for (int i = 0; i < 4; i++) {
        cacheService.next();
      }
      verifyNever(mockApiService.get(any)); // 6 remaining, no fetch yet

      // Pop 1 more, drops to 5 remaining.
      cacheService.next();
      verify(mockApiService.get(argThat(contains('bloomLevel=1')))).called(greaterThan(0));
    });

    test('updateStreak() does not trigger predictive fetch if bloomLevel >= 4', () async {
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology', bloomLevel: 4);
      await Future.delayed(const Duration(milliseconds: 200));
      clearInteractions(mockApiService);

      cacheService.updateStreak(15, true);
      await Future.delayed(const Duration(milliseconds: 200));

      // Should NOT fetch level 5 questions
      verifyNever(mockApiService.get(argThat(contains('bloomLevel='))));
    });

    test('updateStreak() incorrect answer clears predictive fetch and next level queue', () async {
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');
      await Future.delayed(const Duration(milliseconds: 200));

      // Trigger predictive fetch
      cacheService.updateStreak(15, true);
      await Future.delayed(const Duration(milliseconds: 200));
      clearInteractions(mockApiService);

      // Break streak
      cacheService.updateStreak(0, false);

      // If next level queue was cleared, onLevelUp will have to fetch all 10
      cacheService.onLevelUp(2);
      await Future.delayed(const Duration(milliseconds: 200));
      verify(mockApiService.get(argThat(contains('bloomLevel=2')))).called(10);
    });

    test('onLevelUp() swaps queues and fetches remaining to fill buffer', () async {
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology');
      await Future.delayed(const Duration(milliseconds: 200));

      // Trigger predictive fetch (gets 5 questions)
      cacheService.updateStreak(15, true);
      await Future.delayed(const Duration(milliseconds: 200));
      clearInteractions(mockApiService);

      cacheService.onLevelUp(2);
      await Future.delayed(const Duration(milliseconds: 200));

      // Next level queue had 5 questions, so it should fetch 5 more for level 2
      verify(mockApiService.get(argThat(contains('bloomLevel=2')))).called(5);
    });

    test('onLevelDown() clears buffers and fetches 10 for lower level', () async {
      var idCounter = 0;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': ++idCounter, 'text': 'Q$idCounter'});
      await cacheService.init('cardiology', bloomLevel: 3);
      await Future.delayed(const Duration(milliseconds: 200));
      clearInteractions(mockApiService);

      cacheService.onLevelDown(2);
      await Future.delayed(const Duration(milliseconds: 200));

      verify(mockApiService.get(argThat(contains('bloomLevel=2')))).called(10);
      expect(cacheService.queueSize, greaterThan(0));
    });

    test('fetch ignores duplicate IDs', () async {
      var apiCallCount = 0;
      when(mockApiService.get(any)).thenAnswer((_) async {
        apiCallCount++;
        // Always return ID 1 for first 3 calls, then unique IDs
        if (apiCallCount <= 3) return {'id': 1, 'text': 'Dup Q'};
        return {'id': apiCallCount, 'text': 'Q$apiCallCount'};
      });

      await cacheService.init('cardiology');
      await Future.delayed(const Duration(milliseconds: 200));

      // Initial fetch asks for 1 then 9. The queue should end up having unique IDs.
      final ids = <int>{};
      while(!cacheService.isEmpty) {
        final q = cacheService.next();
        if (q != null) ids.add(q['id'] as int);
      }

      expect(ids.length, 10);
      expect(ids.contains(1), isTrue);
    });

    test('fetch stops retrying on 404', () async {
      when(mockApiService.get(any)).thenThrow(Exception('404 Not Found'));

      await cacheService.init('cardiology');
      await Future.delayed(const Duration(milliseconds: 200));

      verify(mockApiService.get(any)).called(lessThan(5));
      expect(cacheService.queueSize, 0);
    });
  });
}
