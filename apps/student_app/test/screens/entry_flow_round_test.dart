import 'dart:async';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/screens/auth/login_screen.dart';
import 'package:arbor_med/screens/auth/register_screen.dart';
import 'package:arbor_med/screens/auth/verification_screen.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoading => false;
  final logins = <String>[],
      registrations = <String>[],
      codes = <String>[],
      resets = <String>[];
  final loginGate = Completer<void>(),
      registerGate = Completer<String>(),
      sendGate = Completer<void>();
  @override
  Future<void> login(String identifier, String password) {
    logins.add(identifier);
    return loginGate.future;
  }

  @override
  Future<String> register(String email, String password,
      {String? username, String? displayName}) {
    registrations.add(email);
    return registerGate.future;
  }

  @override
  Future<void> requestOTP(String email,
      {String purpose = 'password-reset', String? verificationId}) {
    codes.add(email);
    return sendGate.future;
  }

  @override
  Future<void> resetPassword(String email, String otp, String password) async {
    resets.add(email);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _Auth auth;
  late GlobalKey<NavigatorState> nav;
  setUp(() {
    nav = GlobalKey<NavigatorState>();
    SharedPreferences.setMockInitialValues({});
  });
  // The password-strength wave animates continuously while its route is visible.
  Future<void> settleRoute(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    await t.pump();
  }

  Future<void> page(WidgetTester t, Widget screen,
      {Locale locale = const Locale('en')}) async {
    auth = _Auth();
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeService()),
        ],
        child: MaterialApp(
            navigatorKey: nav,
            home: screen,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales)));
    await settleRoute(t);
  }

  Future<void> openReset(WidgetTester t) async {
    await page(t, const LoginScreen());
    await t.tap(find.text('Forgot Password?'));
    await settleRoute(t);
    await t.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextFormField)),
        'first@example.test');
  }

  Future<void> fillRegister(WidgetTester t) async {
    const values = [
      'first@example.test',
      'student',
      'First student',
      'Strong123!'
    ];
    for (var i = 0; i < values.length; i++) {
      await t.enterText(
          find
              .descendant(
                  of: find.byType(RegisterScreen),
                  matching: find.byType(TextFormField))
              .at(i),
          values[i]);
    }
  }

  testWidgets(
      'keyboard and button submit just one registration and one challenge',
      (t) async {
    await page(t, const RegisterScreen());
    await fillRegister(t);
    final enter =
        t.widget<EditableText>(find.byType(EditableText).last).onSubmitted!;
    final send = t
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Create Account'))
        .onPressed!;
    enter('Strong123!');
    send();
    auth.registerGate.complete('fixture-registration');
    await settleRoute(t);
    expect(auth.registrations, ['first@example.test']);
    expect(
        t
            .widget<VerificationScreen>(find.byType(VerificationScreen))
            .registrationId,
        'fixture-registration');
  });
  testWidgets('a late registration response stays behind the current screen',
      (t) async {
    await page(t, const RegisterScreen());
    await fillRegister(t);
    t
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Create Account'))
        .onPressed!();
    expect(auth.registrations, ['first@example.test']);
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other route'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    auth.registerGate.complete('fixture');
    await settleRoute(t);
    expect(find.text('Other route'), findsOneWidget);
    expect(
        ModalRoute.of(t.element(find.text('Other route')))!.isCurrent, isTrue);
  });
  testWidgets(
      'an existing-account response returns the address actually submitted',
      (t) async {
    await page(t, const Scaffold(body: Text('Return route')));
    final result = nav.currentState!.push<String>(
        MaterialPageRoute<String>(builder: (_) => const RegisterScreen()));
    await settleRoute(t);
    await fillRegister(t);
    t
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Create Account'))
        .onPressed!();
    expect(auth.registrations, ['first@example.test']);
    await t.pump();
    final field = t.widget<TextFormField>(find.byType(TextFormField).first);
    field.controller!.text = 'edited@example.test';
    auth.registerGate.completeError(const ApiException(
        statusCode: 400, message: 'An account already exists.'));
    await settleRoute(t);
    expect(find.byType(RegisterScreen), findsOneWidget);
    await t.tap(find.byType(SnackBarAction));
    await settleRoute(t);
    expect(await result, 'first@example.test');
  });
  testWidgets(
      'login coalesces duplicate submits and leaves a newer route alone',
      (t) async {
    await page(t, const LoginScreen());
    await t.enterText(find.byType(TextFormField).first, 'student');
    await t.enterText(find.byType(TextFormField).last, 'Strong123!');
    final send = t
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Login'))
        .onPressed!;
    send();
    send();
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other route'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    auth.loginGate.completeError(const EmailVerificationRequired(
        email: 'first@example.test',
        verificationId: 'fixture',
        message: 'Check email.'));
    await settleRoute(t);
    expect(find.text('Other route'), findsOneWidget);
    expect(auth.logins, ['student']);
  });
  testWidgets('reset remains bound to the mailbox that received the code',
      (t) async {
    await openReset(t);
    final send = t
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Send Code'))
        .onPressed!;
    send();
    send();
    final originalField = t.widget<TextFormField>(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextFormField)));
    originalField.controller!.text = 'edited@example.test';
    auth.sendGate.complete();
    await settleRoute(t);
    expect(find.text('Code sent to first@example.test'), findsOneWidget);
    final inputs = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    await t.enterText(inputs.first, '123456');
    await t.enterText(inputs.last, 'Second123!');
    await t.tap(find.text('Reset'));
    await settleRoute(t);
    expect(auth.codes, ['first@example.test']);
    expect(auth.resets, ['first@example.test']);
  });
  testWidgets(
      'closing reset releases its input controllers even when delivery is pending',
      (t) async {
    await openReset(t);
    final controller = t
        .widget<TextFormField>(find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextFormField)))
        .controller!;
    await t.tap(find.text('Send Code'));
    await t.pump();
    await t.tap(find.text('Cancel'));
    await settleRoute(t);
    auth.sendGate.complete();
    await t.pump();
    expect(t.takeException(), isNull);
    expect(() => controller.addListener(() {}), throwsFlutterError);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
      'the entry screens and password recovery use the selected Hungarian locale',
      (t) async {
    await page(t, const LoginScreen(), locale: const Locale('hu'));
    expect(find.text('Bejelentkezés'), findsOneWidget);
    await t.tap(find.text('Elfelejtetted a jelszavad?'));
    await settleRoute(t);
    expect(find.text('Kód küldése'), findsOneWidget);
    nav.currentState!.pop();
    await settleRoute(t);
    nav.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
    await settleRoute(t);
    expect(find.text('Fiók létrehozása'), findsOneWidget);
  });
  testWidgets(
      'login releases the identifier and password controllers on disposal',
      (t) async {
    await page(t, const LoginScreen());
    final controllers = t
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((w) => w.controller!)
        .toList();
    await t.pumpWidget(const SizedBox());
    for (final c in controllers) {
      expect(() => c.addListener(() {}), throwsFlutterError);
    }
  });
}
