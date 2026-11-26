import 'package:arbor_med/screens/admin/components/quiz_forms/relation_analysis_editor.dart';
import 'package:arbor_med/screens/admin/components/quiz_forms/true_false_editor.dart';
import 'package:arbor_med/widgets/admin/dual_language_field.dart';
import 'package:arbor_med/screens/admin/components/question_metadata_section.dart';
import 'package:arbor_med/screens/admin/components/question_preview_card.dart';
import 'package:arbor_med/screens/admin/components/quiz_forms/matching_editor.dart';
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

  AdminQuestion matching({Object? pairs, Object? answer, Object? options}) =>
      AdminQuestion.fromJson({
        'id': 51, 'topic_id': 2, 'type': 'matching',
        'content': {if (pairs != null) 'pairs':pairs}, 'options':options,
        'correct_answer': answer, 'text':'Match the pairs',
        'explanation':'Reason', 'explanation_hu':'Indok',
      });
  MatchingEditor matchingForm(WidgetTester t) =>
      t.widget<MatchingEditor>(find.byType(MatchingEditor).first);
  Map<String, dynamic> pair(String l, String r, {String lh = '', String rh = ''}) =>
      {'left':{'en':l,'hu':lh}, 'right':{'en':r,'hu':rh}};

  testWidgets('legacy matching keys reopen with side-specific translations and survive saving', (t) async {
    await open(t, matching(answer:'{"Pulse":"Rate","Rate":"Time"}', options:{
      'en':['Rate: Time','Pulse -> Rate'], 'hu':['Ütem: Idő','Pulzus → Frekvencia']
    }));
    final groups=matchingForm(t).matchingGroups;
    expect(groups.map((p)=>[p.leftEn.text,p.leftHu.text,p.rightEn.text,p.rightHu.text]),
      [['Pulse','Pulzus','Rate','Frekvencia'],['Rate','Ütem','Time','Idő']]);
    await save(t);
    expect(saved['correct_answer'], {'Pulse':'Rate','Rate':'Time'});
    expect(saved['content']['pairs'], [
      pair('Pulse','Rate',lh:'Pulzus',rh:'Frekvencia'),pair('Rate','Time',lh:'Ütem',rh:'Idő')
    ]);
  });

  testWidgets('matching lines with no stored key open for editing and keep unknown translations blank', (t) async {
    await open(t, matching(options:{'en':['A: X','B → Y'], 'hu':['Eltolt: Fordítás']}));
    final groups=matchingForm(t).matchingGroups;
    expect(groups.map((g)=>g.leftHu.text), ['', '']);
    await save(t);
    expect(saved['correct_answer'], {'A':'X','B':'Y'});
  });

  testWidgets('saving preserves original lengths of unaligned historical matching translations', (t) async {
    final options={'en':['A: X','B: Y','Unused'], 'hu':['Alfa: Első','Béta: Második']};
    await open(t, matching(options:options, answer:{'A':'X','B':'Y'}));
    await save(t);
    expect(saved['options_en'],options['en']);
    expect(saved['options_hu'],options['hu']);
  });

  testWidgets('conversion to matching does not store the original multiple-choice distractors', (t) async {
    await open(t, choice(palette, 'Green'));
    t.widget<QuestionMetadataSection>(find.byType(QuestionMetadataSection)).onQuestionTypeChanged('matching');
    await t.pumpAndSettle();
    final form=matchingForm(t);
    if(form.matchingGroups.length == 1) {
      form.onAddPair();
      await t.pumpAndSettle();
    }
    final rows=matchingForm(t).matchingGroups;
    rows.first.leftEn.text='A';
    rows.first.rightEn.text='X';
    rows.last.leftEn.text='B';
    rows.last.rightEn.text='Y';
    await save(t);
    expect(saved['correct_answer'],{'A':'X','B':'Y'});
    expect(saved['options_en'],isEmpty);
    expect(saved['options_hu'],isEmpty);
  });

  testWidgets('a malformed matching row is editable and blocks the write until repaired', (t) async {
    await open(t, matching(pairs:[null,pair('B','Y')]));
    expect(t.takeException(), isNull);
    final groups=matchingForm(t).matchingGroups;
    expect(groups.first.leftEn.text,'');
    await save(t);
    expect(saved,isEmpty);
    groups.first.leftEn.text='A';
    groups.first.rightEn.text='X';
    await save(t);
    expect(saved['correct_answer'],{'A':'X','B':'Y'});
  });

  testWidgets('repeated deletion removes only the intended pair and releases all four controllers', (t) async {
    await open(t, matching(pairs:[pair('A','X'),pair('B','Y'),pair('C','Z')]));
    final groups=matchingForm(t).matchingGroups;
    final removed=groups.first;
    final field=find.descendant(of:find.byType(MatchingEditor).first,matching:find.byType(TextField)).at(2);
    final element=t.element(field);
    final delete=find.descendant(of:find.byType(MatchingEditor).first,matching:find.byIcon(Icons.close)).first;
    final remove=t.widget<IconButton>(find.ancestor(of:delete,matching:find.byType(IconButton)).first).onPressed!;
    remove();
    remove();
    await t.pumpAndSettle();
    expect(matchingForm(t).matchingGroups.map((g)=>g.leftEn.text),['B','C']);
    expect(t.element(find.descendant(of:find.byType(MatchingEditor).first,matching:find.byType(TextField)).first),same(element));
    for(final ctrl in [removed.leftEn,removed.leftHu,removed.rightEn,removed.rightHu]) {
      expect(()=>ctrl.addListener((){}), throwsFlutterError);
    }
    await save(t);
    expect(saved['correct_answer'], {'B':'Y','C':'Z'});
  });

  testWidgets('matching drafts reject incomplete pairs and duplicate labels in either displayed language', (t) async {
    await open(t, matching(pairs:[pair('A','X',lh:'B'),pair('B','Y')]));
    final groups=matchingForm(t).matchingGroups;
    await save(t);
    expect(saved,isEmpty);
    groups.first.leftHu.text='Első';
    groups.last.rightEn.text=' x ';
    await save(t);
    expect(saved,isEmpty);
    groups.last.rightEn.text='';
    await save(t);
    expect(saved,isEmpty);
    groups.last.rightEn.text='Y';
    await save(t);
    expect(saved['correct_answer'], {'A':'X','B':'Y'});
  });

  testWidgets('matching edits preserve structured pair and term metadata', (t) async {
    final first=pair('A','X',lh:'Alfa')..['reference']='annotation';
    first['left']['source']='glossary';
    await open(t, matching(pairs:[first,pair('B','Y')]));
    final groups=matchingForm(t).matchingGroups;
    groups.first.leftHu.text='Átírva';
    await save(t);
    expect(saved['content']['pairs'][0], {
      'reference':'annotation','left':{'en':'A','hu':'Átírva','source':'glossary'},
      'right':{'en':'X','hu':''}
    });
  });

  testWidgets('repairing a contradictory stored matching key requires explicitly choosing the displayed pairs', (t) async {
    await open(t, matching(pairs:[pair('A','X'),pair('B','Y')], answer:{'A':'Y','B':'X'}));
    await save(t);
    expect(saved,isEmpty);
    final warning = find.descendant(of: find.byType(MatchingEditor).first, matching: find.byType(CheckboxListTile));
    final consent=t.widget<CheckboxListTile>(warning);
    expect(consent.value,isFalse);
    expect((consent.subtitle as Text).data,contains('"A":"Y"'));
    consent.onChanged!(true);
    await t.pumpAndSettle();
    final edited=find.descendant(of:find.byType(MatchingEditor).first,matching:find.byType(TextField)).first;
    await t.enterText(edited,'Updated');
    await t.pumpAndSettle();
    expect(t.widget<CheckboxListTile>(warning).value,isFalse);
    await t.enterText(edited,matchingForm(t).isEn ? 'A' : '');
    await t.pumpAndSettle();
    t.widget<CheckboxListTile>(warning).onChanged!(true);
    await t.pumpAndSettle();
    await save(t);
    expect(saved['correct_answer'],{'A':'X','B':'Y'});
  });

  testWidgets('switching to matching wires the initial rows to the preview and releases retained drafts on close', (t) async {
    await open(t, choice(palette, 'Green'));
    void change(String type) => t.widget<QuestionMetadataSection>(find.byType(QuestionMetadataSection)).onQuestionTypeChanged(type);
    change('matching');
    await t.pumpAndSettle();
    final form=matchingForm(t);
    expect(form.matchingGroups.length,2);
    final first=form.matchingGroups.first;
    final input=find.descendant(of:find.byType(MatchingEditor).first, matching:find.byType(TextField)).first;
    await t.enterText(input,'New term');
    await t.pump();
    final preview=t.widget<QuestionPreviewCard>(find.byType(QuestionPreviewCard)).question!;
    expect(preview.content['pairs'][0]['left'][form.isEn ? 'en' : 'hu'],'New term');
    change('true_false');
    await t.pumpAndSettle();
    change('matching');
    await t.pumpAndSettle();
    expect(matchingForm(t).matchingGroups.first,same(first));
    final labels=AppLocalizations.of(t.element(find.byType(QuestionEditorDialog)))!;
    await t.tap(find.text(labels.cancel));
    await t.pumpAndSettle();
    for(final ctrl in [first.leftEn,first.leftHu,first.rightEn,first.rightHu]) {
      expect(()=>ctrl.addListener((){}), throwsFlutterError);
    }
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
  AdminQuestion logic(String type, Object? key, {
    Map<String, dynamic> content = const {}, String prompt = 'Question',
    String hu = 'Kérdés',
  }) => AdminQuestion.fromJson({
    'id': 19, 'topic_id': 2, 'type': type, 'correct_answer': key,
    'question_text_en': prompt, 'question_text_hu': hu, 'content': content,
  });

  Finder inEditor(Type form, Type control) =>
      find.descendant(of: find.byType(form).first, matching: find.byType(control));
  Future<void> showHungarian(WidgetTester t) async {
    await t.tap(find.byType(Tab).last);
    await t.pumpAndSettle();
  }

  testWidgets('a historical relation singleton and full prompt survive a language switch and save', (t) async {
    await open(t, logic('relation_analysis', '["E"]', content: {'origin':'import'}));
    final editor = find.byType(RelationAnalysisEditor).first;
    expect(t.widget<RelationAnalysisEditor>(editor).correctIndex, 4);
    await showHungarian(t);
    expect(t.widget<RelationAnalysisEditor>(editor).correctIndex, 4);
    await save(t);
    expect(saved['correct_answer'], 'E');
    expect(saved['content'], containsPair('origin', 'import'));
    expect(saved['content'], isNot(contains('statement1')));
    expect(saved['question_text_en'], 'Question');
  });
  testWidgets('an unknown relation key stays unselected until the admin explicitly chooses E', (t) async {
    await open(t, logic('relation_analysis', ['D','E']));
    final choices = inEditor(RelationAnalysisEditor, ChoiceChip);
    expect(t.widget<RelationAnalysisEditor>(find.byType(RelationAnalysisEditor).first).correctIndex, isNull);
    expect(t.widgetList<ChoiceChip>(choices).where((chip) => chip.selected), isEmpty);
    await save(t);
    expect(saved, isEmpty);
    await t.ensureVisible(choices.at(4));
    await t.tap(choices.at(4));
    await t.pumpAndSettle();
    await save(t);
    expect(saved['correct_answer'], 'E');
  });
  testWidgets('snake-case and scalar statements reopen without a separate prompt and retain annotations', (t) async {
    await open(t, logic('relation_analysis', ['D'], prompt:'', hu:'', content:{
      'statement_1': 'First', 'statement_2': {'hu':'Második', 'source':'manual'},
      'link_word': 'as', 'reference':'ref',
    }));
    final fields = t.widgetList<DualLanguageField>(find.byType(DualLanguageField));
    expect(fields.any((field) => field.controllerEn.text == 'First'), isTrue);
    expect(fields.any((field) => field.controllerHu.text == 'Második'), isTrue);
    await save(t);
    expect(saved['correct_answer'], 'D');
    expect(saved['content']['statement1']['en'], 'First');
    expect(saved['content']['statement2'], {'en':'', 'hu':'Második', 'source':'manual'});
    expect(saved['content']['link_word']['en'], 'as');
    expect(saved['content']['reference'], 'ref');
    expect(saved['content'], isNot(contains('statement_1')));
  });
  testWidgets('one incomplete relation statement cannot be saved behind a complete prompt', (t) async {
    await open(t, logic('relation_analysis', 'B', content:{'statement1':{'en':'First'}}));
    await save(t);
    expect(saved, isEmpty);
    final labels = AppLocalizations.of(t.element(find.byType(QuestionEditorDialog)))!;
    final second = t.widgetList<DualLanguageField>(find.byType(DualLanguageField))
        .firstWhere((field) => field.label == labels.adminSecondStatement);
    second.controllerEn.text = 'Second';
    await t.pump();
    await save(t);
    expect(saved['content']['statement2']['en'], 'Second');
  });
  testWidgets('a stored false singleton with a scalar statement keeps the false key when edited', (t) async {
    await open(t, logic('true_false', '[false]', content:{'statement':'Plain statement'}));
    final editor = find.byType(TrueFalseEditor).first;
    expect(t.widget<TrueFalseEditor>(editor).correctIndex, 1);
    await showHungarian(t);
    expect(t.widget<TrueFalseEditor>(editor).correctIndex, 1);
    await save(t);
    expect(saved['correct_answer'], 'false');
    expect(saved['content']['statement']['en'], 'Plain statement');
  });
  for (final key in [null, 'unknown']) {
    testWidgets('unresolved true-false key $key requires an explicit choice in either tab', (t) async {
      await open(t, logic('true_false', key, content:{
        'statement': {'en':'Stored', 'hu':'Tárolt','source':'old'},
      }));
      final choices = inEditor(TrueFalseEditor, ChoiceChip);
      expect(t.widgetList<ChoiceChip>(choices).where((chip) => chip.selected), isEmpty);
      await save(t);
      expect(saved, isEmpty);
      await showHungarian(t);
      await t.ensureVisible(choices.last);
      await t.tap(choices.last);
      await t.pumpAndSettle();
      await save(t);
      expect(saved['correct_answer'], 'false');
      expect(saved['content']['statement']['source'], 'old');
    });
  }
  testWidgets('switching away and back restores each explicitly selected logic key', (t) async {
    await open(t, logic('relation_analysis', 'C'));
    Future<void> change(String type) async {
      t.widget<QuestionMetadataSection>(find.byType(QuestionMetadataSection)).onQuestionTypeChanged(type);
      await t.pumpAndSettle();
    }
    await change('true_false');
    final tf = find.byType(TrueFalseEditor).first;
    expect(t.widget<TrueFalseEditor>(tf).correctIndex, isNull);
    t.widget<TrueFalseEditor>(tf).onIndexChanged(1);
    await t.pump();
    await change('relation_analysis');
    expect(t.widget<RelationAnalysisEditor>(find.byType(RelationAnalysisEditor).first).correctIndex, 2);
    await change('true_false');
    expect(t.widget<TrueFalseEditor>(tf).correctIndex, 1);
  });

  testWidgets('the registered historical relation type opens the relation editor and saves a canonical type', (t) async {
    await open(t, logic('relational_analysis', 'B'));
    expect(find.byType(RelationAnalysisEditor), findsWidgets);
    await save(t);
    expect(saved['question_type'], 'relation_analysis');
    expect(saved['correct_answer'], 'B');
  });
  testWidgets('corrupt split data cannot silently disappear into the full prompt', (t) async {
    await open(t, logic('relation_analysis', 'D', content:{
      'statement_1': ['damaged'], 'statement_2': 7,
      'question_text': {'en':'outdated','hu':'régi','source':'import'},
    }));
    await save(t);
    expect(saved, isEmpty);
    final labels = AppLocalizations.of(t.element(find.byType(QuestionEditorDialog)))!;
    final fields = t.widgetList<DualLanguageField>(find.byType(DualLanguageField));
    fields.firstWhere((f) => f.label == labels.adminFirstStatement).controllerEn.text = 'Fixed first';
    fields.firstWhere((f) => f.label == labels.adminSecondStatement).controllerEn.text = 'Fixed second';
    await t.pump();
    await save(t);
    expect(saved['content']['statement1']['en'], 'Fixed first');
    expect(saved['content']['question_text'], {'en':'Question','hu':'Kérdés','source':'import'});
  });
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
