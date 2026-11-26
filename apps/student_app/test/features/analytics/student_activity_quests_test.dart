import 'dart:async';
import 'dart:convert';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/analytics/widgets/activity_chart.dart';
import 'package:arbor_med/features/analytics/widgets/analytics_portal.dart';
import 'package:arbor_med/features/profile/models/quest.dart';
import 'package:arbor_med/features/profile/providers/quest_provider.dart';
import 'package:arbor_med/features/profile/widgets/activity_view.dart';
import 'package:arbor_med/features/profile/widgets/quests/quest_list.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends Fake implements ApiService {
  late Future<dynamic> Function(String) read;
  late Future<dynamic> Function(Map<String, dynamic>) claim;
  final paths = <String>[];
  @override
  Future<dynamic> get(String endpoint) {
    paths.add(endpoint);
    return read(endpoint);
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> data) => claim(data);
}

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  final _Api apiService = _Api();
  @override
  User? user = User.fromJson({'id': 1});
  int? balance;
  @override
  int sessionRevision = 0;
  void switchTo(int? id) {
    if (user?.id != id) sessionRevision++;
    user = id == null ? null : User.fromJson({'id': id});
    notifyListeners();
  }

  @override
  void updateCoinBalance(int value) {
    balance = value;
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
  late _Auth auth;
  late _Api api;
  late QuestProvider quests;
  late StatsProvider stats;
  String today() => DateTime.now().toUtc().toIso8601String().split('T').first;
  Map<String, dynamic> daily(
          {String status = 'completed', int target = 5, String? day}) =>
      {
        'date': day ?? today(),
        'quests': [
          {
            'id': 'daily_2',
            'title': 'Practice',
            'titleHu': 'Gyakorlás',
            'description': 'Answer five',
            'descriptionHu': 'Öt válasz',
            'targetCount': target,
            'currentCount': 5,
            'rewardTokens': 20,
            'type': 'correctAnswers',
            'status': status
          }
        ]
      };
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = _Auth();
    api = auth.apiService;
    api.read = (_) async => daily();
    api.claim =
        (_) async => {'date': today(), 'newBalance': 120, 'awardedTokens': 20};
    quests = QuestProvider(auth);
    stats = StatsProvider(auth);
  });
  tearDown(() {
    quests.dispose();
    stats.dispose();
    auth.dispose();
  });
  Widget app(Widget home, {String lang = 'en'}) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: quests),
            ChangeNotifierProvider.value(value: stats),
            ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ],
          child: MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: home)));
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
  }

  test(
      'a replay returns zero awarded tokens and caches its claimed state before going offline',
      () async {
    await quests.fetchQuests();
    api.claim = (request) async {
      expect(request['date'], today());
      return {'newBalance': 120, 'awardedTokens': 0, 'date': today()};
    };
    expect(await quests.claimQuest('daily_2'), 0);
    expect(auth.balance, 120);
    api.read = (_) async => throw StateError('offline');
    final reopened = QuestProvider(auth);
    addTearDown(reopened.dispose);
    await reopened.fetchQuests();
    expect(reopened.quests.single.status, QuestStatus.claimed);
  });

  test('a late claim cannot affect the same account after logout and re-entry',
      () async {
    await quests.fetchQuests();
    final reply = Completer<dynamic>();
    api.claim = (_) => reply.future;
    final result = quests.claimQuest('daily_2');
    auth.switchTo(null);
    auth.switchTo(1);
    reply.complete({'newBalance': 120, 'awardedTokens': 20, 'date': today()});
    expect(await result, 0);
    expect(auth.balance, isNull);
    expect(quests.quests, isEmpty);
  });

  test(
      'a late daily read cannot reinstate a completed button after a durable claim',
      () async {
    await quests.fetchQuests();
    final old = Completer<dynamic>();
    api.read = (_) => old.future;
    final reading = quests.fetchQuests();
    final claimed = quests.claimQuest('daily_2');
    old.complete(daily());
    await Future.wait<dynamic>([reading, claimed]);
    expect(quests.quests.single.status, QuestStatus.claimed);
  });

  test(
      'a malformed or previous-day refresh cannot replace a valid offline snapshot',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'daily_quests_1', jsonEncode(daily(status: 'claimed')));
    for (final bad in [daily(target: 0), daily(day: '2000-01-01')]) {
      final p = QuestProvider(auth);
      api.read = (_) async => bad;
      await p.fetchQuests();
      expect(p.quests.single.status, QuestStatus.claimed);
      expect(
          jsonDecode(prefs.getString('daily_quests_1')!)['quests'][0]
              ['targetCount'],
          5);
      p.dispose();
    }
  });

  testWidgets(
      'opening the quest list fetches once and a failed refresh is retryable',
      (t) async {
    api.read = (_) async => throw StateError('offline');
    await t.pumpWidget(app(const QuestList()));
    await frames(t);
    expect(find.text('Could not refresh daily quests.'), findsOneWidget);
    api.read = (_) async => daily();
    await t.tap(find.text('Retry'));
    await frames(t);
    expect(find.text('Practice'), findsOneWidget);
    expect(api.paths, ['/quests/daily', '/quests/daily']);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a pending reward disables further claims and a lost receipt is reconciled',
      (t) async {
    final reply = Completer<dynamic>();
    var posts = 0;
    api.claim = (_) {
      posts++;
      return reply.future;
    };
    await t.pumpWidget(app(const QuestList()));
    await frames(t);
    final button = t.widget<CozyButton>(find.byType(CozyButton));
    button.onPressed!();
    await t.pump();
    expect(t.widget<CozyButton>(find.byType(CozyButton)).enabled, isFalse);
    expect(await quests.claimQuest('daily_2'), 0);
    expect(posts, 1);
    api.read = (_) async => daily(status: 'claimed');
    reply.completeError(StateError('offline'));
    await frames(t);
    expect(find.textContaining('Could not confirm the reward'), findsOneWidget);
    expect(find.byType(CozyButton), findsNothing);
    expect(find.textContaining('You earned'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a mounted quest list refreshes at the UTC day boundary and cancels the timer when closed',
      (t) async {
    await t.pumpWidget(app(const QuestList()));
    await frames(t);
    expect(api.paths.length, 1);
    final now = DateTime.now().toUtc();
    final untilMidnight =
        DateTime.utc(now.year, now.month, now.day + 1).difference(now);
    await t.pump(untilMidnight + const Duration(seconds: 2));
    await frames(t);
    expect(api.paths.length, 2);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(days: 1));
    expect(api.paths.length, 2);
  });

  testWidgets('Hungarian titles survive the daily snapshot cache', (t) async {
    await quests.fetchQuests();
    quests.dispose();
    quests = QuestProvider(auth);
    api.read = (_) async => throw StateError('offline');
    await t.pumpWidget(app(const QuestList(), lang: 'hu'));
    await frames(t);
    expect(find.text('Gyakorlás'), findsOneWidget);
    expect(find.text('Öt válasz'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'the calendar places June 1 on Monday and labels the server calendar day',
      (t) async {
    final rows = [
      ActivityData(
          date: DateTime.utc(2026, 5, 31, 10),
          calendarDate: '2026-06-01',
          count: 4,
          correctCount: 3)
    ];
    await t.pumpWidget(
        app(ActivityChart(data: rows, timeframe: ActivityTimeframe.month)));
    await frames(t);
    final tip = find.byTooltip('Jun 1\n4 questions');
    expect(tip, findsOneWidget);
    final grid = t.getRect(find.byType(GridView));
    final width = (grid.width - 36) / 7;
    expect(t.getTopLeft(tip).dx, closeTo(grid.left + width + 6, 1));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('two mounted activity views retain their own selected period',
      (t) async {
    final date = DateTime.now().toIso8601String().split('T').first;
    api.read = (path) async => [
          {
            'date': date,
            'count': path.contains('timeframe=month') ? 3 : 7,
            'correct_count': 0
          }
        ];
    await t.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(app(const Row(children: [
      Expanded(child: ActivityView()),
      Expanded(child: ActivityView())
    ])));
    await frames(t);
    await t.tap(find.text('MONTH').first);
    await frames(t);
    expect(
        t
            .widgetList<ActivityChart>(find.byType(ActivityChart))
            .map((c) => c.data.single.count),
        [3, 7]);
    expect(find.text('Review 3 failed questions.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'an activity request failure is distinct from an empty period and can be retried',
      (t) async {
    api.read = (_) async => throw StateError('offline');
    await t.pumpWidget(app(const ActivityView()));
    await frames(t);
    expect(
        find.text('Could not load activity for this period.'), findsOneWidget);
    api.read = (_) async => [];
    await t.tap(find.text('Retry'));
    await frames(t);
    expect(find.text('No activity data for this period.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a late weekly result cannot appear under the daily tab and two hours count as one active day',
      (t) async {
    final weekly = Completer<dynamic>();
    final date = DateTime.now().toIso8601String().split('T').first;
    api.read = (path) async => path.contains('timeframe=week')
        ? weekly.future
        : [
            for (final hour in [10, 12])
              {
                'date': '${date}T$hour:00:00Z',
                'calendar_date': date,
                'count': 3,
                'correct_count': 3
              }
          ];
    await t.pumpWidget(app(const ActivityView()));
    await frames(t);
    await t.tap(find.text('DAY'));
    await frames(t);
    weekly.complete([
      {'date': date, 'count': 99, 'correct_count': 0}
    ]);
    await frames(t);
    expect(
        t
            .widget<ActivityChart>(find.byType(ActivityChart))
            .data
            .map((r) => r.count),
        [3, 3]);
    expect(find.text('Active days'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'analytics displays only returned subjects and the activity tab leaves subject detail',
      (t) async {
    api.read = (path) async {
      if (path == ApiEndpoints.statsSummary) {
        return [
          {'slug': 'pathology', 'name_en': 'Pathology'}
        ];
      }
      if (path.contains('/subject/')) return [];
      if (path.startsWith(ApiEndpoints.statsActivity)) return [];
      return daily();
    };
    await t.pumpWidget(app(const AnalyticsPortal()));
    await frames(t);
    expect(find.text('PATHOLOGY'), findsOneWidget);
    expect(find.text('PHARMACOLOGY'), findsNothing);
    expect(api.paths, [ApiEndpoints.statsSummary]);
    await t.tap(find.text('PATHOLOGY'));
    await frames(t);
    expect(api.paths.where((p) => p.contains('/subject/')).length, 1);
    expect(
        find.text('No sections available for this subject.'), findsOneWidget);
    await t.tap(find.text('ACTIVITY'));
    await frames(t);
    expect(find.byType(ActivityView), findsOneWidget);
    await t.tap(find.text('DAILY QUESTS'));
    await frames(t);
    expect(api.paths.where((p) => p.contains('timeframe=quests')), isEmpty);
    expect(find.text('Practice'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'subject summary errors allow retry and a successful empty list stays empty',
      (t) async {
    api.read = (_) async => throw StateError('offline');
    await t.pumpWidget(app(const AnalyticsPortal()));
    await frames(t);
    expect(find.text('Could not load subject mastery.'), findsOneWidget);
    api.read = (_) async => [];
    await t.tap(find.text('Retry'));
    await frames(t);
    expect(find.text('No subjects available.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
