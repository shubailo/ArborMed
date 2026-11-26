import 'dart:async';
import 'dart:convert';
import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_editor_dialog.dart';
import 'package:arbor_med/screens/admin/components/question_preview_card.dart';
import 'package:arbor_med/screens/admin/components/question_metadata_section.dart';
import 'package:arbor_med/screens/admin/components/quiz_forms/matching_editor.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/admin_question_provider_test.dart'
    show MockAuthProvider;

void main() {
  late Completer<http.Response> reply;
  late List<http.Request> requests;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    ApiService().setHttpClient(MockClient((req) async {
      requests.add(req);
      return reply.future;
    }));
  });
  tearDown(() => ApiService().setHttpClient(http.Client()));
  Future<AppLocalizations> open(WidgetTester tester, {bool relation = false, bool matching = false}) async {
    reply = Completer<http.Response>();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1150);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(
              create: (_) => AdminQuestionProvider(MockAuthProvider())),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
                builder: (context) => Scaffold(
                        body: TextButton(
                      child: const Text('Open'),
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => QuestionEditorDialog(
                                  topics: const [
                                    {
                                      'id': 1,
                                      'slug': 'subject',
                                      'parent_id': null,
                                      'name_en': 'Subject'
                                    }
                                  ],
                                  question: AdminQuestion.fromJson({
                                    'id': 31,
                                    'topic_id': 1,
                                    'type': matching ? 'matching' : relation ? 'relation_analysis' : 'single_choice',
                                    'correct_answer': matching ? {'A':'B','C':'D'} : relation ? 'C' : 'One',
                                    if (matching) 'content': {
                                      'pairs': [
                                        {'left': {'en':'A','hu':'Alfa'}, 'right': {'en':'B','hu':'Béta'}},
                                        {'left': {'en':'C','hu':'Gamma'}, 'right': {'en':'D','hu':'Delta'}},
                                      ],
                                    },
                                    if (relation) 'content': {
                                      'statement1': {'en':'First assertion', 'hu':''},
                                      'statement2': {'en':'Second assertion', 'hu':''},
                                    },
                                    'text': 'Source text',
                                    'question_text_hu': 'Original target',
                                    'explanation': 'Source note',
                                    'explanation_hu': 'Target note',
                                    'options': {
                                      'en': ['One', ''],
                                      'hu': ['Egy', 'Keep empty-source target']
                                    }
                                  }),
                                  onSaved: () {})),
                    ))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final labels =
        AppLocalizations.of(tester.element(find.byType(QuestionEditorDialog)))!;
    await tester.tap(find.text(labels.adminHungarian));
    await tester.pumpAndSettle();
    return labels;
  }

  Map<String, dynamic> result(String target) => {
        'translatedQuestion': {
          'questionText': target,
          'options': ['Új', null],
          'explanation': 'Új magyarázat'
        }
      };
  void complete(Map<String, dynamic> data, [int status = 200]) {
    reply.complete(http.Response.bytes(utf8.encode(jsonEncode(data)), status,
        headers: {'content-type': 'application/json; charset=utf-8'}));
  }

  Finder field(String text) => find
      .byWidgetPredicate((w) => w is EditableText && w.controller.text == text);

  testWidgets(
      'failed autofill shows an error, retry applies real text and preserves blank-source slots',
      (tester) async {
    final labels = await open(tester);
    await tester.tap(find.text(labels.adminAutoFill));
    await tester.pump();
    expect(requests.single.url.path, '/api/translate/question');
    expect(jsonDecode(requests.single.body)['to'], 'hu');
    complete({'message': 'Translation unavailable'}, 502);
    await tester.pumpAndSettle();
    final error = find.descendant(
        of: find.byType(AlertDialog), matching: find.text(labels.translationFailed));
    expect(error, findsOneWidget);
    expect(find.ancestor(of: error, matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true)), findsWidgets);
    expect(field('Original target'), findsOneWidget);
    reply = Completer<http.Response>();
    await tester.tap(find.text(labels.adminAutoFill));
    await tester.pump();
    expect(error, findsNothing);
    complete(result('Lefordítva'));
    await tester.pumpAndSettle();
    expect(field('Lefordítva'), findsOneWidget);
    final preview = find.byType(QuestionPreviewCard);
    expect(find.descendant(of: preview, matching: find.text('Lefordítva')), findsOneWidget);
    expect(find.descendant(of: preview, matching: find.text('Source text')), findsNothing);
    await tester.tap(find.text(labels.adminEnglish));
    await tester.pumpAndSettle();
    expect(find.descendant(of: preview, matching: find.text('Source text')), findsOneWidget);
    await tester.tap(find.text(labels.adminHungarian));
    await tester.pumpAndSettle();
    expect(field('Keep empty-source target'), findsOneWidget);
    expect(field('null'), findsNothing);
  });
  testWidgets('a translated relation exposes its stem, statements, and linking word for review', (tester) async {
    final labels = await open(tester, relation:true);
    await tester.tap(find.text(labels.adminAutoFill));
    await tester.pump();
    final fields = jsonDecode(requests.single.body)['questionData'];
    expect(fields['questionText'],'Source text');
    expect(fields['statement1'],'First assertion');
    complete({'translatedQuestion': {'questionText':'Kérdés','statement1':'Első','statement2':'Második','link_word':'mivel','explanation':'Megjegyzés'}});
    await tester.pumpAndSettle();
    for (final text in ['Kérdés','Első','Második','mivel']) {
      expect(field(text),findsOneWidget);
    }
  });
  testWidgets(
      'typing over the target while autofill runs preserves the manual edit',
      (tester) async {
    final labels = await open(tester);
    await tester.tap(find.text(labels.adminAutoFill));
    await tester.pump();
    await tester.enterText(field('Original target'), 'Edited by author');
    complete(result('Stale'));
    await tester.pumpAndSettle();
    expect(field('Edited by author'), findsOneWidget);
    expect(field('Target note'), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog),
        matching: find.text(labels.adminTranslationDraftChanged)), findsOneWidget);
  });
  testWidgets('undoing a manual target edit while a field request runs keeps the authored value', (t) async {
    final l = await open(t);
    await t.tap(find.byTooltip('Translate from EN').first);
    await t.pump();
    await t.enterText(field('Original target'), 'My edit');
    await t.enterText(field('My edit'), 'Original target');
    complete({'translated': 'Stale'});
    await t.pumpAndSettle();
    expect(field('Original target'), findsOneWidget);
    expect(find.text(l.adminTranslationDraftChanged), findsOneWidget);
  });

  testWidgets('bulk translation discards a stale source and an option edit undone before completion', (t) async {
    final l = await open(t);
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    await t.tap(find.text(l.adminEnglish));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump();
    await t.enterText(field('Source text'), 'Revised source');
    complete(result('Stale'));
    await t.pumpAndSettle();
    expect(find.text(l.adminTranslationDraftChanged), findsOneWidget);
    await t.tap(find.text(l.adminHungarian));
    await t.pumpAndSettle();
    reply = Completer<http.Response>();
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    await t.enterText(field('Egy'), 'Draft');
    await t.enterText(field('Draft'), 'Egy');
    complete(result('Stale'));
    await t.pumpAndSettle();
    expect(field('Egy'), findsOneWidget);
    expect(field('Original target'), findsOneWidget);
  });

  testWidgets('a type round trip invalidates a field translation even when its text is identical', (t) async {
    final l = await open(t);
    await t.tap(find.byTooltip('Translate from EN').first);
    await t.pump();
    final metadata = t.widget<QuestionMetadataSection>(find.byType(QuestionMetadataSection));
    metadata.onQuestionTypeChanged('true_false');
    await t.pump();
    metadata.onQuestionTypeChanged('single_choice');
    await t.pump();
    complete({'translated': 'Stale'});
    await t.pumpAndSettle();
    expect(field('Original target'), findsOneWidget);
    expect(find.text(l.adminTranslationDraftChanged), findsOneWidget);
  });

  Map<String,dynamic> matchingResult() => {
    'translatedQuestion': {
      'questionText':'Fordított kérdés', 'explanation':'Magyarázat',
      'lefts':['Első','Második'], 'rights':['Partner 1','Partner 2'],
    }
  };

  testWidgets('matching translates the saved prompt along with both columns in their original order', (t) async {
    final l = await open(t, matching:true);
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    final fields = jsonDecode(requests.single.body)['questionData'];
    expect(fields['questionText'], 'Source text');
    expect(fields['lefts'], ['A','C']);
    complete(matchingResult());
    await t.pumpAndSettle();
    expect(field('Fordított kérdés'), findsOneWidget);
    final form = t.widget<MatchingEditor>(find.byType(MatchingEditor));
    expect(form.matchingGroups.map((g) => [g.leftHu.text,g.rightHu.text]), [
      ['Első','Partner 1'], ['Második','Partner 2'],
    ]);
  });

  testWidgets('a replaced pair with identical text cannot receive an earlier translation', (t) async {
    final l = await open(t, matching:true);
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    final form = t.widget<MatchingEditor>(find.byType(MatchingEditor));
    form.onRemovePair(form.matchingGroups.last);
    form.onAddPair();
    final row = form.matchingGroups.last;
    row.leftEn.text = 'C';
    row.rightEn.text = 'D';
    row.leftHu.text = 'Gamma';
    row.rightHu.text = 'Delta';
    complete(matchingResult());
    await t.pumpAndSettle();
    expect(row.leftHu.text,'Gamma');
    expect(row.rightHu.text,'Delta');
    expect(find.text(l.adminTranslationDraftChanged), findsOneWidget);
  });

  testWidgets('prefix-only provider output rejects the entire translation before touching the draft', (t) async {
    final l = await open(t);
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    complete(result('[HU]  '));
    await t.pumpAndSettle();
    expect(field('Original target'), findsOneWidget);
    expect(field('Target note'), findsOneWidget);
    expect(find.text(l.translationFailed), findsOneWidget);
  });

  testWidgets('a translation returned for a blank source cannot replace its manually filled target', (t) async {
    final l = await open(t);
    await t.tap(find.text(l.adminAutoFill));
    await t.pump();
    final data = result('Lefordítva');
    (data['translatedQuestion'] as Map)['options'] = ['Új','Unrequested text'];
    complete(data);
    await t.pumpAndSettle();
    expect(field('Keep empty-source target'), findsOneWidget);
    expect(field('Lefordítva'), findsOneWidget);
  });
  testWidgets(
      'closing the editor during a field translation never updates the disposed form',
      (tester) async {
    final labels = await open(tester);
    await tester.tap(find.byTooltip('Translate from EN').first);
    await tester.pump();
    expect(requests.single.url.path, '/api/translate');
    await tester.tap(find.text(labels.cancel));
    await tester.pumpAndSettle();
    complete({'translated': 'After close'});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
