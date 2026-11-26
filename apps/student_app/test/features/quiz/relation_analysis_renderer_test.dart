import 'dart:convert';

import 'package:arbor_med/features/quiz/widgets/questions/relation_analysis_renderer.dart';
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
  final renderer = RelationAnalysisRenderer();
  late List<dynamic> sent;
  setUp(() {
    sent = [];
    SharedPreferences.setMockInitialValues({});
  });
  const prompt = {'text': 'Complete assertion and reason'};

  Future<void> show(WidgetTester t, Map<String, dynamic> q,
      {String lang = 'en',
      Object? current,
      Object? key,
      bool checked = false}) async {
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
              body: SingleChildScrollView(
                  child: Builder(
                      builder: (context) => Column(children: [
                            renderer.buildQuestion(context, q),
                            renderer.buildAnswerInput(
                                context, q, current, sent.add,
                                isChecked: checked, correctAnswer: key),
                          ])))),
        )));
    await t.pumpAndSettle();
  }

  testWidgets(
      'snake-case statements, scalar labels and blank translations render in the requested locale',
      (t) async {
    final q = {
      ...prompt,
      'content': {
        'statement_1': {'hu': 'Első állítás', 'en': 'First statement'},
        'statement_2': 'Second statement',
        'link_word': {'hu': '  '},
      },
    };
    await show(t, q, lang: 'hu');
    expect(find.text('Első állítás'), findsOneWidget);
    expect(find.text('Second statement'), findsOneWidget);
    expect(find.text('MERT'), findsOneWidget);
    await show(t, q);
    expect(find.text('First statement'), findsOneWidget);
    expect(find.text('BECAUSE'), findsOneWidget);
    await show(
        t,
        {
          'content': {
            'statement1': {'en': 'Nullable translation', 'hu': null},
            'statement2': {'en': null, 'hu': 'Második'}
          },
        },
        lang: 'hu');
    expect(find.text('Nullable translation'), findsOneWidget);
    expect(find.text('Második'), findsOneWidget);
  });

  testWidgets(
      'localized split content falls back per field and complete legacy prose stays visible',
      (t) async {
    await show(
        t,
        {
          ...prompt,
          'content': {
            'statement1': {'en': 'Fallback', 'hu': ' '},
            'statement2': {'en': 'Later', 'hu': 'Második'},
            'link_word': {'en': 'therefore', 'hu': 'ezért'},
          },
        },
        lang: 'hu');
    expect(find.text('Complete assertion and reason'), findsOneWidget);
    expect(find.text('Fallback'), findsOneWidget);
    expect(find.text('Második'), findsOneWidget);
    expect(find.text('EZÉRT'), findsOneWidget);
    await show(t, {
      ...prompt,
      'content': {
        'statement1': {'en': '', 'hu': ''},
        'statement2': {'en': '', 'hu': ''},
      }
    });
    expect(find.text('Complete assertion and reason'), findsOneWidget);
  });

  test(
      'local grading matches each canonical and historical stored code with option labels present',
      () {
    const q = {
      ...prompt,
      'options': [
        {'value': 'E', 'label': 'Neither statement is true'}
      ]
    };
    for (final code in ['A', 'B', 'C', 'D', 'E']) {
      for (final stored in [
        code.toLowerCase(),
        [code],
        jsonEncode([code]),
        jsonEncode(code)
      ]) {
        expect(renderer.validateAnswer(' ${code.toLowerCase()} ', stored, q),
            isTrue,
            reason: '$stored');
      }
      expect(renderer.formatAnswer(' ${code.toLowerCase()} '), code);
    }
    for (final bad in [
      null,
      [],
      ['A'],
      '["A"]',
      '"A"',
      {},
      'F',
      1
    ]) {
      expect(renderer.hasAnswer(bad), isFalse, reason: '$bad');
      expect(renderer.validateAnswer(bad, 'A', q), isFalse);
    }
    for (final bad in [
      null,
      [],
      ['A', 'B'],
      [
        ['A']
      ],
      {},
      'F',
      1
    ]) {
      expect(renderer.validateAnswer('A', bad, q), isFalse);
    }
  });

  testWidgets(
      'malformed cached content is explained without offering answer choices',
      (t) async {
    for (final content in [
      {
        'question_text': {'en': false}
      },
      ['not an object'],
      {
        'statement1': {'hu': 'Only one'},
        'statement2': {}
      },
      {
        'statement1': {'en': 42},
        'statement2': 'A phrase'
      },
    ]) {
      final q = {...prompt, 'content': content, 'correct_answer': 'C'};
      await show(t, q, lang: 'hu');
      final labels = AppLocalizations.of(t.element(find.byType(Scaffold)))!;
      expect(find.text(labels.quizIncompleteQuestion), findsOneWidget);
      expect(find.byKey(const ValueKey('relation-A')), findsNothing);
      expect(renderer.canSubmit(q, 'C'), isFalse);
    }
    expect(renderer.canSubmit({...prompt, 'correct_answer': 'unknown'}, 'A'),
        isFalse);
    expect(renderer.canSubmit({...prompt, 'correct_answer': 'A'}, 'B'), isTrue);
  });

  testWidgets(
      'each visible relation choice including E is directly selectable from an unanswered question',
      (t) async {
    await show(t, prompt);
    final ctx = t.element(find.byType(Scaffold));
    expect(renderer.hasAnswer(null), isFalse);
    for (final (i, code) in ['A', 'B', 'C', 'D', 'E'].indexed) {
      final choice = find.byKey(ValueKey('relation-$code'));
      await t.ensureVisible(choice);
      await t.tap(choice);
      expect(sent.last, code);
      expect(renderer.getAnswerForIndex(ctx, prompt, i, null), code);
    }
    expect(sent, ['A', 'B', 'C', 'D', 'E']);
    expect(renderer.getAnswerForIndex(ctx, prompt, 5, 'C'), 'C');
  });

  testWidgets(
      'locked review identifies the expected answer in the active language and ignores taps',
      (t) async {
    const q = {...prompt, 'correct_answer': 'A'};
    await show(t, q, lang: 'hu', current: 'E', key: '["C"]', checked: true);
    final l = AppLocalizations.of(t.element(find.byType(Scaffold)))!;
    expect(find.textContaining(l.correctAnswer), findsOneWidget);
    final choice = find.byKey(const ValueKey('relation-C'));
    await t.ensureVisible(choice);
    await t.tap(choice);
    expect(sent, isEmpty);
    await show(t, q, lang: 'hu', current: 'E', key: '["C"]');
    expect(find.textContaining(l.correctAnswer), findsNothing);
  });
}
