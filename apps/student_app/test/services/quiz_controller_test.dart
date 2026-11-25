import 'dart:async';

import 'package:drift/native.dart';
import 'package:arbor_med/features/quiz/providers/submission_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/features/quiz/providers/quiz_controller.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
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
  late AppDatabase database;
  late SubmissionQueue queue;
  late QuizController controller;

  setUp(() {
    mockApiService = MockApiService();
    mockCacheService = MockQuestionCacheService();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    when(mockApiService.userId).thenReturn(1);
    queue = SubmissionQueue(database, mockApiService);
  });

  tearDown(() async {
    controller.dispose();
    await queue.dispose();
    await database.close();
  });

  QuizController buildController({Map<String, dynamic>? initialData}) {
    return QuizController(
      apiService: mockApiService,
      cacheService: mockCacheService,
      db: database,
      queue: queue,
      systemSlug: 'cardiology',
      systemName: 'Cardiology',
      userId: 1,
      initialQuestion: initialData,
    );
  }

  group('QuizController', () {
    test('initializes and loads first question', () async {
      when(mockCacheService.next()).thenReturn(
          {'id': 100, 'text': 'Q100', 'question_type': 'single_choice'});

      controller = buildController();
      final loaded = Completer<void>();
      void onQuestion() {
        if (controller.state.currentQuestion != null && !loaded.isCompleted) loaded.complete();
      }
      controller.addListener(onQuestion);
      onQuestion();
      try {
        await loaded.future.timeout(const Duration(seconds: 3));
        expect(controller.state.currentQuestion?['id'], 100);
      } finally {
        controller.removeListener(onQuestion);
      }
    });

    test('selectAnswer update state', () async {
      // Use initial data to avoid starting async _initSession
      // AND avoiding need for mockCacheService.next() if properly implemented
      controller = buildController(initialData: {
        'id': 100,
        'question_type': 'single_choice',
      });

      controller.selectAnswer('A');

      expect(controller.state.userAnswer, 'A');
    });

    test('prevents an old quiz controller from recording answers after an account switch', () async {
      controller = buildController(initialData: {'id': 1, 'correct_answer':'A', 'question_type':'single_choice'});
      when(mockApiService.userId).thenReturn(2);
      controller.selectAnswer('A');
      await controller.submitAnswer();
      expect(controller.state.isAnswerChecked, false);
      expect(await database.customSelect('SELECT * FROM pending_submissions').get(), isEmpty);
    });

    test('retains offline answers and reconciles the server grade after replay', () async {
      when(mockApiService.post('/quiz/answer', any)).thenThrow(Exception('offline'));
      controller = buildController(initialData: {
        'id': 100, 'question_type': 'single_choice', 'correct_answer': 'A', 'options': ['A', 'B'],
      });
      controller.selectAnswer('A');
      await controller.submitAnswer();
      expect(controller.state.isCorrect, true);
      final pending = await database.customSelect('SELECT * FROM pending_submissions').getSingle();
      final id = pending.read<String>('submission_id');
      when(mockApiService.post('/quiz/answer', any)).thenAnswer((_) async =>
          {'submissionId': id, 'isCorrect': false, 'correctAnswer': 'B', 'streakProgress': 0.0});
      when(mockApiService.userId).thenReturn(2);
      await queue.flush();
      expect(await database.customSelect('SELECT * FROM pending_submissions').get(), hasLength(1));
      when(mockApiService.userId).thenReturn(1);
      await queue.flush();
      expect(controller.state.isCorrect, false);
      expect(controller.state.correctAnswer, 'B');
      expect(await database.customSelect('SELECT * FROM pending_submissions').get(), isEmpty);
      final sent = verify(mockApiService.post('/quiz/answer', captureAny)).captured;
      expect(sent.map((p) => p['submissionId']).toSet(), {id});
    });

    test('submitAnswer() validates locally and calls API', () async {
      // Use initial data to avoid async init
      final initialQ = {
        'id': 100,
        'question_type': 'single_choice',
        'correct_answer': 'A',
        'options': ['A', 'B']
      };

      // We still need to mock API
      when(mockApiService.post('/quiz/answer', any))
          .thenAnswer((call) async => {'isCorrect': true, 'correctAnswer': 'A', 'submissionId': call.positionalArguments[1]['submissionId']});

      controller = buildController(initialData: initialQ);

      controller.selectAnswer('A');
      await controller.submitAnswer();

      expect(controller.state.isAnswerChecked, true);
      expect(controller.state.isCorrect, true); // Local validation passed

      // Verify background sync
      verify(mockApiService.post('/quiz/answer', any)).called(1);
    });

    test('submitAnswer() updates progress optimistically on success', () async {
      // Use initial data to bypass async init race conditions
      final initialQ = {
        'id': 100,
        'question_type': 'single_choice',
        'correct_answer': 'A',
        'streakProgress': 0.0,
      };

      when(mockApiService.post(any, any)).thenAnswer((call) async => {
            'submissionId': call.positionalArguments[1]['submissionId'],
            'isCorrect': true,
            'streakProgress': 0.1,
          });

      controller = buildController(initialData: initialQ);
      // No wait needed because we provided initial data

      controller.selectAnswer('A');
      final future = controller.submitAnswer();

      await future;
      expect(controller.state.levelProgress, 0.1);
    });

    test('submitAnswer() retains progress on wrong answer until server confirms', () async {
      // START with progress (Streak 1 / 0.05)
      final initialQ = {
        'id': 100,
        'question_type': 'single_choice',
        'correct_answer': 'A',
        'streakProgress': 0.05, // Already have progress
      };

      when(mockApiService.post(any, any)).thenAnswer((call) async => {
            'submissionId': call.positionalArguments[1]['submissionId'],
            'isCorrect': true,
            'streakProgress': 0.0,
          });

      controller = buildController(initialData: initialQ);

      // Verify initial state
      expect(controller.state.levelProgress, 0.05);

      // Submit WRONG answer
      controller.selectAnswer('B');
      final future = controller.submitAnswer();

      // Optimistically retains progress before server responds
      expect(controller.state.levelProgress, 0.05);

      await future;

      // Server confirms reset
      expect(controller.state.levelProgress, 0.0);
    });
  });
}
