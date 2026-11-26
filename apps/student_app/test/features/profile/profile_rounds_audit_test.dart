import 'dart:async';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/dashboard/widgets/mission_control_view.dart';
import 'package:arbor_med/features/profile/providers/rank_provider.dart';
import 'package:arbor_med/features/profile/widgets/profile_portal.dart';
import 'package:arbor_med/features/room/widgets/probation_overlay.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String day(DateTime now) => now.toUtc().toIso8601String().split('T').first;
Map<String, dynamic> status(
        {int progress = 0,
        bool done = false,
        int strikes = 3,
        String? studyDay}) =>
    {
      'status': 'success',
      'data': {
        'rank': 'resident',
        'malpracticeStrikes': strikes,
        'studyDay': studyDay ?? day(DateTime.now()),
        'roundsProgress': progress,
        'roundsGoal': 10,
        'roundsCompleted': done
      }
    };

class _Api extends Fake implements ApiService {
  final reads = <String>[];
  final writes = <Map<String, dynamic>>[];
  Future<dynamic> Function(String) read = (_) async => status();
  Future<dynamic> Function() write =
      () async => status(done: true, progress: 10, strikes: 2);
  @override
  Future<dynamic> get(String path) {
    reads.add(path);
    return read(path);
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) {
    expect(path, '/gamification/sync-rounds');
    writes.add(body);
    return write();
  }
}

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  final _Api apiService = _Api();
  @override
  User? user = User.fromJson({'id': 1, 'display_name': 'Old', 'xp': 50});
  @override
  int sessionRevision = 1;
  var refreshes = 0;
  bool offline = false;
  final saves = <String>[];
  Future<void> Function() save = () async {};
  @override
  Future<void> refreshUser() async {
    refreshes++;
    if (offline) throw StateError('offline');
  }

  @override
  Future<void> updateNickname(String name) {
    saves.add(name);
    return save();
  }

  void switchSession() {
    sessionRevision++;
    user = User.fromJson({'id': 1, 'display_name': 'Second session'});
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Audio extends ChangeNotifier implements AudioProvider {
  @override
  Future<void> playSfx(String name) async {}
  @override
  Future<void> ensureMusicPlaying() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Auth auth;
  late StatsProvider stats;
  late RankProvider rank;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    stats = StatsProvider(auth);
  });
  tearDown(() {
    stats.dispose();
    auth.dispose();
  });
  Widget app(Widget home, {String lang = 'en'}) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider.value(value: stats),
            ChangeNotifierProvider<RankProvider>(
                create: (_) => RankProvider(auth)),
            ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ],
          child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: home)));
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
  }

  Future<void> editor(WidgetTester t) async {
    await t.pumpWidget(app(const ProfilePortal()));
    await frames(t);
    await t.tap(find.byIcon(Icons.badge_outlined));
    await frames(t);
  }

  testWidgets('one save click submits exactly one nickname update', (t) async {
    await editor(t);
    await t.enterText(find.byType(EditableText), ' Lina ');
    await t.tap(find.text('SAVE'));
    await frames(t);
    expect(auth.saves, ['Lina']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Nickname updated!'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('rapid saves issue one trimmed write and one confirmation',
      (t) async {
    final pending = Completer<void>();
    auth.save = () => pending.future;
    await editor(t);
    await t.enterText(find.byType(EditableText), ' New ');
    await t.tap(find.text('SAVE'));
    await t.tap(find.text('SAVE'));
    expect(auth.saves, ['New']);
    pending.complete();
    await frames(t);
    expect(auth.saves, ['New']);
    expect(find.text('Nickname updated!'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'nickname validates Unicode code points and allows retry after a failed save',
      (t) async {
    await editor(t);
    await t.enterText(find.byType(EditableText), '🩺' * 256);
    await t.tap(find.text('SAVE'));
    await frames(t);
    expect(auth.saves, isEmpty);
    final valid = '🩺' * 255;
    auth.save = () async => throw StateError('offline');
    await t.enterText(find.byType(EditableText), valid);
    await t.tap(find.text('SAVE'));
    await frames(t);
    expect(
        find.text('Could not save your nickname. Try again.'), findsOneWidget);
    expect(find.text('Nickname updated!'), findsNothing);
    auth.save = () async {};
    await t.tap(find.text('SAVE'));
    await frames(t);
    expect(auth.saves, [valid, valid]);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'an editor opened by a previous login cannot write to the next login',
      (t) async {
    await editor(t);
    auth.switchSession();
    await frames(t);
    expect(find.text('SAVE'), findsNothing);
    expect(find.text('Your active account has changed. Close this editor.'),
        findsOneWidget);
    expect(auth.saves, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('a covered nickname editor closes only itself after saving',
      (t) async {
    final pending = Completer<void>();
    auth.save = () => pending.future;
    await editor(t);
    await t.tap(find.text('SAVE'));
    await t.pump();
    showDialog<void>(
        context: t.element(find.byType(AlertDialog)),
        builder: (_) => const AlertDialog(title: Text('Other dialog')));
    await frames(t);
    pending.complete();
    await frames(t);
    expect(find.text('Other dialog'), findsOneWidget);
    Navigator.of(t.element(find.text('Other dialog'))).pop();
    await frames(t);
    expect(find.byType(AlertDialog), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'profile refresh is retriable without requesting unrelated subject stats',
      (t) async {
    auth.offline = true;
    await t.pumpWidget(app(const ProfilePortal()));
    await frames(t);
    expect(find.text('Profile refresh failed. Retry'), findsOneWidget);
    auth.offline = false;
    await t.tap(find.text('Profile refresh failed. Retry'));
    await frames(t);
    expect(auth.refreshes, 2);
    expect(auth.apiService.reads, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Hungarian probation allows starting practice below the goal on a short screen',
      (t) async {
    await t.binding.setSurfaceSize(const Size(320, 260));
    addTearDown(() => t.binding.setSurfaceSize(null));
    auth.apiService.read = (_) async => status(progress: 6);
    var practice = 0;
    await t.pumpWidget(
        app(ProbationOverlay(onStartRounds: () => practice++), lang: 'hu'));
    await frames(t);
    expect(find.text('6 / 10 helyes válasz'), findsOneWidget);
    final button = find.text('Gyakorlás indítása');
    await t.ensureVisible(button);
    await t.tap(button);
    expect(practice, 1);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'mission uses weighted subject records and the server receipt and opens practice once',
      (t) async {
    auth.apiService.read = (path) async => path == ApiEndpoints.statsSummary
        ? [
            {'total_answered': 2, 'correct_answered': 2},
            {'total_answered': 8, 'correct_answered': 1}
          ]
        : status(progress: 10);
    await stats.fetchSummary();
    var back = 0;
    var practice = 0;
    await t.pumpWidget(app(MissionControlView(
        onBack: () => back++, onStartRounds: () => practice++)));
    await frames(t);
    expect(find.text('Subject responses: 10 · 30% correct'), findsOneWidget);
    expect(find.text('Earn 250 more XP for next Rank'), findsNothing);
    await t.tap(find.text('Start practice'));
    expect([practice, back], [1, 0]);
    final button = find.text('Confirm daily rounds');
    await t.ensureVisible(button);
    await t.tap(button);
    await frames(t);
    expect(find.text('Today’s rounds are complete.'), findsOneWidget);
    expect(auth.refreshes, 0);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'mission offers retry for subject summary and distinguishes empty results',
      (t) async {
    auth.apiService.read = (path) async {
      if (path == ApiEndpoints.statsSummary) throw StateError('offline');
      return status();
    };
    await stats.fetchSummary();
    await t.pumpWidget(app(MissionControlView(onBack: () {})));
    await frames(t);
    final button = find.text('Could not load subject results. Retry');
    await t.ensureVisible(button);
    auth.apiService.read = (_) async => [];
    await t.tap(button);
    await frames(t);
    expect(find.text('No recorded subject responses yet.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  test(
      'sync coalesces taps and ignores an older GET after accepting the receipt',
      () async {
    final read = Completer<dynamic>();
    auth.apiService.read = (_) => read.future;
    rank = RankProvider(auth);
    addTearDown(rank.dispose);
    final first = rank.fetchStatus();
    await Future<void>.delayed(Duration.zero);
    final pending = Completer<dynamic>();
    auth.apiService.write = () => pending.future;
    final a = rank.syncCompletedRounds();
    final b = rank.syncCompletedRounds();
    pending.complete(status(progress: 10, done: true, strikes: 2));
    expect(await Future.wait([a, b]), [true, true]);
    read.complete(status(strikes: 4));
    await first;
    expect(auth.apiService.writes.length, 1);
    expect(rank.malpracticeStrikes, 2);
    expect(rank.hasDoneRoundsToday, isTrue);
    expect(auth.refreshes, 0);
  });
  test('a late successful sync cannot follow the same user into a fresh login',
      () async {
    rank = RankProvider(auth);
    addTearDown(rank.dispose);
    await rank.fetchStatus();
    final pending = Completer<dynamic>();
    auth.apiService.write = () => pending.future;
    final sync = rank.syncCompletedRounds();
    await Future<void>.delayed(Duration.zero);
    auth.switchSession();
    pending.complete(status(done: true));
    expect(await sync, isFalse);
    expect(rank.hasDoneRoundsToday, isFalse);
    expect(auth.refreshes, 0);
  });
  test(
      'legacy success without today’s date does not credit an incomplete shift',
      () async {
    rank = RankProvider(auth);
    addTearDown(rank.dispose);
    await rank.fetchStatus();
    auth.apiService.write = () async => {
          'status': 'success',
          'data': {
            'rank': 'resident',
            'malpracticeStrikes': 3,
            'lastRoundsDate': '2001-01-01T00:00:00Z'
          }
        };
    expect(await rank.syncCompletedRounds(), isFalse);
    expect(rank.hasDoneRoundsToday, isFalse);
    expect(auth.refreshes, 0);
  });
  test(
      'a transient status error is recoverable and malformed progress is rejected',
      () async {
    rank = RankProvider(auth);
    addTearDown(rank.dispose);
    auth.apiService.read = (_) async => status(progress: 11);
    await rank.fetchStatus();
    expect(rank.statusFailed, isTrue);
    expect(rank.roundsProgress, isNull);
    auth.apiService.read = (_) async => status(progress: 8);
    await rank.fetchStatus();
    expect(rank.statusFailed, isFalse);
    expect(rank.roundsProgress, 8);
  });
  test(
      'UTC rollover hides yesterday’s receipt and submits the displayed server day',
      () async {
    var clock = DateTime.utc(2026, 5, 1, 23, 59);
    auth.apiService.read =
        (_) async => status(progress: 10, done: true, studyDay: day(clock));
    rank = RankProvider(auth, now: () => clock);
    addTearDown(rank.dispose);
    await rank.fetchStatus();
    expect(rank.hasDoneRoundsToday, isTrue);
    clock = DateTime.utc(2026, 5, 2);
    expect(rank.hasDoneRoundsToday, isFalse);
    auth.apiService.read = (_) async => status(studyDay: '2026-05-03');
    await rank.fetchStatus();
    auth.apiService.write =
        () async => status(done: false, studyDay: '2026-05-03');
    expect(await rank.syncCompletedRounds(), isFalse);
    expect(auth.apiService.writes.single, {'studyDay': '2026-05-03'});
  });
}
