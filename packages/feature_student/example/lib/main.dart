import 'package:flutter/material.dart';
import 'package:feature_student/feature_student.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';

// Fake auth contract for isolation
class FakeAuthContract implements AuthContract {
  @override AuthState get authState => AuthState.authenticated;
  @override Stream<AuthState> get authStateStream => Stream.value(AuthState.authenticated);
  @override String? get currentUserId => 'test_user_id';
  @override String? get authToken => 'fake_token';
  @override String? get userRole => 'student';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  
  getIt.registerLazySingleton<AuthContract>(() => FakeAuthContract());

  // Init in-memory DB or mock for UI testing
  final db = DatabaseService();
  await db.init();
  
  final studentService = StudentService(db.isar);
  getIt.registerSingleton<StudentService>(studentService);
  getIt.registerSingleton<StudentContract>(studentService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeService>()),
        ChangeNotifierProvider(create: (_) => getIt<AudioProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<LocaleProvider>()),
      ],
      child: const StudentExampleApp(),
    ),
  );
}

class StudentExampleApp extends StatelessWidget {
  const StudentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Feature Example',
      theme: CozyTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Student Dashboard')),
        body: const StudentProfileScreen(),
      ),
    );
  }
}
