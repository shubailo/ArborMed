import 'package:flutter/material.dart';
import 'package:feature_student/feature_student.dart';
import 'package:arbormed_core/arbormed_core.dart' hide QuestType;
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:go_router/go_router.dart';

// Fake auth contract for isolation
class FakeAuthContract implements AuthContract {
  @override AuthState get authState => AuthState.authenticated;
  @override Stream<AuthState> get authStateStream => Stream.value(AuthState.authenticated);
  @override String? get currentUserId => 'test_user_id';
  @override String? get authToken => 'fake_token';
  @override String? get userRole => 'student';

  @override Future<void> login(String id, String pw) async {}
  @override Future<void> logout() async {}
  @override Future<void> register(String e, String p, {String? username, String? displayName}) async {}
  @override Future<void> verifyEmail(String e, String o) async {}
  @override Future<void> requestOTP(String e) async {}
  @override Future<void> resetPassword(String e, String o, String n) async {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  
  getIt.registerLazySingleton<AuthContract>(() => FakeAuthContract());

  // Init in-memory DB or mock for UI testing
  final dbService = DatabaseService();
  await dbService.init();
  
  final studentService = StudentService(dbService.db);
  getIt.registerSingleton<StudentService>(studentService);
  getIt.registerSingleton<StudentContract>(studentService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ThemeService>()),
        ChangeNotifierProvider.value(value: getIt<AudioProvider>()),
        ChangeNotifierProvider.value(value: getIt<LocaleProvider>()),
      ],
      child: const StudentExampleApp(),
    ),
  );
}

class StudentExampleApp extends StatelessWidget {
  const StudentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ...StudentRoutes.routes,
        // Mock other feature routes for buttons to work in isolation
        GoRoute(
          path: '/room',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Study Room Mock')),
            body: const Center(child: Text('Room Feature would be here.')),
          ),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Quiz Engine Mock')),
            body: Center(child: Text('Quiz Feature for topic: ${state.uri.queryParameters['topic']}')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Student Feature Example',
      theme: CozyTheme.light,
      darkTheme: CozyTheme.dark,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
