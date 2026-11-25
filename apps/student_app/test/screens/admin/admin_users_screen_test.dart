import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/admin_users_screen.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DirectoryApi extends Fake implements ApiService {
  final requests = <Uri>[];
  bool fail = false;
  String lastActivity = '2026-11-25T10:15:00Z';

  @override
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(endpoint);
    requests.add(uri);
    if (fail) throw StateError('Directory unavailable');
    final students = uri.path.endsWith('users-performance');
    final users = [
      {
        'id': 2,
        'email': 'ada@example.test',
        'created_at': '2026-01-01T00:00:00Z',
        'last_activity': lastActivity,
        if (!students) 'assigned_subject_name': 'Pathology',
        if (!students) 'assigned_subject_name_hu': 'Kórtan'
      },
      if (students && uri.queryParameters['search'] == '')
        {
          'id': 3,
          'email': 'kay@example.test',
          'created_at': '2026-01-02T00:00:00Z'
        }
    ];
    return {'users': users, 'total': users.length};
  }
}

class _Auth extends Fake with ChangeNotifier implements AuthProvider {
  @override
  final _DirectoryApi apiService = _DirectoryApi();
  @override
  User? get user => null;
}

void main() {
  testWidgets(
      'directory displays recorded visits on desktop and mobile and keeps server search results',
      (tester) async {
    final auth = _Auth();
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1500, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider(auth)),
      ],
      child: const MaterialApp(
        locale: Locale('hu'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminUsersScreen(),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nincs rögzített aktivitás'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);

    await tester.tap(find.text('Pathológia'));
    await tester.pump();
    expect(auth.apiService.requests.last.queryParameters['sort'], 'pathology');
    await tester.tap(find.text('Pathológia'));
    await tester.pump();
    expect(auth.apiService.requests.last.queryParameters['direction'], 'asc');

    final search = find.byType(TextField);
    for (final query in ['ada@example.test', '#002']) {
      await tester.enterText(search, query);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(auth.apiService.requests.last.queryParameters['search'], query);
      expect(find.text('ORVOSI AZONOSÍTÓ #002'), findsOneWidget);
    }
    tester.view.physicalSize = const Size(430, 850);
    await tester.pump();
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.textContaining('Nincs rögzített aktivitás'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    auth.apiService.lastActivity = '2027-01-01T12:00:00Z';
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(auth.apiService.requests.last.queryParameters['search'], '#002');
    expect(find.textContaining('2027'), findsOneWidget);

    auth.apiService.fail = true;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.text('Nem sikerült betölteni a felhasználók listáját.'),
        findsOneWidget);
    auth.apiService.fail = false;
    await tester
        .tap(find.text(AppLocalizations.of(tester.element(search))!.retry));
    await tester.pump();
    expect(find.text('ORVOSI AZONOSÍTÓ #002'), findsOneWidget);
    final labels = AppLocalizations.of(tester.element(search))!;
    await tester.tap(find.text(labels.adminStudents));
    await tester.pumpAndSettle();
    await tester.tap(find.text(labels.adminAdministrators));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(auth.apiService.requests.last.queryParameters['search'], '');
    expect(find.textContaining('Kórtan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
