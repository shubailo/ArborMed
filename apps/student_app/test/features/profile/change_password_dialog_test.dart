import 'dart:async';

import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/features/profile/widgets/change_password_dialog.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  final response = Completer<void>();
  @override
  User? user = User.fromJson({'id': 7});
  @override
  bool get isAuthenticated => user != null;

  @override
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final outgoing = user;
    await response.future;
    if (user == outgoing) user = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Auth auth;
  Future<void> submit(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: MaterialApp(
        initialRoute: '/account',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/': (_) => const Scaffold(body: Text('Sign in')),
          '/account': (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showChangePasswordDialog(context),
                  child: const Text('Account settings'),
                ),
              ),
        },
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account settings'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'old');
    await tester.enterText(fields.at(1), 'new');
    await tester.enterText(fields.at(2), 'new');
    await tester.tap(find.text('UPDATE'));
    await tester.pump();
  }

  testWidgets('confirmed password change clears the private navigation stack',
      (tester) async {
    await submit(tester);
    auth.response.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Password changed successfully'), findsOneWidget);
    expect(Navigator.canPop(tester.element(find.text('Sign in'))), isFalse);
    expect(auth.user, isNull);
  });

  testWidgets('a late response dismisses only the outgoing account dialog',
      (tester) async {
    await submit(tester);
    auth.user = User.fromJson({'id': 8});
    auth.response.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Account settings'), findsOneWidget);
    expect(auth.user?.id, 8);
  });

  testWidgets(
      'a local cleanup error after sign-out still clears private routes',
      (tester) async {
    await submit(tester);
    auth.user = null;
    auth.response.completeError(StateError('Cache unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(Navigator.canPop(tester.element(find.text('Sign in'))), isFalse);
  });
}
