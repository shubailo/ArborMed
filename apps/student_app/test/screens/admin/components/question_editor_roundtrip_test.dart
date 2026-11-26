import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_editor_dialog.dart';
import 'package:arbor_med/screens/admin/components/quiz_forms/single_choice_editor.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/admin_question_provider_test.dart'
    show MockAuthProvider, MockApiService;

void main() {
  late MockAuthProvider auth;
  late Map<String, dynamic> saved;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = MockAuthProvider();
    saved = {};
    (auth.apiService as MockApiService).onPut = (endpoint, data) async {
      saved = data;
      return {};
    };
  });
  Future<void> open(WidgetTester tester, AdminQuestion? question) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1700, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AdminQuestionProvider(auth)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
              builder: (context) => Scaffold(
                      body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => QuestionEditorDialog(
                              question: question,
                              topics: const [
                                {
                                  'id': 1,
                                  'slug': 'pathology',
                                  'name_en': 'Subject',
                                  'parent_id': null
                                },
                                {
                                  'id': 2,
                                  'slug': 'section',
                                  'name_en': 'Section',
                                  'parent_id': 1
                                },
                                {
                                  'id': 3,
                                  'slug': 'nested',
                                  'name_en': 'Nested section',
                                  'parent_id': 2
                                },
                              ],
                              onSaved: () {},
                            )),
                    child: const Text('Open'),
                  ))),
        )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  AdminQuestion choice(dynamic options, dynamic answer) => AdminQuestion.fromJson({
    'id': 91,
    'topic_id': 2,
    'type': 'single_choice',
    'correct_answer': answer,
    'text': 'Choose a colour',
    'explanation': 'Rationale',
    'explanation_hu': 'Indoklás',
    'question_text_hu': 'Válassz színt',
    'options': options,
  });
  SingleChoiceEditor activeEditor(WidgetTester t) =>
      t.widget<SingleChoiceEditor>(find.byType(SingleChoiceEditor).first);
  Future<void> save(WidgetTester t) async {
    final labels = AppLocalizations.of(t.element(find.byType(QuestionEditorDialog)))!;
    await t.tap(find.text(labels.adminSaveQuestion));
    await t.pumpAndSettle();
  }
  final palette = {
    'en': ['Red', 'Blue', 'Green'],
    'hu': ['Piros', 'Kék', 'Zöld'],
  };
  testWidgets('removing an earlier choice keeps the same translated row selected in both tabs', (t) async {
    await open(t, choice(palette, 'Zöld'));
    expect(activeEditor(t).correctIndex, 2);
    await t.tap(find.byIcon(Icons.remove_circle_outline).first);
    await t.pumpAndSettle();
    expect(activeEditor(t).correctIndex, 1);
    final tabs = find.byType(Tab);
    await t.tap(tabs.last);
    await t.pumpAndSettle();
    expect(activeEditor(t).correctIndex, 1);
    final visibleFields = t.widgetList<TextFormField>(
      find.descendant(of: find.byType(SingleChoiceEditor).first, matching: find.byType(TextFormField)),
    );
    expect(visibleFields.map((field) => field.controller!.text), activeEditor(t).options);
    await save(t);
    expect(saved['options_en'], ['Blue', 'Green']);
    expect(saved['options_hu'], ['Kék', 'Zöld']);
    expect(saved['correct_answer'], 'Green');
  });
  testWidgets('deleting the selected choice requires an explicit replacement before saving', (t) async {
    await open(t, choice(palette, 'Green'));
    await t.tap(find.byIcon(Icons.remove_circle_outline).last);
    await t.pumpAndSettle();
    expect(activeEditor(t).correctIndex, isNull);
    await save(t);
    expect(saved, isEmpty);
    activeEditor(t).onCorrectIndexChanged(1);
    await t.pumpAndSettle();
    await save(t);
    expect(saved['correct_answer'], 'Blue');
  });
  testWidgets('an unrecognised answer cannot silently turn into the first choice', (t) async {
    await open(t, choice(palette, 'Lost key'));
    expect(activeEditor(t).correctIndex, isNull);
    await save(t);
    expect(saved, isEmpty);
  });
  testWidgets('editing a structured choice preserves the authored ID and its translation', (t) async {
    await open(t, choice([
      {'id':'red', 'en':'Red', 'hu':'Piros'},
      {'id':'blue', 'en':'Blue', 'hu':'Kék'},
    ], 'blue'));
    expect(activeEditor(t).correctIndex, 1);
    final input = activeEditor(t);
    final original = input.options;
    final isEn = original.first == 'Red';
    input.onOptionsChanged([original.first, isEn ? 'Sky blue' : 'Égszínkék']);
    await t.pumpAndSettle();
    await save(t);
    expect((saved['options_en'] as List)[1], containsPair('id', 'blue'));
    expect((saved['options_en'] as List)[1], containsPair('en', isEn ? 'Sky blue' : 'Blue'));
    expect((saved['options_hu'] as List)[1], isEn ? 'Kék' : 'Égszínkék');
    final reopened = choice({
      'en': saved['options_en'],
      'hu': saved['options_hu'],
    }, saved['correct_answer']);
    expect(reopened.choiceIndex(reopened.correctAnswer), 1);
  });

  testWidgets('cross-language label collisions keep the selected choice ID', (t) async {
    const redId = 'opt_ba19e9c3d5f49882ddaafed4f286a8a8';
    await open(t, choice({'en': ['Red', 'Other'], 'hu': ['Piros', 'Red']}, redId));
    await save(t);
    expect(saved['correct_answer'], redId);
  });
  testWidgets('a JSON-looking label is saved with its stable ID', (t) async {
    final question = choice(['[42]', '42'], '"[42]"');
    await open(t, question);
    await save(t);
    expect(saved['correct_answer'], question.choices.first.id);
  });
  testWidgets('an empty row cannot be persisted as an invisible option', (t) async {
    await open(t, choice(palette, 'Green'));
    activeEditor(t).onAdd();
    await t.pumpAndSettle();
    await save(t);
    expect(saved, isEmpty);
  });
  testWidgets('clearing an English label keeps the Hungarian choice editable', (t) async {
    await open(t, choice([
      {'id': 'red', 'en': 'Red', 'hu': 'Piros'},
      {'value': 'blue', 'label': 'Blue', 'hu': 'Kék'},
    ], 'blue'));
    await t.tap(find.byType(Tab).first);
    await t.pumpAndSettle();
    activeEditor(t).onOptionsChanged(['Red', '  ']);
    await t.pumpAndSettle();
    await save(t);
    final option = (saved['options_en'] as List)[1];
    expect(option, {'id': 'blue', 'hu': 'Kék'});
    final reopened = choice({'en': saved['options_en'], 'hu': saved['options_hu']}, saved['correct_answer']);
    expect(reopened.choices[1].en, isEmpty);
    expect(reopened.choiceIndex(reopened.correctAnswer), 1);
  });

  for (final topicId in [1, 3]) {
    testWidgets('saving preserves the existing root or nested topic $topicId',
        (tester) async {
      await open(
          tester,
          AdminQuestion.fromJson({
            'id': 40,
            'topic_id': topicId,
            'type': 'single_choice',
            'correct_answer': 'B',
            'options': {
              'en': ['A', 'B'],
              'hu': ['A', 'B']
            },
            'text': 'Statement?',
            'question_text_hu': 'Állítás?',
            'explanation': 'Explanation',
            'explanation_hu': 'Magyarázat',
          }));
      final l10n = AppLocalizations.of(
          tester.element(find.byType(QuestionEditorDialog)))!;
      await tester.tap(find.text(l10n.adminSaveQuestion));
      await tester.pumpAndSettle();
      expect(saved['topic_id'], topicId);
    });
  }

  for (final item in [
    ('multiple_choice', '["Second","Third"]', ['Second', 'Third']),
    ('true_false', 'false', 'false'),
    ('relation_analysis', 'C', 'C'),
  ]) {
    testWidgets('opening and saving a ${item.$1} question keeps its answer key',
        (tester) async {
      await open(
          tester,
          AdminQuestion.fromJson({
            'id': 12,
            'topic_id': 2,
            'type': item.$1,
            'correct_answer': item.$2,
            'text': 'Statement?',
            'question_text_hu': 'Állítás?',
            'explanation': 'Explanation',
            'explanation_hu': 'Magyarázat',
            'options': {
              'en': ['First', 'Second', 'Third'],
              'hu': ['Első', 'Második', 'Harmadik']
            },
            'content': {
              if (item.$1 == 'true_false')
                'statement': {'en': 'Statement?', 'hu': 'Állítás?'},
              if (item.$1 == 'relation_analysis') ...{
                'statement1': {'en': 'One', 'hu': 'Egy'},
                'statement2': {'en': 'Two', 'hu': 'Kettő'},
              }
            },
          }));
      final l10n = AppLocalizations.of(
          tester.element(find.byType(QuestionEditorDialog)))!;
      await tester.tap(find.text(l10n.adminSaveQuestion));
      await tester.pumpAndSettle();
      expect(saved['correct_answer'], item.$3);
      expect(saved['question_text_en'], 'Statement?');
    });
  }
  testWidgets('a new question can add and remove an option in both languages',
      (tester) async {
    await open(tester, null);
    SingleChoiceEditor editor() =>
        tester.widget(find.byType(SingleChoiceEditor).first);
    final initial = editor().options.length;
    editor().onAdd();
    await tester.pump();
    expect(editor().options.length, initial + 1);
    editor().onRemove(initial);
    await tester.pump();
    expect(editor().options.length, initial);
  });
}
