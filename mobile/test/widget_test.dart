import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login Screen Smoke Test', (WidgetTester tester) async {
    // Build app with isolated AuthProvider to avoid Audio/API issues in headless env.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify "AGOOM Login" title is present.
    expect(find.text('AGOOM Login'), findsOneWidget);

    // Verify "Login" button text is present.
    expect(find.text('Login'), findsOneWidget);
    
    // Check for Email and Password fields
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
