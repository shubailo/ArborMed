import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/core/models/topic_hierarchy.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/screens/admin/components/batch_upload_dialog.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/bulk_action_handler.dart';
import 'package:arbor_med/screens/admin/components/question_metadata_section.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/admin_question_provider_test.dart'
    show MockAuthProvider, MockApiService;

void main() {
  late MockApiService api;
  late TopicProvider topics;
  late AdminQuestionProvider questions;
  final rows = <Map<String, dynamic>>[];
  final ids = <int>{};
  final sent = <Map<String, dynamic>>[];
  int changed = 0;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    topics = TopicProvider(auth);
    questions = AdminQuestionProvider(auth);
    ids
      ..clear()
      ..addAll([12, 13]);
    changed = 0;
    sent.clear();
    rows
      ..clear()
      ..addAll([
        {'id': 1, 'name_en': 'A', 'name_hu': 'Tárgy'},
        {'id': 2, 'name_en': 'Parent', 'name_hu': 'Ág', 'parent_id': 1},
        {'id': 3, 'name_en': 'Leaf', 'parent_id': 2},
        {'id': 4, 'name_en': 'Other'},
      ]);
    api.onGet = (path) async =>
        path.endsWith('/topics') ? rows : {'questions': [], 'total': 0};
    api.onPost = (path, body) async {
      sent.add(body);
      return {};
    };
  });

  test(
      'sibling labels distinguish equal translations and disconnected nodes stay outside the catalog',
      () {
    final tree = TopicHierarchy([
      ...rows,
      {'id': 5, 'name_en': 'Parent B', 'name_hu': 'Ág', 'parent_id': 1},
      {'id': 6, 'name_en': 'Self', 'parent_id': 6},
      {'id': 7, 'name_en': 'Orphan', 'parent_id': 12},
    ]);
    expect(tree.members(1), [1, 2, 3, 5]);
    expect(tree.label(3, 'hu', '?'), 'Ág [#2] › Leaf');
    expect(tree.label(5, 'hu', '?'), 'Ág [#5]');
    expect(tree.label(2, 'en', '?'), 'Parent');
    expect(tree.branch(6), isEmpty);
    expect(tree.branch(7), isEmpty);
  });

  Future<AppLocalizations> open(
      WidgetTester t, Widget Function(BuildContext) builder) async {
    await topics.fetchTopics();
    await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: topics),
          ChangeNotifierProvider(create: (_) => ThemeService()),
        ],
        child: MaterialApp(
            locale: const Locale('hu'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Builder(builder: builder)))));
    return AppLocalizations.of(t.element(find.byType(Scaffold)))!;
  }

  Widget commands(BuildContext ctx) => Column(children: [
        TextButton(
            onPressed: () => BulkActionHandler.handleBulkDelete(
                context: ctx,
                questionProvider: questions,
                selectedIds: ids,
                onSuccess: () => changed++),
            child: const Text('erase')),
        TextButton(
            onPressed: () => BulkActionHandler.handleBulkMove(
                context: ctx,
                questionProvider: questions,
                selectedIds: ids,
                onSuccess: () => changed++),
            child: const Text('move')),
      ]);
  testWidgets(
      'bulk confirmation freezes IDs, blocks a second prompt and double confirmation',
      (t) async {
    final l = await open(t, commands);
    final press = t
        .widget<TextButton>(find.widgetWithText(TextButton, 'erase'))
        .onPressed!;
    press();
    press();
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    ids
      ..clear()
      ..add(99);
    final yes = t
        .widget<TextButton>(find.widgetWithText(TextButton, l.adminDeleteAll))
        .onPressed!;
    yes();
    yes();
    await t.pumpAndSettle();
    expect(sent.single['ids'], [12, 13]);
    expect(changed, 1);
  });
  testWidgets(
      'bulk move rechecks the branch and can select the new destination explicitly',
      (t) async {
    final l = await open(t, commands);
    await t.tap(find.text('move'));
    await t.pumpAndSettle();
    Future<void> choose(String label) async {
      await t.tap(find.byType(DropdownButtonFormField<int>));
      await t.pumpAndSettle();
      await t.tap(find.text(label).last);
      await t.pumpAndSettle();
    }

    await choose('Tárgy › Ág › Leaf');
    rows[2]['parent_id'] = 4;
    await topics.fetchTopics();
    await t.pumpAndSettle();
    expect(
        t
            .widget<TextButton>(find.widgetWithText(TextButton, l.adminMoveNow))
            .onPressed,
        isNull);
    await choose('Other › Leaf');
    await t.tap(find.text(l.adminMoveNow));
    await t.pumpAndSettle();
    expect(sent.single, {
      'action': 'move',
      'ids': [12, 13],
      'targetTopicId': 3
    });
    expect(changed, 1);
  });
  testWidgets(
      'a confirmation from a previous account cannot submit a bulk mutation',
      (t) async {
    final l = await open(t, commands);
    await t.tap(find.text('erase'));
    await t.pumpAndSettle();
    questions.updateAccount(18, 'admin');
    await t.tap(find.text(l.adminDeleteAll));
    await t.pumpAndSettle();
    expect(sent, isEmpty);
    expect(changed, 0);
  });
  testWidgets('template download failures reach the dialog and allow a retry',
      (t) async {
    var calls = 0;
    api.onGetBytes = (_) async {
      calls++;
      throw ApiException(
          statusCode: 503, message: 'Service unavailable ($calls)');
    };
    final labels = await open(
        t,
        (ctx) => TextButton(
              onPressed: () => BatchUploadDialog.show(ctx,
                  questionProvider: questions, onComplete: () {}),
              child: const Text('Import'),
            ));
    await t.tap(find.text('Import'));
    await t.pumpAndSettle();
    for (int i = 1; i <= 2; i++) {
      await t.tap(find.text(labels.adminDownloadTemplate));
      await t.pumpAndSettle();
      expect(find.text('Service unavailable ($i)'), findsOneWidget);
    }
    expect(calls, 2);
  });

  testWidgets(
      'metadata allows the root itself and requires correction of a legacy Bloom value',
      (t) async {
    final key = GlobalKey<FormState>();
    int? picked;
    int bloom = 6;
    await open(
        t,
        (ctx) => StatefulBuilder(
            builder: (ctx, rebuild) => Form(
                key: key,
                child: QuestionMetadataSection(
                    hierarchy: TopicHierarchy(topics.topics),
                    questionType: 'single_choice',
                    bloomLevel: bloom,
                    selectedSubjectId: 1,
                    selectedTopicId: picked,
                    onQuestionTypeChanged: (_) {},
                    onBloomLevelChanged: (v) => rebuild(() => bloom = v),
                    onSubjectChanged: (_) {},
                    onTopicChanged: (v) => rebuild(() => picked = v)))));
    expect(t.takeException(), isNull);
    expect(key.currentState!.validate(), isFalse);
    final bloomField = t.widget<DropdownButtonFormField<int>>(
        find.byKey(const ValueKey('bloom_6')));
    bloomField.onChanged!(4);
    await t.pump();
    final topicsField = t.widget<DropdownButtonFormField<int>>(
        find.byKey(const ValueKey('topic_null')));
    topicsField.onChanged!(1);
    await t.pump();
    expect(find.text('Tárgy'), findsWidgets);
    expect(key.currentState!.validate(), isTrue);
    expect(picked, 1);
  });
}
