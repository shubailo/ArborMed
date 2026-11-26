import 'dart:convert';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/screens/auth/login_screen.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cache extends Fake implements AppDatabase {}

void main() {
  testWidgets('username login continues after the matching mailbox challenge',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    const email = 'student@example.com';
    const verificationId = '1581aed1-099b-4d53-a309-aca80ee292e5';
    final requests = <String>[];
    final api = ApiService()..setToken('');
    api.setHttpClient(MockClient((request) async {
      requests.add(request.url.path);
      final body = jsonDecode(request.body);
      if (request.url.path == ApiEndpoints.authLogin) {
        expect(body, {'username': 'student', 'password': 'Original123!'});
        if (requests.length == 1) {
          return http.Response(
              jsonEncode({
                'code': 'email_not_verified',
                'email': email,
                'verificationId': verificationId,
                'message': 'Check your email.'
              }),
              403);
        }
        return http.Response(
            jsonEncode({
              'id': 1,
              'email': email,
              'is_email_verified': true,
              'token': 'verified',
              'refreshToken': 'renew'
            }),
            200);
      }
      expect(body['email'], email);
      expect(body['verificationId'], verificationId);
      if (request.url.path == ApiEndpoints.authVerifyEmail) {
        expect(body['otp'], '123456');
      }
      if (request.url.path == ApiEndpoints.authRequestOtp) {
        expect(body['purpose'], 'email-verification');
      }
      return http.Response('{}', 200);
    }));
    final auth = AuthProvider(db: _Cache(), apiService: api);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider.value(value: auth),
    ], child: const MaterialApp(home: LoginScreen())));
    await tester.enterText(find.byType(TextFormField).first, 'student');
    await tester.enterText(find.byType(TextFormField).last, 'Original123!');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.textContaining(email), findsOneWidget);
    expect(auth.user, isNull);
    await tester.tap(find.text('Resend Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump(); // Rebuild the button after the sixth digit enables it.
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();
    expect(auth.user?.email, email);
    expect(requests, [
      ApiEndpoints.authLogin,
      ApiEndpoints.authRequestOtp,
      ApiEndpoints.authVerifyEmail,
      ApiEndpoints.authLogin
    ]);
  });
}
