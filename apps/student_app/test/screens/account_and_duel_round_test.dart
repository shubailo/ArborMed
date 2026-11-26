import 'dart:async';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/screens/auth/verification_screen.dart';
import 'package:arbor_med/screens/game/duel_game_screen.dart';
import 'package:arbor_med/screens/game/duel_lobby_screen.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/duel_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  User? user = User.fromJson({'id': 1, 'coins': 30});
  var refreshes = 0, sends = 0, signOuts = 0;
  Future<void> Function() refresh = () async {};
  Future<void> Function() resend = () async {};
  Future<void> Function() end = () async {};
  void notifyListenersForTest() => notifyListeners();
  @override
  Future<void> refreshUser() {
    refreshes++;
    return refresh();
  }

  @override
  Future<void> resendRegistrationOTP(String email, String id) {
    sends++;
    return resend();
  }

  @override
  Future<void> logout() {
    signOuts++;
    return end();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Duel extends ChangeNotifier implements DuelProvider {
  @override
  DuelState state = DuelState.idle;
  @override
  int get currentWager => 10;
  @override
  String? get errorMessage => null;
  @override
  List<Map<String, dynamic>> get questions => [];
  final joins = <int>[];
  Future<bool> Function() leave = () async => true;
  @override
  void initialize() {}
  @override
  void joinQueue(int wager) => joins.add(wager);
  @override
  Future<bool> leaveQueue() => leave();
  void notifyForTest() => notifyListeners();
  void playing() {
    state = DuelState.playing;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Auth auth;
  late _Duel duel;
  late GlobalKey<NavigatorState> nav;
  const verify = VerificationScreen(
      email: 'student@example.test', registrationId: 'fixture');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    duel = _Duel();
    nav = GlobalKey<NavigatorState>();
  });
  Future<void> open(WidgetTester t, Widget page,
      {String language = 'en', Size size = const Size(900, 1100)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<DuelProvider>.value(value: duel),
          ChangeNotifierProvider(create: (_) => ThemeService())
        ],
        child: MaterialApp(
            navigatorKey: nav,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Text('Home fixture')))));
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => page));
    await t.pumpAndSettle();
  }

  CozyButton cozy(WidgetTester t, String label) =>
      t.widget<CozyButton>(find.byWidgetPredicate(
          (w) => w is CozyButton && w.label.toUpperCase() == label));
  testWidgets('verification controls fit with a compact viewport and scrolling',
      (t) async {
    await open(t, verify, size: const Size(390, 440));
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('Resend Code'));
    expect(find.text('Resend Code').hitTestable(), findsOneWidget);
  });
  testWidgets(
      'verification accepts six digits and prevents a repeated resend in the same frame',
      (t) async {
    await open(t, verify);
    expect(t.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await t.enterText(find.byType(TextFormField), 'a123456');
    await t.pump();
    expect(t.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        '123456');
    expect(t.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
    final gate = Completer<void>();
    auth.resend = () => gate.future;
    final action = t
        .widget<TextButton>(find.widgetWithText(TextButton, 'Resend Code'))
        .onPressed!;
    action();
    action();
    gate.complete();
    await t.pump();
    expect(auth.sends, 1);
  });
  testWidgets(
      'a superseded code offers a restart and a delivery outage leaves the code intact',
      (t) async {
    await open(t, verify);
    await t.enterText(find.byType(TextFormField), '123456');
    auth.resend = () async => throw const ServerException(
        statusCode: 503, message: 'Mail temporarily unavailable');
    await t.tap(find.text('Resend Code'));
    await t.pumpAndSettle();
    expect(t.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        '123456');
    expect(
        find.text('Verification is temporarily unavailable. Try again later.'),
        findsOneWidget);
    auth.resend = () async =>
        throw const ApiException(statusCode: 429, message: 'Too many requests');
    await t.tap(find.text('Resend Code'));
    await t.pumpAndSettle();
    expect(find.text('Too many requests. Please try again later.'),
        findsOneWidget);
    auth.resend =
        () async => throw const ConflictException(message: 'Challenge changed');
    await t.tap(find.text('Resend Code'));
    await t.pumpAndSettle();
    expect(find.text('Start again'), findsOneWidget);
    await t.tap(find.text('Start again'));
    await t.pumpAndSettle();
    expect(find.text('Home fixture'), findsOneWidget);
  });
  testWidgets(
      'sign-out remains on the verification route until device cleanup finishes',
      (t) async {
    await open(t, verify);
    final gate = Completer<void>();
    auth.end = () => gate.future;
    await t
        .tap(find.textContaining(RegExp(r'^Sign out$', caseSensitive: false)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    expect(ModalRoute.of(t.element(find.byType(VerificationScreen)))!.isCurrent,
        isTrue);
    gate.complete();
    await t.pumpAndSettle();
    expect(find.text('Home fixture'), findsOneWidget);
  });
  testWidgets(
      'a failed sign-out cleanup reports the failure on the verification screen',
      (t) async {
    await open(t, verify);
    auth.end = () async => throw StateError('fixture cleanup');
    await t
        .tap(find.textContaining(RegExp(r'^Sign out$', caseSensitive: false)));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Could not finish signing out on this device. Try again.'),
        findsOneWidget);
    expect(find.byType(VerificationScreen), findsOneWidget);
  });

  testWidgets('verification and lobby use the selected Hungarian locale',
      (t) async {
    await open(t, verify, language: 'hu');
    expect(find.text('Kód újraküldése'), findsOneWidget);
    nav.currentState!.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DuelLobbyScreen()));
    await t.pumpAndSettle();
    expect(find.text('TÉT KIVÁLASZTÁSA'), findsOneWidget);
    duel.state = DuelState.searching;
    duel.notifyForTest();
    await t.pump();
    expect(find.text('Tét: 10 🩺'), findsOneWidget);
  });
  testWidgets('a wager belongs to the account that requested the balance check',
      (t) async {
    await open(t, const DuelLobbyScreen());
    final gate = Completer<void>();
    auth.refresh = () => gate.future;
    final action = cozy(t, 'FIND MATCH').onPressed!;
    action();
    action();
    auth.user = User.fromJson({'id': 2, 'coins': 100});
    gate.complete();
    await t.pump();
    expect(duel.joins, isEmpty);
    expect(auth.refreshes, 1);
  });
  testWidgets('search rechecks the balance and reports an unavailable refresh',
      (t) async {
    await open(t, const DuelLobbyScreen());
    auth.refresh = () async {
      auth.user = User.fromJson({'id': 1, 'coins': 2});
    };
    cozy(t, 'FIND MATCH').onPressed!();
    await t.pump();
    expect(duel.joins, isEmpty);
    auth.user = User.fromJson({'id': 1, 'coins': 30});
    auth.notifyListenersForTest();
    await t.pump();
    auth.refresh = () async => throw const ServerException();
    cozy(t, 'FIND MATCH').onPressed!();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Could not refresh your balance. Try again.'),
        findsOneWidget);
  });
  testWidgets(
      'a cancellation acknowledgement cannot pop the screen above the lobby',
      (t) async {
    await open(t, const DuelLobbyScreen());
    final gate = Completer<bool>();
    duel.leave = () => gate.future;
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pump();
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other screen'))));
    await t.pumpAndSettle();
    gate.complete(true);
    await t.pumpAndSettle();
    expect(find.text('Other screen'), findsOneWidget);
  });
  testWidgets(
      'a match found behind another route opens when the lobby becomes current',
      (t) async {
    await open(t, const DuelLobbyScreen());
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other screen'))));
    await t.pumpAndSettle();
    duel.playing();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Other screen'), findsOneWidget);
    nav.currentState!.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(DuelGameScreen), findsOneWidget);
  });
  testWidgets(
      'a failed leave can be retried and the wallet outage does not trap the lobby',
      (t) async {
    await open(t, const DuelLobbyScreen());
    duel.leave = () async => throw StateError('fixture');
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Could not confirm leaving the queue. Try again.'),
        findsOneWidget);
    duel.leave = () async => true;
    auth.refresh = () async => throw const ServerException();
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('Home fixture'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
