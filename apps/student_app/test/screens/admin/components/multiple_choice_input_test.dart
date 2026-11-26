import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_editor_dialog.dart';
import 'package:arbor_med/screens/admin/components/quiz_forms/multiple_choice_editor.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/admin_question_provider_test.dart'
    show MockApiService, MockAuthProvider;

void main() {
  late Map<String, dynamic> saved;

  Future<void> open(WidgetTester t) async {
    SharedPreferences.setMockInitialValues({});
    final auth = MockAuthProvider();
    saved = {};
    (auth.apiService as MockApiService).onPut = (url, data) async {
      saved = data;
      return {};
    };
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1700, 1100);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final question = AdminQuestion.fromJson({
      'id': 91,
      'topic_id': 2,
      'type': 'multiple_choice',
      'text': 'Choose organs',
      'question_text_hu': 'Válassz szerveket',
      'explanation_en': 'Example',
      'explanation_hu': 'Példa',
      'options': {
        'en': [
          'First',
          {'id': 'b', 'en': 'Heart'},
          {'id': 'c', 'en': 'Heart'},
          'Fourth'
        ],
        'hu': ['Első', 'B', 'C', 'Negyedik']
      },
      'correct_answer': ['B', 'Fourth'],
    });
    await t.pumpWidget(MultiProvider(
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
                                    'name_en': 'Subject',
                                    'parent_id': null
                                  },
                                  {
                                    'id': 2,
                                    'name_en': 'Section',
                                    'parent_id': 1
                                  },
                                ],
                                onSaved: () {}),
                          ),
                      child: const Text('Open')),
                )),
      ),
    ));
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  Finder editor() => find.byType(MultipleChoiceEditor).first;
  Finder field(int i) =>
      find.descendant(of: editor(), matching: find.byType(TextField)).at(i);
  TextEditingController controller(WidgetTester t, int i) =>
      t.widget<TextField>(field(i)).controller!;
  MultipleChoiceEditor form(WidgetTester t) => t.widget(editor());
  Future<void> save(WidgetTester t) async {
    final l =
        AppLocalizations.of(t.element(find.byType(QuestionEditorDialog)))!;
    await t.tap(find.text(l.adminSaveQuestion));
    await t.pumpAndSettle();
  }

  testWidgets(
      'typing mid-word preserves the cursor and the active IME composition',
      (t) async {
    await open(t);
    await t.showKeyboard(field(1));
    final before = controller(t, 1);
    const input = TextEditingValue(
        text: 'Heár ct',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 2, end: 4));
    t.testTextInput.updateEditingValue(input);
    await t.pump();
    expect(controller(t, 1).value, input);
    expect(controller(t, 1), same(before));
    expect(form(t).options[1], input.text);
  });

  testWidgets(
      'selection follows the surviving duplicate-label row and its own language tab',
      (t) async {
    await open(t);
    final en = controller(t, 2);
    const range = TextSelection(baseOffset: 4, extentOffset: 1);
    en.selection = range;
    form(t).onRemoveOption(0);
    await t.pumpAndSettle();
    expect(controller(t, 1), same(en));
    expect(controller(t, 1).selection, range);
    expect(form(t).correctIndices, orderedEquals([0, 2]));
    await t.tap(find.byType(Tab).last);
    await t.pumpAndSettle();
    expect(controller(t, 1).text, 'C');
    expect(controller(t, 1), isNot(same(en)));
    await t.tap(find.byType(Tab).first);
    await t.pumpAndSettle();
    expect(controller(t, 1), same(en));
    expect(controller(t, 1).selection, range);
  });

  testWidgets(
      'external replacement clamps selection and clears only stale composing text',
      (t) async {
    await open(t);
    final before = controller(t, 1);
    before.value = const TextEditingValue(
        text: 'Heart',
        selection: TextSelection(baseOffset: 4, extentOffset: 1),
        composing: TextRange(start: 1, end: 4));
    form(t).onOptionChanged(1, 'Ab');
    await t.pump();
    expect(controller(t, 1).text, 'Ab');
    expect(controller(t, 1).selection,
        const TextSelection(baseOffset: 2, extentOffset: 1));
    expect(controller(t, 1).value.composing, TextRange.empty);
    expect(controller(t, 1), same(before));
  });

  testWidgets(
      'a repeated checkbox event adds a correct answer once, including in the saved payload',
      (t) async {
    await open(t);
    final toggle = form(t).onToggleCorrect;
    toggle(0, true);
    toggle(0, true);
    await t.pump();
    expect(form(t).correctIndices, orderedEquals([1, 3, 0]));
    await save(t);
    final keys = saved['correct_answer'] as List;
    expect(keys.length, 3);
    expect(keys.toSet().length, 3);
  });

  testWidgets(
      'removed option callbacks cannot edit or delete the following question row',
      (t) async {
    await open(t);
    final old = form(t);
    final dropped = controller(t, 0);
    old.onRemoveOption(0);
    old.onRemoveOption(0);
    old.onOptionChanged(0, 'Stale');
    old.onToggleCorrect(0, false);
    await t.pumpAndSettle();
    expect(form(t).options, ['Heart', 'Heart', 'Fourth']);
    expect(form(t).correctIndices, orderedEquals([0, 2]));
    expect(() => dropped.addListener(() {}), throwsFlutterError);
  });
}
