import 'dart:async';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/bulk_action_toolbar.dart';
import 'package:arbor_med/screens/admin/components/question_preview_pane.dart';
import 'package:arbor_med/screens/admin/components/questions_data_table.dart';
import 'package:arbor_med/screens/admin/questions_screen.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/admin_question_provider_test.dart'
    show MockApiService, MockAuthProvider;

void main() {
  late MockAuthProvider auth;
  late MockApiService api;
  late AdminQuestionProvider provider;
  late List<int> ids;
  late List<Uri> reads;
  late int total;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    provider = AdminQuestionProvider(auth);
    ids = [10, 20];
    reads = [];
    total = 2;
    api.onGet = (endpoint) async {
      final uri = Uri.parse(endpoint);
      if (uri.path != ApiEndpoints.quizAdminQuestions) {
        return uri.path.endsWith('/analytics') ? <String, dynamic>{} : [];
      }
      reads.add(uri);
      final page = int.parse(uri.queryParameters['page'] ?? '1');
      return {
        'total': total,
        'questions': [
          if (page == 1 || total > (page - 1) * 200)
            for (final id in ids)
              {
                'id': id,
                'topic_id': 1,
                'text': 'Question $id',
                'question_text_hu': 'Kérdés $id',
                'topic_name': 'Medicine',
                'topic_name_hu': 'Orvostan',
                'type': 'single_choice',
                'options': ['A', 'B'],
                'correct_answer': 'A',
                'attempts': id == 10 ? 0 : 1,
                'success_rate': 0,
              },
        ],
      };
    };
  });

  Future<void> open(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => TopicProvider(auth)),
        ChangeNotifierProvider(create: (_) => AdminUserProvider(auth)),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MaterialApp(
        locale: Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminQuestionsScreen(),
      ),
    ));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'filter');
    await t.pump(const Duration(milliseconds: 550));
    await t.pumpAndSettle();
  }

  QuestionsDataTable table(WidgetTester t) =>
      t.widget<QuestionsDataTable>(find.byType(QuestionsDataTable));
  Finder row(int id) => find.byKey(ValueKey<int>(id));
  Finder inside(int id, Finder matching) =>
      find.descendant(of: row(id), matching: matching);

  testWidgets(
      'HU row labels and accuracy distinguish missing attempts from zero success',
      (t) async {
    await open(t);
    expect(inside(10, find.text('Kérdés 10')), findsOneWidget);
    expect(inside(10, find.text('Orvostan')), findsOneWidget);
    expect(inside(10, find.text('—')), findsOneWidget);
    expect(inside(20, find.text('0.0%')), findsOneWidget);
    final l = AppLocalizations.of(t.element(find.byType(QuestionsDataTable)))!;
    expect(inside(10, find.byTooltip(l.edit)), findsOneWidget);
    expect(inside(20, find.byTooltip(l.delete)), findsOneWidget);
  });

  testWidgets(
      'partially selected rows keep their elements and IDs after reordering',
      (t) async {
    await open(t);
    final selectedRow = t.element(row(20));
    await t.tap(inside(20, find.byType(Checkbox)));
    await t.pumpAndSettle();
    expect(t.widget<Checkbox>(find.byType(Checkbox).first).value, isNull);
    ids = [20, 10];
    await provider.fetchAdminQuestions(search: 'filter');
    await t.pumpAndSettle();
    expect(t.element(row(20)), same(selectedRow));
    expect(t.widget<Checkbox>(inside(20, find.byType(Checkbox))).value, isTrue);
    expect(
        t.widget<Checkbox>(inside(10, find.byType(Checkbox))).value, isFalse);
    await t.tap(find.byType(Checkbox).first);
    await t.pumpAndSettle();
    expect(table(t).selectedIds, {10, 20});
    await t.tap(find.byType(Checkbox).first);
    await t.pumpAndSettle();
    expect(table(t).selectedIds, isEmpty);
  });

  testWidgets(
      'a background refresh removes orphaned actions, preview and selection',
      (t) async {
    await open(t);
    final old = table(t);
    final removed = old.questions.first;
    old.onSelectionChanged({removed.id});
    old.onPreviewSelected(removed);
    await t.pumpAndSettle();
    expect(find.byType(QuestionPreviewPane), findsOneWidget);
    expect(find.byType(BulkActionToolbar), findsOneWidget);
    ids = [20];
    total = 1;
    await provider.fetchAdminQuestions(search: 'filter');
    await t.pumpAndSettle();
    expect(find.byType(QuestionPreviewPane), findsNothing);
    expect(find.byType(BulkActionToolbar), findsNothing);
    final before = reads.length;
    old.onSelectionChanged({10});
    old.onPreviewSelected(removed);
    old.onEditQuestion(removed);
    old.onDeleteQuestion(removed);
    old.onSort('attempts', true);
    await t.pumpAndSettle();
    expect(table(t).selectedIds, isEmpty);
    expect(find.byType(QuestionPreviewPane), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(reads.length, before);
  });

  testWidgets('server sorting keeps only the selected IDs on the returned page',
      (t) async {
    await open(t);
    table(t).onSelectionChanged({10, 20});
    table(t).onPreviewSelected(table(t).questions.last);
    await t.pumpAndSettle();
    ids = [30, 20];
    table(t).onSort('attempts', true);
    await t.pumpAndSettle();
    expect(reads.last.queryParameters['sortBy'], 'attempts');
    expect(table(t).selectedIds, {20});
    expect(
        t
            .widget<QuestionPreviewPane>(find.byType(QuestionPreviewPane))
            .question
            .id,
        20);
    ids = [30];
    table(t).onSort('attempts', false);
    await t.pumpAndSettle();
    expect(table(t).selectedIds, isEmpty);
    expect(find.byType(QuestionPreviewPane), findsNothing);
  });

  testWidgets('background deletion of the last page loads its predecessor once',
      (t) async {
    total = 201;
    await open(t);
    await t.tap(find.byIcon(Icons.chevron_right));
    await t.pumpAndSettle();
    expect(reads.last.queryParameters['page'], '2');
    total = 1;
    ids = [10];
    final before = reads.length;
    await provider.fetchAdminQuestions(page: 2, search: 'filter');
    await t.pumpAndSettle();
    expect(reads.skip(before).map((uri) => uri.queryParameters['page']),
        ['2', '1']);
    expect(table(t).questions.single.id, 10);
  });

  testWidgets('double activation of row delete submits once and refreshes once',
      (t) async {
    final deletes = <String>[];
    final pending = Completer<dynamic>();
    api.onDelete = (endpoint) {
      deletes.add(endpoint);
      return pending.future;
    };
    await open(t);
    final rowTable = table(t);
    final before = reads.length;
    rowTable.onDeleteQuestion(rowTable.questions.first);
    rowTable.onDeleteQuestion(rowTable.questions.first);
    await t.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final labels = AppLocalizations.of(t.element(dialog))!;
    final confirm = t
        .widget<TextButton>(find.widgetWithText(TextButton, labels.delete))
        .onPressed!;
    confirm();
    confirm();
    await t.pumpAndSettle();
    expect(deletes, ['${ApiEndpoints.quizAdminQuestions}/10']);
    ids = [20];
    total = 1;
    pending.complete({});
    await t.pumpAndSettle();
    expect(reads.length - before, 1);
    expect(table(t).questions.single.id, 20);
  });

  testWidgets('an open delete confirmation expires when the account changes',
      (t) async {
    var deletes = 0;
    api.onDelete = (_) async {
      deletes++;
      return {};
    };
    await open(t);
    final old = table(t);
    old.onDeleteQuestion(old.questions.first);
    await t.pumpAndSettle();
    provider.updateAccount(33, 'admin');
    await t.pumpAndSettle();
    final labels = AppLocalizations.of(t.element(find.byType(AlertDialog)))!;
    await t.tap(find.widgetWithText(TextButton, labels.delete));
    await t.pumpAndSettle();
    expect(deletes, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
