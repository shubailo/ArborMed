import 'package:flutter/material.dart';
import 'package:feature_game/feature_game.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';

class FakeAuthContract implements AuthContract {
  @override AuthState get authState => AuthState.authenticated;
  @override Stream<AuthState> get authStateStream => Stream.value(AuthState.authenticated);
  @override String? get currentUserId => 'test_user_id';
  @override String? get authToken => 'fake_token';
  @override String? get userRole => 'student';

  @override Future<void> login(String identifier, String password) async {}
  @override Future<void> logout() async {}
  @override Future<void> register(String email, String password, {String? username, String? displayName}) async {}
  @override Future<void> verifyEmail(String email, String otp) async {}
  @override Future<void> requestOTP(String email) async {}
  @override Future<void> resetPassword(String email, String otp, String newPassword) async {}
}

class FakeStudentContract implements StudentContract {
  @override Future<int> getCoins() async => 500;
  @override Future<void> addCoins(int amount) async {}
  @override Future<void> addXP(int amount) async {}
  @override Future<int> getXP() async => 1000;
  @override Future<int> getLevel() async => 5;
  @override Future<void> fetchSummary() async {}
  @override Future<void> fetchActivity(String timeframe) async {}
  @override Future<void> fetchReadiness() async {}
  @override Future<void> fetchSmartReview() async {}
  @override List<SubjectMastery> get subjectMastery => [];
  @override List<ActivityData> get activityData => [];
  @override List<SmartReviewItem> get smartReview => [];
  @override ReadinessScore? get readinessScore => null;
  @override Future<int> getMistakeCount() async => 0;
  @override Future<List<int>> getIncorrectQuestionIds() async => [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  
  getIt.registerLazySingleton<AuthContract>(() => FakeAuthContract());
  getIt.registerLazySingleton<StudentContract>(() => FakeStudentContract());

  // Setup memory DB
  final dbService = DatabaseService();
  await dbService.init();
  
  final gameService = GameService(dbService.db);
  getIt.registerSingleton<GameContract>(gameService);
  getIt.registerSingleton<GameService>(gameService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeService>()),
        ChangeNotifierProvider(create: (_) => getIt<AudioProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<LocaleProvider>()),
      ],
      child: const GameExampleApp(),
    ),
  );
}

class GameExampleApp extends StatelessWidget {
  const GameExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Feature Example',
      theme: CozyTheme.light,
      home: const StudyRoomScreen(),
    );
  }
}
