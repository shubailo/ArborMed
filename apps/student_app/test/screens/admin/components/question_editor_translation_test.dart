import 'dart:async';
import 'dart:convert';
import 'package:arbor_med/core/models/admin_question.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/question_editor_dialog.dart';
import 'package:arbor_med/screens/admin/components/question_preview_card.dart';
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
  Future<AppLocalizations> open(WidgetTester tester, {bool relation = false}) async {
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
                                    'type': relation ? 'relation_analysis' : 'single_choice',
                                    'correct_answer': relation ? 'C' : 'One',
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
