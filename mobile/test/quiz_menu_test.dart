import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/widgets/quiz/quiz_menu.dart';
import 'package:arbor_med/services/stats_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:async';

// Mock HttpOverrides to prevent network calls
class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool get autoUncompress => true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

// Mock AuthProvider (needed by StatsProvider)
class MockAuthProvider extends AuthProvider {
  @override
  bool get isInitialized => true;
  @override
  bool get isAuthenticated => true;
}

// Mock StatsProvider to inject test data
class MockStatsProvider extends StatsProvider {
  MockStatsProvider(super.auth);

  Quote? _mockQuote;

  @override
  Quote? get currentQuote => _mockQuote;

  void setQuote(Quote? quote) {
    _mockQuote = quote;
    notifyListeners();
  }

  @override
  Future<void> fetchCurrentQuote() async {
    // No-op for test
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  Widget createWidgetUnderTest(MockStatsProvider statsProvider, {String locale = 'en'}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StatsProvider>.value(value: statsProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hu'),
        ],
        locale: Locale(locale),
        home: Scaffold(
          body: QuizMenuWidget(
            onSystemSelected: (_, __) {},
          ),
        ),
      ),
    );
  }

  testWidgets('QuizMenu displays default title when no quote is loaded', (WidgetTester tester) async {
    final mockStats = MockStatsProvider(MockAuthProvider());
    mockStats.setQuote(null);

    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle(); // Allow async tasks to complete

    expect(find.text('Study Break'), findsOneWidget); 
  });

  testWidgets('QuizMenu displays Custom English Title from API', (WidgetTester tester) async {
    final mockStats = MockStatsProvider(MockAuthProvider());
    final customQuote = Quote(
      id: 1,
      textEn: 'Test Quote',
      textHu: '',
      author: 'Tester',
      titleEn: 'Custom Title',
      titleHu: '',
      iconName: 'menu_book_rounded',
    );
    mockStats.setQuote(customQuote);

    await tester.pumpWidget(createWidgetUnderTest(mockStats));
    await tester.pumpAndSettle();

    expect(find.text('Custom Title'), findsOneWidget);
  });

  testWidgets('QuizMenu displays Custom Hungarian Title when locale is HU', (WidgetTester tester) async {
    final mockStats = MockStatsProvider(MockAuthProvider());
    final customQuote = Quote(
      id: 1,
      textEn: 'Test Quote',
      textHu: 'Teszt Idézet',
      author: 'Tester',
      titleEn: 'Custom Title',
      titleHu: 'Egyéni Cím', 
      iconName: 'menu_book_rounded',
    );
    mockStats.setQuote(customQuote);

    await tester.pumpWidget(createWidgetUnderTest(mockStats, locale: 'hu'));
    await tester.pumpAndSettle();

    expect(find.text('Egyéni Cím'), findsOneWidget);
  });

  testWidgets('QuizMenu falls back to English Title if Hungarian is missing', (WidgetTester tester) async {
    final mockStats = MockStatsProvider(MockAuthProvider());
    final customQuote = Quote(
      id: 1,
      textEn: 'Test Quote',
      textHu: 'Teszt Idézet',
      author: 'Tester',
      titleEn: 'Fallback Title',
      titleHu: '', // Empty HU title
      iconName: 'menu_book_rounded',
    );
    mockStats.setQuote(customQuote);

    await tester.pumpWidget(createWidgetUnderTest(mockStats, locale: 'hu'));
    await tester.pumpAndSettle();

    expect(find.text('Fallback Title'), findsOneWidget);
  });
}
