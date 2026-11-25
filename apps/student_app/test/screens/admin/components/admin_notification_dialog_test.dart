import 'dart:async';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/admin/components/admin_notification_dialog.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends Fake implements ApiService {
  final calls = <Map<String, dynamic>>[];
  var response = Completer<dynamic>();
  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) {
    expect(endpoint, '/admin/notify/broadcast');
    calls.add(data);
    return response.future;
  }
}

class _Auth extends Fake implements AuthProvider {
  @override
  final _Api apiService = _Api();
}

void main() {
  testWidgets(
      'keeps the draft on failure and confirms the server count on retry',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = _Auth();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => AdminUserProvider(auth)),
        ],
        child: MaterialApp(
          locale: const Locale('hu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
              builder: (context) => Scaffold(
                      body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AdminNotificationDialog()),
                    child: const Text('Open'),
                  ))),
        )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    final labels = AppLocalizations.of(tester.element(fields.first))!;
    await tester.enterText(fields.first, ' Title ');
    await tester.enterText(fields.last, ' Draft ');
    await tester.tap(find.text(labels.adminSendNow));
    await tester.pump();
    expect(auth.apiService.calls.single, containsPair('title', 'Title'));
    expect(auth.apiService.calls.single, containsPair('message', 'Draft'));
    expect(find.text(labels.adminBroadcastDelivered(2)), findsNothing);
    auth.apiService.response.completeError(Exception('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text(labels.adminBroadcastFailed), findsOneWidget);
    expect(
        tester.widget<TextField>(fields.last).controller!.text.trim(), 'Draft');
    auth.apiService.response = Completer<dynamic>();
    await tester.tap(find.text(labels.adminSendNow));
    await tester.pump();
    expect(auth.apiService.calls[1]['requestId'],
        auth.apiService.calls[0]['requestId']);
    auth.apiService.response.complete({'delivered': 2});
    await tester.pumpAndSettle();
    expect(find.byType(AdminNotificationDialog), findsNothing);
    expect(find.text(labels.adminBroadcastDelivered(2)), findsOneWidget);
  });
}
