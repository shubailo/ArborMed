import 'dart:async';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/bulk_action_toolbar.dart';
import 'package:arbor_med/screens/admin/components/questions_data_table.dart';
import 'package:arbor_med/screens/admin/questions_screen.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/admin_question_provider_test.dart' show MockAuthProvider, MockApiService;

Map<String, dynamic> _page(int id, {int total = 1}) => {
  'questions': [{'id': id, 'topic_id': 1, 'text': 'Question $id', 'options': [], 'correct_answer': 'A'}],
  'total': total,
};

void main() {
  late MockAuthProvider auth;
  late MockApiService api;
  late AdminQuestionProvider provider;
  setUp(() {
    auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    provider = AdminQuestionProvider(auth);
    SharedPreferences.setMockInitialValues({});
  });

  test('the newest query owns the table and its search terms survive transport', () async {
    final slow = Completer<dynamic>();
    final requests = <Uri>[];
    api.onGet = (endpoint) {
      requests.add(Uri.parse(endpoint));
      return requests.length == 1 ? slow.future : Future.value(_page(22));
    };
    final first = provider.fetchAdminQuestions(search: 'old');
    await provider.fetchAdminQuestions(search: 'A+B & C#D');
    slow.complete(_page(11));
    await first;
    expect(requests.last.queryParameters['search'], 'A+B & C#D');
    expect(provider.adminQuestions.single.id, 22);
  });

  test('a late list response cannot restore a previous account’s questions', () async {
    final pending = Completer<dynamic>();
    api.onGet = (_) => pending.future;
    provider.updateAccount(7, 'admin');
    final load = provider.fetchAdminQuestions();
    provider.updateAccount(8, 'student');
    pending.complete(_page(700));
    await load;
    expect(provider.adminQuestions, isEmpty);
  });

  test('quick search leaves the filtered table intact and mutations refresh that table', () async {
    final requests = <Uri>[];
    api.onGet = (endpoint) async {
      final uri = Uri.parse(endpoint);
      requests.add(uri);
      return _page(uri.queryParameters['search'] == '#32' ? 32 : 15);
    };
    api.onPost = (endpoint, data) async => {'success': true};
    await provider.fetchAdminQuestions(topicId: 77, bloomLevel: 2);
    expect((await provider.searchQuestions('#32')).single.id, 32);
    expect(provider.adminQuestions.single.id, 15);
    await provider.bulkActionQuestions(action: 'move', ids: [15], targetTopicId: 13);
    expect(requests.last, requests.first);
    api.onGet = (_) async => throw StateError('unavailable');
    await provider.fetchAdminQuestions(search: 'unavailable');
    expect(provider.questionsFailed, isTrue);
    expect(provider.adminQuestions, isEmpty);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => TopicProvider(auth)),
      ChangeNotifierProvider(create: (_) => AdminUserProvider(auth)),
      ChangeNotifierProvider(create: (_) => ThemeService()),
    ], child: const MaterialApp(
      locale: Locale('hu'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdminQuestionsScreen(),
    )));
    await tester.pumpAndSettle();
  }

  testWidgets('switching pages or search cannot leave a hidden question selected for bulk deletion', (tester) async {
    api.onGet = (endpoint) async {
      final uri = Uri.parse(endpoint);
      if (uri.path != ApiEndpoints.quizAdminQuestions) return [];
      return _page(uri.queryParameters['page'] == '2' ? 202 : 101, total: 201);
    };
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Question');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(find.byType(BulkActionToolbar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('Question 202'), findsOneWidget);
    expect(find.byType(BulkActionToolbar), findsNothing);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'another');
    await tester.pump();
    expect(find.byType(BulkActionToolbar), findsNothing);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<QuestionsDataTable>(find.byType(QuestionsDataTable))
            .selectedIds,
        isEmpty);
  });

  testWidgets('a committed bulk edit reloads the current question list only once', (t) async {
    int reads = 0;
    api.onGet = (endpoint) async {
      if (Uri.parse(endpoint).path != ApiEndpoints.quizAdminQuestions) return [];
      reads++;
      return _page(101);
    };
    api.onPost = (_, __) async => {};
    await open(t);
    await t.enterText(find.byType(TextField), 'Question');
    await t.pump(const Duration(milliseconds: 550));
    await t.pumpAndSettle();
    await t.tap(find.byType(Checkbox).last);
    await t.pumpAndSettle();
    final toolbar = t.widget<BulkActionToolbar>(find.byType(BulkActionToolbar));
    final l = AppLocalizations.of(t.element(find.byType(BulkActionToolbar)))!;
    final before = reads;
    toolbar.onDelete();
    await t.pumpAndSettle();
    await t.tap(find.text(l.adminDeleteAll));
    await t.pumpAndSettle();
    expect(reads - before, 1);
    expect(find.byType(BulkActionToolbar), findsNothing);
  });

  testWidgets(
      'subject switching uses rooted descendants, local names and valid remembered selections',
      (t) async {
    var parent = 2;
    final queries = <String?>[];
    api.onGet = (endpoint) async {
      final u = Uri.parse(endpoint);
      if (u.path == ApiEndpoints.quizTopics) {
        return [
          {
            'id': 1,
            'slug': 'new-root',
            'name_en': 'New root',
            'name_hu': 'Új tárgy'
          },
          {'id': 2, 'parent_id': 1, 'name_en': 'Parent', 'name_hu': 'Szülő'},
          {'id': 3, 'parent_id': parent, 'name_en': 'Deep', 'name_hu': ''},
          {'id': 4, 'name_en': 'Other subject', 'slug': 'other'},
        ];
      }
      if (u.path == ApiEndpoints.quizAdminQuestions) {
        queries.add(u.queryParameters['topic_id']);
        return _page(42);
      }
      return [];
    };
    await open(t);
    Future<void> subject(String label) async {
      await t.tap(find.byType(PopupMenuButton<int>));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(PopupMenuItem<int>, label));
      await t.pumpAndSettle();
    }

    await subject('Új tárgy');
    expect(queries.last, '1');
    final filter = find.byWidgetPredicate((w) =>
        w is DropdownButton<int?> &&
        w.items!.any((e) =>
            e.child is Text && (e.child as Text).data == 'Szülő › Deep'));
    await t.ensureVisible(filter);
    await t.tap(filter);
    await t.pumpAndSettle();
    await t.tap(find.text('Szülő › Deep').last);
    await t.pumpAndSettle();
    expect(queries.last, '3');
    await subject('Other subject');
    expect(queries.last, '4');
    await subject('Új tárgy');
    expect(queries.last, '3');
    final catalog =
        t.element(find.byType(AdminQuestionsScreen)).read<TopicProvider>();
    parent = 4;
    await catalog.fetchTopics();
    await t.pumpAndSettle();
    expect(queries.last, '1');
    await subject('Other subject');
    await subject('Új tárgy');
    expect(queries.last, '1');
    expect(t.takeException(), isNull);
  });

  testWidgets('ECG and case-study tabs render with a valid filter',
      (tester) async {
    api.onGet = (endpoint) async =>
        Uri.parse(endpoint).path == ApiEndpoints.quizAdminQuestions
            ? {'questions': [], 'total': 0}
            : [];
    await open(tester);
    final labels =
        AppLocalizations.of(tester.element(find.byType(AdminQuestionsScreen)))!;
    for (final label in [labels.quizECG, labels.adminCaseStudies]) {
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<int>, label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ECG cases have their own retry, count, localized diagnosis and accessible actions', (tester) async {
    var fail = true;
    api.onGet = (endpoint) async {
      final uri = Uri.parse(endpoint);
      if (uri.path == ApiEndpoints.quizAdminQuestions) return _page(1, total: 97);
      if (uri.path == ApiEndpoints.ecgCases) {
        if (fail) throw StateError('offline fixture');
        return [{'id':1,'diagnosis_id':3,'image_url':'/uploads/ecg/case_001.png','difficulty':'beginner',
          'diagnosis_code':'D1', 'diagnosis_name':'English diagnosis', 'diagnosis_name_hu':'Magyar diagnózis'}];
      }
      return [];
    };
    await open(tester);
    final labels = AppLocalizations.of(tester.element(find.byType(AdminQuestionsScreen)))!;
    await tester.tap(find.byType(PopupMenuButton<int>)); await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<int>, labels.quizECG)); await tester.pumpAndSettle();
    expect(find.text(labels.retry), findsOneWidget);
    expect(find.text(labels.adminNoEcgCasesFound), findsNothing);
    fail = false;
    await tester.tap(find.text(labels.retry)); await tester.pumpAndSettle();
    expect(find.text('1 EKG-eset'), findsOneWidget);
    expect(find.text('Magyar diagnózis'), findsOneWidget);
    expect(find.byTooltip(labels.edit), findsOneWidget);
    expect(find.byTooltip(labels.delete), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a late ECG request cannot overwrite a newer case list', () async {
    final old = Completer<dynamic>();
    api.onGet = (_) => old.future;
    final first = provider.fetchECGCases();
    api.onGet = (_) async => [{'id':2}];
    await provider.fetchECGCases();
    old.complete([{'id':1}]);
    await first;
    expect(provider.ecgCases.single.id, 2);
  });
}
