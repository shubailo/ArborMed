import 'package:feature_auth/feature_auth.dart';
import 'package:feature_student/feature_student.dart';
import 'package:feature_game/feature_game.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  final db = DatabaseService();
  getIt.registerSingleton<DatabaseService>(db);
  await db.init();
  
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());

  // Feature Services
  final authService = AuthService();
  getIt.registerLazySingleton<AuthService>(() => authService);
  getIt.registerLazySingleton<AuthContract>(() => authService);

  // Student
  final studentService = StudentService(db.isar);
  getIt.registerSingleton<StudentContract>(studentService);
  getIt.registerSingleton<StudentService>(studentService);

  // Game
  getIt.registerLazySingleton<FurnitureService>(() => FurnitureService(db.isar));
}
