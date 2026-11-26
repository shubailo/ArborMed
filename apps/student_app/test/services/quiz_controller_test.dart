import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/widgets/cozy/liquid_button.dart';
import 'package:arbor_med/features/quiz/widgets/questions/matching_renderer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/features/quiz/widgets/components/quiz_body.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/core/api_exceptions.dart';

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
  MockSpec<AppDatabase>(),
])
import 'quiz_controller_test.mocks.dart';

void main() {

  late MockApiService mockApiService;
  late QuestionCacheService cache;
  late AppDatabase database;
  late SubmissionQueue queue;
  late QuizController controller;

  setUp(() {
    mockApiService = MockApiService();
    cache = QuestionCacheService(mockApiService);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    when(mockApiService.userId).thenReturn(1);
    queue = SubmissionQueue(database, mockApiService);
  });

  tearDown(() async {
    controller.dispose();
    await queue.dispose();
    await database.close();
  });

  QuizController buildController({Map<String, dynamic>? initialData, List<int>? review}) {
    return QuizController(
      apiService: mockApiService,
      cacheService: cache,
      db: database,
      queue: queue,
      systemSlug: 'cardiology',
      systemName: 'Cardiology',
      userId: 1,
      initialQuestion: initialData,
      questionIds: review,
    );
  }

  group('QuizController', () {
    test('legacy practice type survives normalization and canonical type takes precedence', () {
      controller = buildController(initialData: {'id': 1, 'type': 'true_false'});
      expect(controller.state.currentQuestion?['question_type'], 'true_false');
      expect(normalizePracticeQuestion({'id': 1, 'type': 'relational_analysis'})['question_type'], 'relation_analysis');
      expect(normalizePracticeQuestion({'id': 1, 'type': 'single_choice', 'question_type': 'future_type'})['question_type'], 'future_type');
    });

    for (final type in ['future_type', 7]) {
      testWidgets('unsupported question type $type can be skipped without a submission', (tester) async {
        SharedPreferences.setMockInitialValues({});
        when(mockApiService.get(any)).thenAnswer((_) async => {'id': 8});
        controller = buildController(initialData: {
          'id': 7, 'question_type': type, 'correct_answer': 'A',
          'options': ['A', 'B'], 'streakProgress': 0.3,
        });
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider<QuizController>.value(value: controller),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: QuizBody(systemName: 'Renal')),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('This question type is not supported.'), findsOneWidget);
        expect(find.text('A'), findsNothing);
        controller.selectAnswer('A');
        await tester.runAsync(controller.submitAnswer);
        expect(controller.state.isAnswerChecked, false);
        expect(controller.state.levelProgress, 0.3);
        verifyNever(mockApiService.post('/quiz/answer', any));
        await tester.tap(find.text('Next Question'));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpWidget(const SizedBox());
        expect(controller.state.currentQuestion?['id'], 8);
      });
    }

    test('a mismatched review result leaves the requested question available for retry', () async {
      when(mockApiService.get('/quiz/questions/5')).thenAnswer((_) async => {'id': 6});
      controller = buildController(review: [5]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.currentQuestion, isNull);
      expect(controller.state.isReviewComplete, false);
      when(mockApiService.get('/quiz/questions/5')).thenAnswer((_) async => {'id': '5'});
      await controller.loadNextQuestion();
      expect(controller.state.currentQuestion?['id'], 5);
    });

    test('changing section replaces the progress bar and clears the previous feedback', () async {
      when(mockApiService.get(any)).thenAnswer((_) async => {
        'id': 8, 'topic_slug': 'renal', 'currentBloom': 2, 'streakProgress': 0.15,
      });
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NetworkException());
      controller = buildController(initialData: {
        'id': 7, 'topic_slug': 'heart', 'streakProgress': 0.80,
        'correct_answer': 'A', 'explanation': 'First explanation',
      });
      controller.selectAnswer('A');
      await controller.submitAnswer();
      expect(controller.state.isCorrect, true);
      await controller.loadNextQuestion();
      expect(controller.state.levelProgress, 0.15);
      expect(controller.state.currentBloomLevel, 2);
      expect(controller.state.correctAnswer, isNull);
      expect(controller.state.explanation, isEmpty);
    });

    test('a late receipt updates progress in the same section without grading the new question', () async {
      when(mockApiService.get(any)).thenAnswer((_) async => {
        'id': 8, 'topic_slug': 'renal', 'streakProgress': 0.50,
      });
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NetworkException());
      controller = buildController(initialData: {
        'id': 7, 'topic_slug': 'renal', 'correct_answer': 'A', 'streakProgress': 0.50,
      });
      controller.selectAnswer('A');
      await controller.submitAnswer();
      expect(controller.state.levelProgress, closeTo(0.55, 0.001));
      await controller.loadNextQuestion();
      expect(controller.state.levelProgress, 0.50);
      when(mockApiService.post('/quiz/answer', any)).thenAnswer((call) async => {
        'submissionId': call.positionalArguments[1]['submissionId'], 'isCorrect': true,
        'topicSlug': 'renal', 'currentBloom': 2, 'streakProgress': 0.0,
      });
      await queue.flush();
      expect(controller.state.currentQuestion?['id'], 8);
      expect(controller.state.isAnswerChecked, false);
      expect(controller.state.levelProgress, 0.0);
      expect(controller.state.currentBloomLevel, 2);
    });

    test('a definitive rejection withdraws the local grade and a new question can be opened', () async {
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': 8});
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NotFoundException());
      controller = buildController(initialData: {
        'id': 7, 'correct_answer': 'A', 'streakProgress': 0.95, 'explanation': 'Local grade',
      });
      controller.selectAnswer('A');
      await controller.submitAnswer();
      expect(controller.state.isAnswerChecked, false);
      expect(controller.state.isCorrect, false);
      expect(controller.state.correctAnswer, isNull);
      expect(controller.state.explanation, isEmpty);
      expect(controller.state.levelProgress, 0.95);
      await controller.submitAnswer();
      verify(mockApiService.post('/quiz/answer', any)).called(1);
      await controller.loadNextQuestion();
      expect(controller.state.currentQuestion?['id'], 8);
    });

    testWidgets('the rejection panel offers a working next-question action', (tester) async {
      SharedPreferences.setMockInitialValues({});
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': 8});
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NotFoundException());
      await tester.runAsync(() async {
        controller = buildController(initialData: {'id': 7, 'correct_answer': 'A'});
        controller.selectAnswer('A');
        await controller.submitAnswer();
      });
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<QuizController>.value(value: controller),
        ],
        child: const MaterialApp(home: Scaffold(body: QuizBody(systemName: 'Renal'))),
      ));
      expect(find.textContaining('The server rejected this answer'), findsOneWidget);
      await tester.tap(find.text('Next question'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(const SizedBox());
      expect(controller.state.currentQuestion?['id'], 8);
    });

    test('initializes and loads first question', () async {
      when(mockApiService.get(any)).thenAnswer((_) async =>
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

    test('mistake review retries a transient failure and skips only unavailable questions', () async {
      when(mockApiService.get('/quiz/questions/4')).thenThrow(const NotFoundException());
      when(mockApiService.get('/quiz/questions/5')).thenThrow(const NetworkException());
      controller = buildController(review: [4,5]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isReviewComplete, false);
      expect(controller.state.error, isNotNull);
      when(mockApiService.get('/quiz/questions/5')).thenAnswer((_) async => {'id':5});
      await controller.loadNextQuestion();
      expect(controller.state.currentQuestion?['id'], 5);
      await controller.loadNextQuestion();
      expect(controller.state.isReviewComplete, true);
      expect(controller.state.currentQuestion, isNull);
      verify(mockApiService.get('/quiz/questions/4')).called(1);
    });

    test('an account change discards a previously requested mistake', () async {
      final pending = Completer<dynamic>();
      when(mockApiService.get('/quiz/questions/5')).thenAnswer((_) => pending.future);
      controller = buildController(review: [5]);
      await Future<void>.delayed(Duration.zero);
      when(mockApiService.userId).thenReturn(2);
      pending.complete({'id': 5});
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.currentQuestion, isNull);
      expect(controller.state.error, isNotNull);
    });

    test('server receipt stores review progress under the canonical question topic', () async {
      controller = buildController(initialData: {'id':1});
      when(mockApiService.post('/quiz/answer', any)).thenAnswer((call) async => {
        'submissionId': call.positionalArguments[1]['submissionId'], 'isCorrect':true, 'topicSlug':'renal', 'currentBloom':3,
      });
      await queue.enqueue(1, 'review', {'questionId':7,'userAnswer':'correct'});
      await queue.flush();
      final row = await database.select(database.topicProgress).getSingle();
      expect(row.topicSlug, 'renal');
      expect(row.currentBloomLevel, 3);
    });

    test('selectAnswer update state', () async {
      // Use initial data to avoid starting async _initSession
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

    testWidgets('an incomplete cached relation can be skipped without recording a grade', (t) async {
      SharedPreferences.setMockInitialValues({});
      when(mockApiService.get('/quiz/questions/18')).thenAnswer((_) async => {'id': 18});
      controller = buildController(review: [18], initialData: {
        'id': 17, 'question_type': 'relation_analysis', 'correct_answer': 'B',
        'text': 'Generic instructions', 'content': {'statement1': 'Only half the question'},
      });
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: QuizBody(systemName: 'Renal')),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text('Submit Answer'), findsNothing);
      await t.runAsync(() async {
        controller.selectAnswer('B');
        await controller.submitAnswer();
        expect(controller.state.isAnswerChecked, isFalse);
        expect(await database.customSelect('SELECT * FROM pending_submissions').get(), isEmpty);
      });
      await t.tap(find.text('Next Question'));
      await t.pumpAndSettle();
      expect(controller.state.currentQuestion?['id'], 18);
      verifyNever(mockApiService.post('/quiz/answer', any));
      await t.pumpWidget(const SizedBox());
    });

    test('a historical relation key and the answer sent for offline replay agree', () async {
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NetworkException());
      controller = buildController(initialData: {
        'id': 17, 'question_type': 'relational_analysis', 'text': 'Both statements together',
        'correct_answer': '["E"]', 'options': [{'value': 'E', 'label': 'Neither is true'}],
      });
      expect(controller.state.currentQuestion?['question_type'], 'relation_analysis');
      controller.selectAnswer(['E']);
      await controller.submitAnswer();
      expect(controller.state.isAnswerChecked, isFalse);
      controller.selectAnswer(' e ');
      await controller.submitAnswer();
      expect(controller.state.isCorrect, isTrue);
      final call = verify(mockApiService.post('/quiz/answer', captureAny)).captured.single;
      expect(call['userAnswer'], 'E');
      expect(await database.customSelect('SELECT * FROM pending_submissions').get(), hasLength(1));
    });

    testWidgets('matching submit becomes available only after a complete one-to-one attempt', (t) async {
      SharedPreferences.setMockInitialValues({});
      controller = buildController(review: [18], initialData: {
        'id': 17, 'question_type': 'matching', 'correct_answer': {'A':'X','B':'Y'},
        'matching_data': {'left':['A','B'], 'right':['Y','X']},
      });
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: QuizBody(systemName: 'Renal')),
        ),
      ));
      await t.pumpAndSettle();
      LiquidButton submit() => t.widget<LiquidButton>(
        find.widgetWithText(LiquidButton, 'Submit Answer'));
      expect(submit().onPressed, isNull);
      controller.selectAnswer({'A':'Y'});
      await t.pump();
      expect(submit().onPressed, isNull);
      controller.selectAnswer({'A':'Y','B':'X'});
      await t.pump();
      expect(submit().onPressed, isNotNull);
      final outgoing = t.widget<MatchingInputWidget>(find.byType(MatchingInputWidget)).onAnswerChanged;
      when(mockApiService.get(any)).thenAnswer((_) async => {'id': 18});
      await t.runAsync(controller.loadNextQuestion);
      expect(controller.state.currentQuestion?['id'], 18);
      outgoing({'A':'X','B':'Y'});
      expect(controller.state.userAnswer, isNull);
      await t.pumpWidget(const SizedBox());
    });

    test('a partial or out-of-board matching answer never enters the submission queue', () async {
      controller = buildController(initialData:{
        'id': 17, 'question_type':'matching', 'correct_answer':{'A':'X','B':'Y'},
        'matching_data':{'left':['B','A'],'right':['X','Y']},
      });
      when(mockApiService.post('/quiz/answer', any)).thenThrow(const NetworkException());
      for (final draft in [{}, {'A':'X'}, {'A':'X','B':'X'}, {'A':'X','C':'Y'}]) {
        controller.selectAnswer(draft);
        await controller.submitAnswer();
        expect(controller.state.isAnswerChecked, isFalse);
        expect(await database.customSelect('SELECT * FROM pending_submissions').get(), isEmpty);
      }
      verifyNever(mockApiService.post('/quiz/answer', any));
      controller.selectAnswer({'B':'Y','A':'X'});
      await controller.submitAnswer();
      expect(controller.state.isCorrect,isTrue);
      final call=verify(mockApiService.post('/quiz/answer',captureAny)).captured.single;
      expect(call['userAnswer'],{'A':'X','B':'Y'});
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
