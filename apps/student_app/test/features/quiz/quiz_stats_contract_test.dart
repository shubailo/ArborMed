import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'dart:async';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/quiz/screens/quiz_loading_screen.dart';
import 'package:arbor_med/features/quiz/widgets/questions/multiple_choice_renderer.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../../services/quiz_controller_test.mocks.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  final ApiService apiService;
  @override
  User? user;
  _Auth(this.apiService);
  @override
  int sessionRevision = 0;
  void switchTo(int? id) {
    if (user?.id != id) sessionRevision++;
    user = id == null ? null : User.fromJson({'id': id});
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child) => ChangeNotifierProvider(
    create: (_) => ThemeService(), child: MaterialApp(home: child));

void main() {
  late MockApiService api;
  late _Auth auth;
  late StatsProvider stats;
  setUp(() {
    api = MockApiService();
    auth = _Auth(api)..switchTo(1);
    stats = StatsProvider(auth);
  });
  tearDown(() {
    stats.dispose();
    auth.dispose();
  });

  test(
      'switching accounts while two summaries load preserves only the current user and spinner',
      () async {
    final first = Completer<dynamic>();
    final second = Completer<dynamic>();
    when(api.get(ApiEndpoints.statsSummary)).thenAnswer((_) => first.future);
    final old = stats.fetchSummary();
    auth.switchTo(2);
    when(api.get(ApiEndpoints.statsSummary)).thenAnswer((_) => second.future);
    final current = stats.fetchSummary();
    first.complete([
      {'slug': 'former'}
    ]);
    await old;
    expect(stats.isLoading, isTrue);
    expect(stats.subjectMastery, isEmpty);
    second.complete([
      {'slug': 'current'}
    ]);
    await current;
    auth.switchTo(2);
    expect(stats.subjectMastery.single.slug, 'current');
    auth.switchTo(1);
    expect(stats.subjectMastery, isEmpty);
  });

  test(
      'logout and re-entry with the same ID discard a pending subject failure and mistake list',
      () async {
    final section = Completer<dynamic>();
    final mistakes = Completer<dynamic>();
    when(api.get(argThat(contains('/subject/'))))
        .thenAnswer((_) => section.future);
    when(api.get(argThat(contains('mistakes'))))
        .thenAnswer((_) => mistakes.future);
    final detail = stats.fetchSubjectDetail('renal');
    final ids = stats.fetchMistakeIds();
    auth.switchTo(null);
    auth.switchTo(1);
    section.completeError(StateError('old'));
    mistakes.complete([7]);
    await detail;
    expect(stats.getSectionState('renal'), SubjectQuizState.initial);
    expect(await ids, isNull);
  });

  test(
      'superseded subject-detail failures do not overwrite a newer successful response',
      () async {
    final first = Completer<dynamic>();
    when(api.get(any)).thenAnswer((_) => first.future);
    final old = stats.fetchSubjectDetail('renal');
    when(api.get(any)).thenAnswer((_) async => [
          {'slug': 'new'}
        ]);
    await stats.fetchSubjectDetail('renal');
    first.completeError(StateError('old'));
    await old;
    expect(stats.getSectionState('renal'), SubjectQuizState.loaded);
    expect(stats.sectionMastery['renal']!.single['slug'], 'new');
  });

  test(
      'an activity preload waits for its work, preserves the chosen month and updates daily progress',
      () async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final current = Completer<dynamic>();
    final history = Completer<dynamic>();
    final summary = Completer<dynamic>();
    final requests = <String>[];
    when(api.get(any)).thenAnswer((call) async {
      final path = call.positionalArguments.first as String;
      requests.add(path);
      if (path == ApiEndpoints.statsSummary) return summary.future;
      if (path.contains('timeframe=week')) return current.future;
      if (path.contains('timeframe=month')) return history.future;
      if (path == ApiEndpoints.statsSmartReview) return {'recommendations': []};
      return <String, dynamic>{};
    });
    var finished = false;
    final warm = stats.preFetchData().then((_) => finished = true);
    final browsing = stats.fetchActivity(
        timeframe: 'month', anchorDate: DateTime(2000, 1, 1));
    history.complete([
      {'date': '2000-01-01', 'correct_count': 9}
    ]);
    await browsing;
    summary.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    current.complete([
      {
        'date': DateTime.parse(today)
            .toUtc()
            .subtract(const Duration(hours: 14))
            .toIso8601String(),
        'calendar_date': today,
        'correct_count': 4
      }
    ]);
    await warm;
    expect(stats.activity.single.date.year, 2000);
    expect(stats.activity.single.correctCount, 9);
    expect(stats.todayCorrectAnswers, 4);
    expect(
        requests
            .where((path) => path.startsWith(ApiEndpoints.statsActivity))
            .length,
        2);
  });

  test(
      'a failed or malformed mistake list stays distinct from an empty successful response',
      () async {
    when(api.get(any)).thenAnswer((_) async => []);
    expect(await stats.fetchMistakeIds(), isEmpty);
    when(api.get(any)).thenAnswer((_) async => [7, 'bad']);
    await expectLater(stats.fetchMistakeIds(), throwsFormatException);
    when(api.get(any)).thenAnswer((_) async => throw StateError('offline'));
    await expectLater(stats.fetchMistakeIds(), throwsStateError);
  });

  test(
      'legacy bilingual multi-select requires each expected option exactly once',
      () {
    final renderer = MultipleChoiceRenderer();
    final q = {
      'options': {
        'en': ['Red', 'Blue'],
        'hu': ['Piros', 'Kék']
      }
    };
    expect(renderer.validateAnswer(['Piros', 'Piros'], ['Red', 'Blue'], q),
        isFalse);
    expect(renderer.validateAnswer(['Piros', 'unknown'], ['Red'], q), isFalse);
    expect(renderer.validateAnswer(['Piros'], ['Red', 'unknown'], q), isFalse);
    expect(
        renderer.validateAnswer(['Kék', 'Piros'], ['Red', 'Blue'], q), isTrue);
    expect(
        renderer.validateAnswer([
          'Piros'
        ], [
          'Red'
        ], {
          'content': {
            'options': [
              {'en': 'Red', 'hu': 'Piros'},
              {'en': 'Blue', 'hu': 'Kék'}
            ]
          }
        }),
        isTrue);
    expect(renderer.formatAnswer([]), isNull);
  });

  test(
      'a shared label cannot select an arbitrary option when stable IDs are available',
      () {
    final renderer = MultipleChoiceRenderer();
    final q = {
      'choice_options': [
        {'id': 'left', 'en': 'Same', 'hu': 'Első'},
        {'id': 'right', 'en': 'Same', 'hu': 'Második'}
      ]
    };
    expect(renderer.validateAnswer(['left'], ['Same'], q), isFalse);
    expect(renderer.validateAnswer(['right'], ['Második'], q), isTrue);
  });

  testWidgets(
      'malformed optional image metadata leaves an English multi-select usable',
      (t) async {
    await t.pumpWidget(_app(Scaffold(
        body: Builder(
            builder: (context) =>
                MultipleChoiceRenderer().buildQuestion(context, {
                  'text': 'Pick two',
                  'content': {'image_url': 17}
                })))));
    expect(t.takeException(), isNull);
    expect(find.text('Pick two'), findsOneWidget);
    expect(find.text('Select all correct answers.'), findsOneWidget);
  });

  testWidgets(
      'Hungarian quiz instructions and loader errors use the active locale',
      (t) async {
    final request = Completer<Map<String, dynamic>>();
    Widget app(Widget home) => ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: MaterialApp(
            locale: const Locale('hu'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home));
    await t.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (ctx) => MultipleChoiceRenderer()
                .buildQuestion(ctx, {'text': 'Kérdés'})))));
    await t.pumpAndSettle();
    expect(find.text('Válassz ki minden helyes választ!'), findsOneWidget);
    await t.pumpWidget(app(QuizLoadingScreen(
        systemName: 'Vese', dataFuture: request.future, onComplete: (_) {})));
    await t.pump();
    expect(find.text('Vese – a kvíz előkészítése'), findsOneWidget);
    request.completeError(StateError('offline'));
    await t.pumpAndSettle();
    expect(find.text('A kvízt nem sikerült betölteni'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'replacing an in-flight transition delivers only the replacement quiz',
      (t) async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    final ids = <int>[];
    Widget load(Completer<Map<String, dynamic>> request) =>
        _app(QuizLoadingScreen(
            systemName: 'Test',
            dataFuture: request.future,
            onComplete: (data) => ids.add(data['id'] as int)));
    await t.pumpWidget(load(first));
    first.complete({'id': 1});
    await t.pump();
    await t.pump(const Duration(milliseconds: 850));
    await t.pumpWidget(load(second));
    await t.pump(const Duration(seconds: 1));
    expect(ids, isEmpty);
    second.complete({'id': 2});
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(ids, [2]);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'compact loading and error screens fit, and the failed request stops scheduling frames',
      (t) async {
    await t.binding.setSurfaceSize(const Size(420, 190));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final request = Completer<Map<String, dynamic>>();
    await t.pumpWidget(_app(QuizLoadingScreen(
        systemName: 'Compact',
        dataFuture: request.future,
        onComplete: (_) {})));
    expect(t.takeException(), isNull);
    request.completeError(StateError('internal detail'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.text('Could not load the quiz'), findsOneWidget);
    expect(find.textContaining('internal detail'), findsNothing);
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(const SizedBox());
  });
}
