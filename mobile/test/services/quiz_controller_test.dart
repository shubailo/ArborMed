import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/quiz_controller.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/question_cache_service.dart';
import 'package:arbor_med/database/database.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate Mocks
@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<QuestionCacheService>(),
  MockSpec<AppDatabase>(),
])
import 'quiz_controller_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockQuestionCacheService mockCacheService;
  late MockAppDatabase mockDatabase;
  late QuizController controller;

  setUp(() {
    mockApiService = MockApiService();
    mockCacheService = MockQuestionCacheService();
    mockDatabase = MockAppDatabase();

    // Default Stubs
    when(mockCacheService.next()).thenReturn({'id': 100, 'text': 'Q100', 'question_type': 'single_choice'});
  });

  QuizController buildController() {
    return QuizController(
      apiService: mockApiService,
      cacheService: mockCacheService,
      db: mockDatabase,
      systemSlug: 'cardiology',
      systemName: 'Cardiology',
      userId: 1,
    );
  }

  group('QuizController', () {
    test('initializes and loads first question', () async {
      controller = buildController();
      
      // Allow async initSession to complete
      await Future.delayed(Duration.zero); 

      expect(controller.state.currentQuestion, isNotNull);
      expect(controller.state.currentQuestion!['id'], 100);
      verify(mockCacheService.init('cardiology')).called(1);
    });

    test('selectAnswer update state', () {
      controller = buildController();
      controller.selectAnswer('A');

      expect(controller.state.userAnswer, 'A');
    });

    test('submitAnswer() validates locally and calls API', () async {
      // Arrange
      when(mockCacheService.next()).thenReturn({
        'id': 100,
        'text': 'Q100',
        'question_type': 'single_choice',
        'correct_answer': 'A', // Client-side key for instant validation
        'options': ['A', 'B']
      });
      
      controller = buildController();
      await Future.delayed(Duration.zero); // Wait for loadNextQuestion
      
      controller.selectAnswer('A');

      // Act
      await controller.submitAnswer();

      // Assert
      expect(controller.state.isAnswerChecked, true);
      expect(controller.state.isCorrect, true); // Local validation passed
      
      // Verify background sync
      verify(mockApiService.post('/quiz/answer', any)).called(1);
    });

    test('loadNextQuestion() pulls from cache', () async {
      controller = buildController();
      await Future.delayed(Duration.zero); // First load

      // Act
      await controller.loadNextQuestion();

      // Assert
      verify(mockCacheService.next()).called(2); // Init + explicit call
    });
  });
}
