import 'dart:convert';
import 'package:arbor_med/features/quiz/widgets/questions/matching_renderer.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  Future<void> playSfx(String name) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final renderer = MatchingRenderer();
  final data = {
    'left': [
      {'en': 'A', 'hu': 'Bal A'},
      {'en': 'B', 'hu': ' '}
    ],
    'right': [
      {'en': 'Y', 'hu': 'Jobb Y'},
      {'en': 'X', 'hu': 'Jobb X'}
    ],
  };
  Map<String, dynamic> question(int id) => {
        'id': id,
        'question_type': 'matching',
        'question_text_hu': 'Kösd össze!',
        'text': 'Connect them!',
        'matching_data': jsonEncode(data)
      };
  late List<dynamic> answers;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    answers = [];
  });

  Future<void> show(WidgetTester t, Map<String, dynamic> q,
      {dynamic current,
      bool checked = false,
      dynamic key,
      String lang = 'hu'}) async {
    await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
        ],
        child: MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: Builder(
                    builder: (context) => Column(children: [
                          renderer.buildQuestion(context, q),
                          renderer.buildAnswerInput(
                              context, q, current, answers.add,
                              isChecked: checked, correctAnswer: key),
                        ]))))));
    await t.pumpAndSettle();
  }

  testWidgets(
      'saved prompt, shuffled labels and a missing translation keep their English answer identities',
      (t) async {
    await show(t, question(1));
    expect(find.text('Kösd össze!'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    await t.tap(find.text('Jobb Y'));
    await t.pump();
    await show(t, question(1), lang: 'en');
    await t.tap(find.text('A'));
    await t.pump();
    expect(answers.single, {'A': 'Y'});
    expect(find.textContaining('Paired with Y'), findsOneWidget);
    await t.tap(find.text('B'));
    await t.pump();
    await t.tap(find.text('X'));
    await t.pump();
    expect(answers.first, {'A': 'Y'});
    expect(answers.last, {'A': 'Y', 'B': 'X'});
    await t.tap(find.text('X'));
    await t.pump();
    expect(answers.last, {'A': 'Y'});
    expect(answers[1], {'A': 'Y', 'B': 'X'});
  });

  testWidgets('rapid taps read the current connection before the next frame',
      (t) async {
    await show(t, question(1));
    VoidCallback tap(String label) => t
        .widget<InkWell>(
            find.ancestor(of: find.text(label), matching: find.byType(InkWell)))
        .onTap!;
    final left = tap('Bal A'), right = tap('Jobb X');
    left();
    right();
    right();
    expect(answers, [
      {'A': 'X'},
      {}
    ]);
  });

  testWidgets(
      'question changes and restored answers reset pending taps and replace visible pairs',
      (t) async {
    await show(t, question(1), current: {'A': 'Y'});
    await t.tap(find.text('B'));
    await t.pump();
    await show(t, question(2), current: {'B': 'Y'});
    await t.tap(find.text('Jobb X'));
    await t.pump();
    expect(answers, isEmpty);
    await t.tap(find.text('Bal A'));
    await t.pump();
    expect(answers.single, {'A': 'X', 'B': 'Y'});
    await show(t, question(2), current: {'B': 'X'});
    await t.tap(find.text('Jobb X'));
    await t.pump();
    expect(answers.last, isEmpty);
  });

  testWidgets(
      'checked pairs show the submitted partner and expected partner without accepting taps',
      (t) async {
    await show(t, question(1),
        current: {'A': 'Y', 'B': 'X'}, checked: true, key: '{"A":"X","B":"Y"}');
    expect(find.textContaining('Kiválasztott pár: Jobb Y'), findsOneWidget);
    expect(find.textContaining('Helyes válasz: Jobb X'), findsOneWidget);
    expect(t.widget<InkWell>(find.byType(InkWell).first).onTap, isNull);
    await t.tap(find.text('Bal A'));
    await t.pump();
    expect(answers, isEmpty);
  });

  testWidgets(
      'malformed pairs produce a localized empty state and no interactive rows',
      (t) async {
    for (final raw in [
      null,
      '{',
      '{}',
      {
        'left': 'A',
        'right': ['X', 'Y']
      },
      {
        'left': ['A', 'A'],
        'right': ['X', 'Y']
      },
      {
        'left': [null, 'B'],
        'right': ['X', 'Y']
      },
      {
        'left': ['A', 'B'],
        'right': ['Y']
      },
    ]) {
      await show(t, {'id': 1, 'matching_data': raw});
      final labels = AppLocalizations.of(t.element(find.byType(Scaffold)))!;
      expect(find.text(labels.quizNoOptions), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      expect(t.takeException(), isNull);
    }
  });

  test('local grading follows exact left keys and case-sensitive right labels',
      () {
    final q = question(1);
    const expected = {'A': 'X', 'B': 'Y'};
    expect(
        renderer
            .validateAnswer({'A': ' X ', 'B': 'Y'}, jsonEncode(expected), q),
        isTrue);
    for (final actual in [
      {'a': 'x', 'b': 'y'},
      {'A': 'X'},
      {'A': 'X', 'B': 'X'},
      {'A': 1, 'B': 'Y'}
    ]) {
      expect(renderer.validateAnswer(actual, expected, q), isFalse);
    }
    expect(renderer.validateAnswer({}, 'unreadable', q), isFalse);
    expect(renderer.validateAnswer({}, {}, q), isFalse);
    expect(
        renderer.validateAnswer({'A': 'X', 'B': 'X'}, {'A': 'X', 'B': 'X'}, q),
        isFalse);
  });
}
