import 'dart:async';

import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
import 'package:arbor_med/features/quiz/providers/quiz_controller.dart';
import 'package:arbor_med/features/quiz/providers/submission_queue.dart';
import 'package:arbor_med/features/quiz/screens/quiz_session_screen.dart';
import 'package:arbor_med/features/quiz/widgets/questions/single_choice_renderer.dart';
import 'package:arbor_med/features/quiz/widgets/questions/true_false_renderer.dart';
import 'package:arbor_med/features/room/screens/room_screen.dart';
import 'package:arbor_med/features/room/widgets/room_camera.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/cozy/coin_particle.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/quiz_controller_test.mocks.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  final ApiService apiService;
  @override
  User? user;
  int refreshes = 0;
  _Auth(this.apiService);
  void switchTo(int? id) {
    user = id == null ? null : User.fromJson({'id': id});
    notifyListeners();
  }

  @override
  Future<void> refreshUser() async {
    refreshes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  Future<void> playSfx(String name) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockApiService api;
  late _Auth auth;
  late AppDatabase db;
  late SubmissionQueue queue;
  late QuestionCacheService cache;
  final question = <String, dynamic>{
    'id': 7,
    'question_text_en': 'Visible quiz question',
    'content': {
      'question_text': {'en': 'Content-only prompt'}
    },
    'correct_answer': 'True',
    'choice_options': [
      {'id': 'opt_first', 'en': 'Igaz', 'hu': 'Első'},
      {'id': 'opt_second', 'en': 'True', 'hu': 'Második'},
    ],
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = MockApiService();
    auth = _Auth(api)..switchTo(1);
    when(api.userId).thenAnswer((_) => auth.user?.id);
    when(api.get(any)).thenAnswer((_) async => {...question, 'id': 8});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SubmissionQueue(db, api);
    cache = QuestionCacheService(api);
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
    auth.dispose();
  });

  Widget app(Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<LocaleProvider>(
              create: (_) => LocaleProvider()),
          Provider.value(value: queue),
          Provider.value(value: cache),
        ],
        child: MaterialApp(home: home),
      );
  Widget quiz() => QuizSessionScreen(
      systemName: 'Renal', systemSlug: 'renal', initialData: question);

  testWidgets(
      'switching or losing the account ends the original quiz and drops its question',
      (t) async {
    await t.pumpWidget(app(quiz()));
    expect(find.text('Visible quiz question'), findsOneWidget);
    auth.switchTo(2);
    await t.pump();
    expect(find.text('Visible quiz question'), findsNothing);
    expect(find.text('This quiz session has ended.'), findsOneWidget);
    auth.switchTo(1);
    await t.pump();
    expect(find.text('Visible quiz question'), findsNothing);
    await t.pumpWidget(const SizedBox());
    auth.switchTo(null);
    await t.pumpWidget(app(quiz()));
    expect(find.text('This quiz session has ended.'), findsOneWidget);
  });

  test(
      'ordinary option labels do not acquire the aliases of true/false questions',
      () {
    final renderer = SingleChoiceRenderer();
    expect(
        renderer.validateAnswer('Igaz', 'True', {
          'options': ['Igaz', 'True']
        }),
        isFalse);
    expect(TrueFalseRenderer().validateAnswer('Igaz', 'True', {}), isTrue);
    expect(renderer.validateAnswer('opt_second', 'True', question), isTrue);
    expect(renderer.validateAnswer('opt_first', 'True', question), isFalse);
    expect(renderer.validateAnswer('opt_first', 'Első', question), isTrue);
  });

  testWidgets(
      'content-only prompts render and a blank localized column falls back to English',
      (t) async {
    for (final entry in [
      (
        {
          'content': {
            'question_text': {'en': 'Content prompt'}
          }
        },
        'Content prompt'
      ),
      (
        {'question_text_en': '  ', 'content': {}, 'text': 'Fallback prompt'},
        'Fallback prompt'
      ),
    ]) {
      await t.pumpWidget(app(QuizSessionScreen(
        key: ValueKey(entry.$2),
        systemName: 'Renal',
        systemSlug: 'renal',
        initialData: {...question, 'question_text_en': null, ...entry.$1},
      )));
      expect(find.text(entry.$2), findsOneWidget);
    }
  });

  testWidgets(
      'invalid optional image metadata cannot prevent answering a content-only question',
      (t) async {
    await t.pumpWidget(app(QuizSessionScreen(
        systemName: 'Renal',
        systemSlug: 'renal',
        initialData: {
          ...question,
          'question_text_en': null,
          'content': {'question_text': 'Visible prompt', 'image_url': 17},
        })));
    expect(t.takeException(), isNull);
    expect(find.text('Visible prompt'), findsOneWidget);
    expect(find.text('Igaz'), findsOneWidget);
  });

  testWidgets('the coin effect removes its completed overlay', (t) async {
    when(api.post('/quiz/answer', any)).thenAnswer((call) async => {
          'submissionId': call.positionalArguments[1]['submissionId'],
          'isCorrect': true,
          'correctAnswer': 'True',
          'topicSlug': 'renal',
          'coinsEarned': 1,
        });
    await t.pumpWidget(app(quiz()));
    final controller = Provider.of<QuizController>(
        t.element(find.text('Visible quiz question')),
        listen: false);
    await t.runAsync(() async {
      controller.selectAnswer('opt_second');
      await controller.submitAnswer();
      await Future<void>.delayed(Duration.zero);
    });
    await t.pump();
    expect(find.byType(CoinParticle), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    expect(find.byType(CoinParticle), findsNothing);
    expect(auth.refreshes, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'finishing a covered quiz loader preserves the dialog and the route underneath it',
      (t) async {
    final handshake = Completer<dynamic>();
    when(api.post('/quiz/start', any)).thenAnswer((_) => handshake.future);
    late BuildContext home;
    bool? finished;
    await t.pumpWidget(app(Builder(builder: (context) {
      home = context;
      return const Scaffold(body: Text('Room'));
    })));
    openRoomQuiz(home, 'Renal', 'renal', 1).then((value) => finished = value);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final navigator = Navigator.of(home);
    final dialog = showDialog<void>(
        context: home,
        builder: (_) => const AlertDialog(title: Text('Unrelated dialog')));
    await t.pump();
    handshake.complete({'id': 10});
    for (var i = 0; i < 7; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Unrelated dialog'), findsOneWidget);
    navigator.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await dialog;
    expect(find.text('Visible quiz question'), findsOneWidget);
    navigator.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(finished, true);
    expect(find.text('Room'), findsOneWidget);
  });

  testWidgets(
      'a second room camera motion replaces the first and disposal cancels an active ticker',
      (t) async {
    final transform = TransformationController();
    final camera = RoomCamera(transform, t);
    camera.animateTo(
        Matrix4.translationValues(80, 0, 0), const Duration(seconds: 2));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    camera.animateTo(
        Matrix4.translationValues(5, 0, 0), const Duration(milliseconds: 100));
    await t.pump();
    await t.pump(const Duration(milliseconds: 150));
    expect(transform.value.getTranslation().x, closeTo(5, 0.001));
    await t.pump(const Duration(seconds: 2));
    expect(transform.value.getTranslation().x, closeTo(5, 0.001));
    camera.animateTo(Matrix4.identity(), const Duration(seconds: 2));
    camera.dispose();
    transform.dispose();
    await t.pump(const Duration(seconds: 3));
    expect(t.takeException(), isNull);
  });
}
