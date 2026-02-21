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
  });
}
