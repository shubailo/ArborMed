import 'dart:async';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/manage_sections_dialog.dart';
import 'package:flutter/material.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../services/admin_question_provider_test.dart'
    show MockApiService, MockAuthProvider;

class _SessionAuth extends MockAuthProvider {
  final _listeners = <VoidCallback>{};

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  int _revision = 0;
  @override
  int get sessionRevision => _revision;
  void signInAgain() {
    _revision++;
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}

void main() {
  late _SessionAuth auth;
  late TopicProvider provider;
  late MockApiService api;
  late int changed;
  final rows = <Map<String, dynamic>>[];
  Map<String, dynamic> row(int id, String name) =>
      {'id': id, 'parent_id': 1, 'name_en': name, 'name_hu': 'HU $name'};
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _SessionAuth();
    provider = TopicProvider(auth);
    api = auth.apiService as MockApiService;
    changed = 0;
    rows.clear();
    api.onGet = (_) async => rows;
  });
  Future<AppLocalizations> open(WidgetTester t) async {
    await provider.fetchTopics();
    await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => ThemeService())
        ],
        child: MaterialApp(
            locale: const Locale('hu'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: Builder(
                    builder: (ctx) => TextButton(
                        onPressed: () => showDialog<void>(
                            context: ctx,
                            builder: (_) => ManageSectionsDialog(
                                subjectId: 1,
                                subjectName: 'Élettan',
                                onChanged: () {
                                  changed++;
                                })),
                        child: const Text('open')))))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return AppLocalizations.of(t.element(find.byType(ManageSectionsDialog)))!;
  }

  Future<void> settleDialog(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
  }

  testWidgets(
      'Enter and add in one frame submit once; dismissal during the write is safe',
      (t) async {
    final pending = Completer<dynamic>();
    var posts = 0;
    api.onPost = (_, __) {
      posts++;
      return pending.future;
    };
    final l = await open(t);
    await t.enterText(find.byType(TextFormField).first, 'Pulse');
    final submit =
        t.widget<TextField>(find.byType(TextField).last).onSubmitted!;
    final button = t
        .widget<ElevatedButton>(find.ancestor(
            of: find.text(l.adminAddSection),
            matching: find.byWidgetPredicate((w) => w is ElevatedButton)))
        .onPressed!;
    submit('');
    button();
    expect(posts, 1);
    await t.pump();
    await t.tap(find.text(l.close));
    await t.pumpAndSettle();
    rows.add(row(2, 'Pulse'));
    pending.complete(rows.single);
    await t.pumpAndSettle();
    expect(changed, 0);
    expect(provider.topics.single['id'], 2);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'a failed rename keeps its draft on the same row across reorder and a retry saves once',
      (t) async {
    rows.addAll([row(2, 'Alpha'), row(3, 'Beta')]);
    final l = await open(t);
    await t.tap(find.byTooltip(l.edit).first);
    await t.pumpAndSettle();
    final field =
        find.widgetWithText(TextField, '${l.adminRenameSection} (EN)');
    await t.enterText(field, 'New Alpha');
    final p = Completer<dynamic>();
    var puts = 0;
    api.onPut = (_, __) {
      puts++;
      return p.future;
    };
    final submit = t.widget<TextField>(field).onSubmitted!;
    submit('New Alpha');
    submit('New Alpha');
    expect(puts, 1);
    rows.insert(0, rows.removeLast());
    await provider.fetchTopics();
    await t.pump();
    p.completeError(const ConflictException(message: 'Name conflict'));
    await t.pumpAndSettle();
    expect(find.text('New Alpha'), findsOneWidget);
    expect(changed, 0);
    api.onPut = (path, body) async {
      expect(path, endsWith('/2'));
      rows[1] = row(2, body['name_en']);
      return rows[1];
    };
    await t.tap(find.text(l.save));
    await t.pumpAndSettle();
    expect(find.text('New Alpha'), findsOneWidget);
    expect(changed, 1);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'repeat delete opens one prompt and a cancelled second confirmation sends no force',
      (t) async {
    rows.add(row(2, 'Alpha'));
    final l = await open(t);
    final action = t
        .widget<IconButton>(find.ancestor(
            of: find.byIcon(Icons.delete), matching: find.byType(IconButton)))
        .onPressed!;
    action();
    action();
    await settleDialog(t);
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    final paths = <String>[];
    api.onDelete = (path) async {
      paths.add(path);
      throw const ConflictException(
          message: 'Erősítsd meg',
          body:
              '{"code":"topic_questions_confirmation","count":3,"confirmation":"first"}');
    };
    await t.tap(find.widgetWithText(TextButton, l.delete));
    await settleDialog(t);
    expect(find.textContaining('HU Alpha (3)'), findsOneWidget);
    await t.tap(find.text(l.cancel));
    await settleDialog(t);
    expect(paths, hasLength(1));
    expect(changed, 0);
    await t.tap(find.byTooltip(l.delete));
    await settleDialog(t);
    await t.tap(find.widgetWithText(TextButton, l.delete));
    await settleDialog(t);
    api.onDelete = (path) async {
      paths.add(path);
      rows.clear();
      return {};
    };
    final yes = t
        .widget<TextButton>(
            find.widgetWithText(TextButton, l.adminYesDeleteEverything))
        .onPressed!;
    yes();
    yes();
    await settleDialog(t);
    expect(paths.where((p) => p.contains('force=true')).length, 1);
    expect(find.byType(ManageSectionsDialog), findsOneWidget);
    expect(changed, 1);
  });

  testWidgets('an open delete confirmation is invalid across sessions',
      (t) async {
    rows.add(row(2, 'Alpha'));
    final l = await open(t);
    await t.tap(find.byIcon(Icons.delete));
    await settleDialog(t);
    var calls = 0;
    api.onDelete = (_) async {
      calls++;
      return {};
    };
    auth.signInAgain();
    await t.pump();
    await t.tap(find.widgetWithText(TextButton, l.delete));
    await settleDialog(t);
    expect(calls, 0);
    expect(changed, 0);
  });

  testWidgets(
      'a compact dialog can recover from a failed catalog and reach the last section',
      (t) async {
    t.view.physicalSize = const Size(360, 420);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    api.onGet = (_) async => throw const NetworkException();
    final l = await open(t);
    expect(find.text(l.adminNoSectionsYet), findsNothing);
    api.onGet = (_) async => List.generate(40, (i) => row(i + 2, 'Section $i'));
    await t.drag(find.byType(ListView), const Offset(0, -220));
    await t.pumpAndSettle();
    await t.tap(find.textContaining(l.retry));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Section 39'), 500,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Section 39'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
