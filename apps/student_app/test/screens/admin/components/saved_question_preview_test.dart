import 'dart:async';
import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_preview_pane.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AdminQuestion record(Map<String, dynamic> fields) =>
      AdminQuestion.fromJson({'id': 1, 'topic_id': 2, ...fields});

  Future<void> show(WidgetTester tester, AdminQuestion question,
      {Future<Map<String, dynamic>?>? analytics}) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(
        locale: const Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: QuestionPreviewPane(
                question: question,
                analyticsFuture: analytics,
                onClose: () {},
                onEditQuestion: (_) {})),
      ),
    ));
    await tester.pump();
  }

  testWidgets(
      'shows the saved options, answer and explanation in either language',
      (t) async {
    await show(
        t,
        record({
          'text': 'Pick one',
          'question_text_hu': 'Válassz',
          'options': [
            {'id': 'aa', 'en': 'Heart', 'hu': 'Szív'},
            {'id': 'bb', 'en': 'Lung', 'hu': 'Tüdő'}
          ],
          'correct_answer': 'bb',
          'explanation_en': 'Breathing',
          'explanation_hu': 'Légzés',
        }));
    for (final label in ['Válassz', '• Szív', '• Tüdő', 'Tüdő', 'Légzés']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('Magas hibaarány'), findsNothing);
    await t.tap(find.widgetWithText(ChoiceChip, 'Angol'));
    await t.pumpAndSettle();
    for (final label in [
      'Pick one',
      '• Heart',
      '• Lung',
      'Lung',
      'Breathing'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Tüdő'), findsNothing);
  });

  testWidgets(
      'renders all multiple answers and identifies an unresolved stored key',
      (t) async {
    await show(
        t,
        record({
          'type': 'multiple_choice',
          'options': {
            'hu': ['Egy', 'Kettő', 'Három']
          },
          'correct_answer': '["Három","Egy","ismeretlen"]',
        }));
    expect(find.text('Három'), findsOneWidget);
    expect(find.text('Egy'), findsOneWidget);
    expect(find.text('Kettő'), findsNothing);
    expect(find.text('A helyes válasz nem azonosítható (ismeretlen)'),
        findsOneWidget);
  });

  testWidgets('the same English term can have different translations on each matching side', (t) async {
    await show(t, record({
      'type':'matching','correct_answer':{'A':'B','B':'C'},
      'options':{'en':['A: B','B: C'],'hu':['Alfa: Béta','Bal: Cél']},
    }));
    expect(find.text('Alfa → Béta'),findsOneWidget);
    expect(find.text('Bal → Cél'),findsOneWidget);
  });

  testWidgets('saved logic previews resolve historical statements and mark ambiguous scalar keys', (t) async {
    final l = lookupAppLocalizations(const Locale('hu'));
    await show(t, record({'type':'relational_analysis', 'content':{
      'statement_1':'First', 'statement_2':{'hu':'Második'}
    }, 'correct_answer':'[" d "]'}));
    for (final text in ['First','Második','D']) {
      expect(find.text(text), findsOneWidget);
    }
    for (final type in ['true_false','relation_analysis']) {
      await show(t, record({'type':type,'correct_answer':
        type == 'true_false' ? [true,false] : ['A','E']}));
      expect(find.text(l.adminAnswerKeyUnresolved), findsOneWidget);
    }
  });

  testWidgets('renders translated legacy pairs and boolean answers', (t) async {
    await show(
        t,
        record({
          'type': 'matching',
          'options': {
            'en': ['Heart: red', 'Lung -> blue'],
            'hu': ['Szív: vörös', 'Tüdő → kék']
          },
          'correct_answer': '{"Heart":"red","Lung":"blue"}',
        }));
    expect(find.text('Szív → vörös'), findsOneWidget);
    expect(find.text('Tüdő → kék'), findsOneWidget);
    await show(
        t,
        record({
          'id': 2,
          'type': 'true_false',
          'correct_answer': false,
          'content': {
            'statement': {'en': 'Claim', 'hu': 'Állítás'}
          }
        }));
    expect(find.text('Állítás'), findsOneWidget);
    expect(find.text('HAMIS'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Angol'));
    await t.pumpAndSettle();
    expect(find.text('FALSE'), findsOneWidget);
  });

  testWidgets(
      'structured matching and relation details retain the saved language and diagnostics',
      (t) async {
    await show(
        t,
        record({
          'type': 'matching',
          'content': {
            'pairs': [
              {
                'left': {'en': 'A', 'hu': 'Bal'},
                'right': {'en': 'B', 'hu': 'Jobb'}
              }
            ]
          },
          'correct_answer': {'A': 'B'},
          'report_count': 2,
          'attempts': 3,
          'success_rate': 0
        }));
    expect(find.text('Bal → Jobb'), findsOneWidget);
    expect(find.textContaining('Magas hibaarány'), findsOneWidget);
    expect(find.textContaining('(2)'), findsOneWidget);
    await show(
        t,
        record({
          'id': 2,
          'type': 'relation_analysis',
          'content': {
            'statement1': {'hu': 'Első'},
            'link_word': {'hu': 'mert'},
            'statement2': {'en': 'Second'}
          },
          'correct_answer': 'C'
        }));
    for (final part in ['Első', 'mert', 'Second', 'C']) {
      expect(find.text(part), findsOneWidget);
    }
  });

  testWidgets(
      'clears previous analytics during refresh and reports fetch failure',
      (t) async {
    final first = Completer<Map<String, dynamic>?>();
    final second = Completer<Map<String, dynamic>?>();
    await show(t, record({}), analytics: first.future);
    first.complete({
      'wrongAnswers': [
        null,
        {'answer': 'old answer', 'count': 2}
      ]
    });
    await t.pumpAndSettle();
    expect(find.text('old answer'), findsOneWidget);
    await show(t, record({'id': 2}), analytics: second.future);
    expect(find.text('old answer'), findsNothing);
    second.completeError(StateError('sample'));
    await t.pumpAndSettle();
    expect(find.text('Nincs elérhető analitika'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
