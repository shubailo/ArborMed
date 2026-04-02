import 'package:feature_auth/feature_auth.dart';
import 'package:feature_student/feature_student.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_quiz/feature_quiz.dart';
import 'package:feature_ecg/feature_ecg.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:feature_social/feature_social.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  final dbService = DatabaseService();
  await dbService.init(); // Initialize first
  getIt.registerSingleton<DatabaseService>(dbService);
  
  final db = dbService.db;
  getIt.registerSingleton<AppDatabase>(db);

  // Seed database if needed
  final seedingService = DriftSeedingService(db: db);
  await seedingService.seedDatabaseIfNeeded();
  
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());

  // Unified Plugin Registration (Micro-App Architecture)
  FeatureAuth.register(getIt);
  FeatureStudent.register(getIt);
  FeatureQuiz.register(getIt);
  FeatureGame.register(getIt);
  FeatureECG.register(getIt);
  FeatureAdmin.register(getIt);
  FeatureSocial.register(getIt);
}
