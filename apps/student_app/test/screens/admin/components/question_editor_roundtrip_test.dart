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
