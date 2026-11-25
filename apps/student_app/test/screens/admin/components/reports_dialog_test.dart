import 'dart:async';

import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/reports_dialog.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends Fake implements ApiService {
  late Future<dynamic> Function(String) read;
  late Future<dynamic> Function(String, Map<String, dynamic>) write;
  @override
  Future<dynamic> get(String endpoint) => read(endpoint);
  @override
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) =>
      write(endpoint, data);
}

class _Auth extends Fake implements AuthProvider {
  @override
  final _Api apiService = _Api();
}

Map<String, dynamic> _report(int q, [String status = 'pending']) => {
      'id': q + 100,
      'question_id': q,
      'user_id': 3,
      'status': status,
      'reason_category': 'incorrect_answer',
      'description': 'Reported question $q',
      'created_at': '2026-06-01T12:00:00Z',
    };

void main() {
  late _Auth auth;
  late AdminQuestionProvider provider;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    provider = AdminQuestionProvider(auth);
  });

  test('only the most recent question or account can publish reports',
      () async {
    final first = Completer<List<dynamic>>();
    final afterLogout = Completer<List<dynamic>>();
    auth.apiService.read = (url) async {
      if (url == '/reports/question/2') return [_report(2)];
      if (url.endsWith('/3')) return afterLogout.future;
      return first.future;
    };
    final early = provider.fetchReports(1);
    final current = provider.fetchReports(2);
    first.complete([_report(1)]);
    await Future.wait([early, current]);
    expect(provider.questionReports.map((r) => r.questionId), [2]);
    final pending = provider.fetchReports(3);
    provider.updateAccount(99, 'student');
    afterLogout.complete([_report(3)]);
    await pending;
    expect(provider.questionReports, isEmpty);
  });

  testWidgets(
      'an interrupted read can be retried, then resolving sends one PATCH',
      (tester) async {
    final saved = Completer<Map<String, dynamic>>();
    final urls = <String>[];
    final writes = <String>[];
    auth.apiService.read = (url) async {
      urls.add(url);
      if (urls.length == 1) throw Exception('offline');
      return [_report(7)];
    };
    auth.apiService.write = (url, data) {
      writes.add(url);
      expect(data['status'], 'resolved');
      return saved.future;
    };
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MaterialApp(
        locale: Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReportsDialog(questionId: 7)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(urls, ['/reports/question/7']);
    final labels =
        AppLocalizations.of(tester.element(find.byType(ReportsDialog)))!;
    await tester.tap(find.text(labels.retry));
    await tester.pumpAndSettle();
    expect(find.text('Reported question 7'), findsOneWidget);
    await tester.tap(find.text('Lezárás'));
    await tester.tap(find.text('Lezárás'));
    await tester.pump();
    expect(writes, ['/reports/107']);
    saved.complete(_report(7, 'resolved'));
    await tester.pumpAndSettle();
    expect(provider.questionReports.single.status, 'resolved');
    expect(find.text('Lezárás'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
