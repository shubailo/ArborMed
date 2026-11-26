import 'package:arbor_med/features/analytics/models/performance.dart';
import 'package:arbor_med/screens/admin/components/user_history_dialog.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'dart:async';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/analytics/widgets/weakness_radar_chart.dart';
import 'package:arbor_med/features/quiz/widgets/quiz_menu.dart';
import 'package:arbor_med/features/quiz/widgets/smart_review_sheet.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends Fake implements ApiService {
  final paths = <String>[];
  late Future<dynamic> Function(String) read;
  @override
  Future<dynamic> get(String path) {
    paths.add(path);
    return read(path);
  }
}

class _Auth extends ChangeNotifier implements AuthProvider {
  @override
  final _Api apiService = _Api();
  @override
  User? user = User.fromJson({'id': 1});
  @override
  int sessionRevision = 0;
  void logInAgain() {
    sessionRevision++;
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
  late List<(String, String)> selections;
  final summary = ApiEndpoints.statsSummary;
  final review = ApiEndpoints.statsSmartReview;
  final readiness = ApiEndpoints.statsReadiness;
  final detail = ApiEndpoints.statsSubject;
  Map<String, dynamic> row(int i) => {
        'slug': 't-$i',
        'topic': 'Topic $i',
        'topicHu': 'Téma $i',
        'score': i,
        'retention': i,
        'daysSince': null,
        'mastery': '75.25'
      };
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    selections = [];
    auth = _Auth();
    stats = StatsProvider(auth);
    auth.apiService.read = (path) async {
      if (path == ApiEndpoints.quizSingleQuote) {
        return {'id': 1, 'text_en': 'Quote'};
      }
      if (path == review) return {'recommendations': []};
      if (path == readiness) return {'overallReadiness': 0, 'breakdown': []};
      return [];
    };
  });
  tearDown(() {
    stats.dispose();
    auth.dispose();
  });
  Widget app(Widget widget, {String lang = 'en'}) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: stats),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AudioProvider>(create: (_) => _Audio()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService())
          ],
          child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: widget)));
  Widget menu() => QuizMenuWidget(
      onSystemSelected: (name, slug) => selections.add((name, slug)));
  Widget sheet() => SmartReviewSheet(
      onReviewSelected: (name, slug) => selections.add((name, slug)));
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump();
  }

  Future<void> hit(WidgetTester t, String label) async {
    final text = find.text(label);
    await t.ensureVisible(text);
    await t.tap(text);
    await frames(t);
  }

  Future<void> small(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(320, 290));
    addTearDown(() => t.binding.setSurfaceSize(null));
  }

  testWidgets(
      'catalog follows API roots, nested sections, locale and original slug',
      (t) async {
    final fallback = auth.apiService.read;
    auth.apiService.read = (path) async {
      if (path == summary) {
        return [
          {'slug': 'new-course', 'name_en': 'New course', 'name_hu': 'Új tárgy'}
        ];
      }
      if (path == '$detail/new-course') {
        return [
          {
            'slug': 'module',
            'name_en': 'Module',
            'name_hu': 'Modul',
            'has_children': true
          }
        ];
      }
      if (path == '$detail/module') {
        return [
          {
            'slug': 'leaf & 2',
            'name_en': 'Clinical section',
            'name_hu': 'Klinikai téma',
            'has_direct_questions': true
          }
        ];
      }
      return fallback(path);
    };
    await t.pumpWidget(app(menu(), lang: 'hu'));
    await frames(t);
    final strings =
        AppLocalizations.of(t.element(find.byType(QuizMenuWidget)))!;
    await hit(t, strings.quizSubjects);
    expect(find.text('Pathology'), findsNothing);
    await hit(t, 'Új tárgy');
    await hit(t, 'Modul');
    await hit(t, 'Klinikai téma');
    expect(selections, [('Klinikai téma', 'leaf & 2')]);
    await hit(t, 'Modul');
    expect(find.text('Új tárgy'), findsOneWidget);
    expect(auth.apiService.paths.where((p) => p.startsWith('$detail/')),
        ['$detail/new-course', '$detail/module']);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'catalog retry and short-screen lazy list handle zero and more than four subjects',
      (t) async {
    await small(t);
    final fallback = auth.apiService.read;
    var reads = 0;
    auth.apiService.read = (path) async {
      if (path != summary) return fallback(path);
      reads++;
      if (reads == 1) throw StateError('offline');
      if (reads == 2) return [];
      return [
        for (int i = 0; i < 60; i++) {'slug': 's-$i', 'name_en': 'Course $i'}
      ];
    };
    await t.pumpWidget(app(menu()));
    await frames(t);
    await hit(t, 'Subjects');
    await hit(t, 'Could not load subject results. Retry');
    expect(find.text('No subjects available.'), findsOneWidget);
    await hit(t, 'Select Subject');
    await hit(t, 'Subjects');
    expect(find.text('Course 59'), findsNothing);
    await t.scrollUntilVisible(find.text('Course 59'), 260,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Course 59'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'section retry preserves the selected root and disables inactive topics',
      (t) async {
    final fallback = auth.apiService.read;
    var attempts = 0;
    auth.apiService.read = (p) async {
      if (p == summary) {
        return [
          {'name_en': 'Renamed', 'slug': 'r / 1', 'has_direct_questions': true}
        ];
      }
      if (p == '$detail/r%20%2F%201') {
        if (++attempts == 1) throw StateError('offline');
        return [
          {
            'name_en': 'No active items',
            'slug': 'empty',
            'has_direct_questions': false
          }
        ];
      }
      return fallback(p);
    };
    await t.pumpWidget(app(menu()));
    await frames(t);
    await hit(t, 'Subjects');
    await hit(t, 'Renamed');
    await hit(t, 'Could not load sections. Retry');
    final tile =
        t.widget<ListTile>(find.widgetWithText(ListTile, 'No active items'));
    expect(tile.onTap, isNull);
    await hit(t, 'Practise this subject');
    expect(selections, [('Renamed', 'r / 1')]);
    expect(attempts, 2);
    await t.pumpWidget(const SizedBox());
  });

  test(
      'review rows preserve an unknown practice date and accept finite PostgreSQL numerics',
      () {
    final parsed = SmartReviewItem.fromJson(
        {...row(1), 'retention': '73.5', 'daysSince': null});
    expect(parsed.daysSince, isNull);
    expect(parsed.retention, 73.5);
    expect(parsed.mastery, 75);
    expect(SmartReviewItem.fromJson({...row(1), 'daysSince': '2.75'}).daysSince,
        2.75);
  });
  test(
      'readiness decodes legacy numerics and isolates malformed or unselectable rows',
      () {
    final parsed = ReadinessScore.fromJson({
      'overallReadiness': '87.5',
      'breakdown': [
        null,
        {'topic': 'No identifier', 'score': 50},
        {...row(2), 'score': 'NaN'},
        {
          ...row(1),
          'score': '87.75',
          'metrics': {'retention': '79.5', 'mastery': '95'}
        }
      ]
    });
    expect(parsed.overall, 87);
    expect(parsed.breakdown.single.slug, 't-1');
    expect(parsed.breakdown.single.retention, 79.5);
    expect(parsed.breakdown.single.mastery, 95);
    expect(
        () => ReadinessScore.fromJson(
            {'overallReadiness': double.infinity, 'breakdown': []}),
        throwsFormatException);
    expect(
        () => ReadinessScore.fromJson({
              'breakdown': [
                {'slug': 'bad', 'score': 120}
              ]
            }),
        throwsFormatException);
  });

  testWidgets(
      'review reads independently and distinguishes empty from failure without duplicate preload requests',
      (t) async {
    final pending = Completer<dynamic>();
    int tries = 0;
    auth.apiService.read = (p) async {
      if (p == readiness) return pending.future;
      if (p == review && ++tries == 1) throw StateError('offline');
      return {'recommendations': []};
    };
    final warm = stats.fetchReadiness();
    await t.pumpWidget(app(sheet()));
    await frames(t);
    expect(auth.apiService.paths.where((p) => p == readiness).length, 1);
    expect(find.text('No topics to review right now.'), findsNothing);
    expect(find.text('Could not load recommendations. Retry'), findsOneWidget);
    pending.complete({'overallReadiness': 0, 'breakdown': []});
    await warm;
    await frames(t);
    expect(find.text('Complete a quiz to see your readiness.'), findsOneWidget);
    await hit(t, 'Could not load recommendations. Retry');
    expect(find.text('No topics to review right now.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'five recommendations remain reachable in Hungarian and use one original topic per selection',
      (t) async {
    await small(t);
    final fallback = auth.apiService.read;
    auth.apiService.read = (p) async => p == review
        ? {
            'recommendations': [
              null,
              {'topic': 'Invalid'},
              for (int i = 1; i <= 5; i++) row(i)
            ]
          }
        : fallback(p);
    await t.pumpWidget(app(menu(), lang: 'hu'));
    await frames(t);
    await hit(t, 'Okos ismétlés');
    await hit(t, 'Téma 5');
    expect(selections, [('Téma 5', 't-5')]);
    expect(find.byType(SmartReviewSheet), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'a stale review sheet and a delayed response cannot start a quiz in a fresh login',
      (t) async {
    final lateRead = Completer<dynamic>();
    final fallback = auth.apiService.read;
    auth.apiService.read =
        (p) async => p == review ? lateRead.future : fallback(p);
    await t.pumpWidget(app(menu()));
    await frames(t);
    await hit(t, 'Smart review');
    auth.logInAgain();
    lateRead.complete({
      'recommendations': [row(1)]
    });
    await frames(t);
    expect(stats.smartReview, isEmpty);
    expect(find.text('Topic 1'), findsNothing);
    expect(selections, isEmpty);
    await hit(t, 'Close');
    expect(find.text('Subjects'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'invalid recommendation payload is retriable and never offers an empty slug',
      (t) async {
    final fallback = auth.apiService.read;
    var invalid = true;
    auth.apiService.read = (p) async => p == review
        ? {
            'recommendations': invalid
                ? [
                    {'slug': '  ', 'topic': 'Broken'}
                  ]
                : [row(1)]
          }
        : fallback(p);
    await t.pumpWidget(app(sheet()));
    await frames(t);
    expect(find.text('Broken'), findsNothing);
    expect(find.text('No topics to review right now.'), findsNothing);
    invalid = false;
    await hit(t, 'Could not load recommendations. Retry');
    await hit(t, 'Topic 1');
    expect(selections, [('Topic 1', 't-1')]);
    expect(find.textContaining('ago'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'one and two studied topics show exact labelled percentages without radar exceptions',
      (t) async {
    for (final count in [1, 2]) {
      final topics = [
        for (int i = 1; i <= count; i++) ReadinessDetail.fromJson(row(i))
      ];
      await t.pumpWidget(app(WeaknessRadarChart(data: topics), lang: 'hu'));
      await frames(t);
      expect(t.takeException(), isNull);
      expect(find.byType(RadarChart), findsNothing);
      expect(find.text('Téma $count · $count%'), findsOneWidget);
    }
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
      'radar uses an absolute percentage scale and shows the six weakest with full labels',
      (t) async {
    final topics = [
      for (final i in [30, 20, 10, 15, 5, 1, 7])
        ReadinessDetail.fromJson(row(i))
    ];
    await t.pumpWidget(app(WeaknessRadarChart(data: topics)));
    await frames(t);
    final chart = t.widget<RadarChart>(find.byType(RadarChart)).data;
    expect(chart.minEntry.value, 0);
    expect(chart.maxEntry.value, 100);
    expect(chart.isMinValueAtCenter, isTrue);
    expect(chart.dataSets.last.dataEntries.map((p) => p.value),
        [1, 5, 7, 10, 15, 20]);
    expect(find.text('1. Topic 1 · 1%'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  test(
      'old recommendations and readiness cannot repopulate a new login for the same student',
      () async {
    final delayedReview = Completer<dynamic>();
    final delayedScore = Completer<dynamic>();
    auth.apiService.read =
        (path) => path == review ? delayedReview.future : delayedScore.future;
    final pending =
        Future.wait([stats.fetchSmartReview(), stats.fetchReadiness()]);
    auth.logInAgain();
    delayedReview.complete({
      'recommendations': [
        {
          'topic': 'A',
          'slug': 'one',
          'retention': 10,
          'mastery': 75,
          'daysSince': 1
        }
      ]
    });
    delayedScore.complete({
      'overallReadiness': 60,
      'breakdown': [
        {'topic': 'A', 'slug': 'one', 'score': 60}
      ]
    });
    await pending;
    expect(stats.smartReview, isEmpty);
    expect(stats.readiness, isNull);
  });

  testWidgets(
      'returning during a detail request cannot replace the next selected subject',
      (t) async {
    final delayed = Completer<dynamic>();
    final fallback = auth.apiService.read;
    auth.apiService.read = (p) async {
      if (p == summary) {
        return [
          {'slug': 'a', 'name_en': 'Course A'},
          {'slug': 'b', 'name_en': 'Course B'}
        ];
      }
      if (p == '$detail/a') return delayed.future;
      if (p == '$detail/b') {
        return [
          {
            'slug': 'unused',
            'name_en': 'Unused',
            'attempts': 0,
            'last_studied': '2026-01-05'
          },
          {
            'slug': 'used',
            'name_en': 'Used',
            'attempts': 1,
            'last_studied': '2026-01-01'
          },
        ];
      }
      return fallback(p);
    };
    await t.pumpWidget(app(menu()));
    await frames(t);
    await hit(t, 'Subjects');
    await hit(t, 'Course A');
    await hit(t, 'Course A');
    await hit(t, 'Course B');
    delayed.complete([
      {'slug': 'late', 'name_en': 'Late A'}
    ]);
    await frames(t);
    expect(find.text('Late A'), findsNothing);
    final used = t.widget<ListTile>(find.widgetWithText(ListTile, 'Used'));
    expect((used.subtitle as Text).data,
        AppLocalizations.of(t.element(find.text('Used')))!.quizLastStudied);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'readiness retries a malformed score while valid recommendations remain usable',
      (t) async {
    bool bad = true;
    auth.apiService.read = (p) async {
      if (p == review) {
        return {
          'recommendations': [row(1)]
        };
      }
      return {
        'overallReadiness': 74,
        'breakdown': [
          bad ? {'slug': 'unknown'} : {...row(1), 'score': 74}
        ]
      };
    };
    await t.pumpWidget(app(sheet()));
    await frames(t);
    expect(find.text('Topic 1'), findsOneWidget);
    bad = false;
    await hit(t, 'Could not load readiness. Retry');
    expect(find.text('Readiness 74%'), findsOneWidget);
    expect(auth.apiService.paths.where((p) => p == review).length, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'admin history consumes the bilingual review contract when one recommendation is damaged',
      (t) async {
    auth.apiService.read = (p) async => p.endsWith('/analytics')
        ? {
            'readiness': {'overallReadiness': 61},
            'smartReview': [null, row(1)]
          }
        : [];
    final admin = AdminUserProvider(auth);
    addTearDown(admin.dispose);
    await t.pumpWidget(app(
        ChangeNotifierProvider<AdminUserProvider>.value(
            value: admin,
            child: UserHistoryDialog(
                user: UserPerformance.fromJson(
                    {'id': 4, 'created_at': '2025-01-01'}))),
        lang: 'hu'));
    await frames(t);
    expect(t.takeException(), isNull);
    expect(find.text('Téma 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
