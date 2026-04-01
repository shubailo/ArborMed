import 'package:flutter/material.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';

class FakeAuthContract implements AuthContract {
  @override AuthState get authState => AuthState.authenticated;
  @override Stream<AuthState> get authStateStream => Stream.value(AuthState.authenticated);
  @override String? get currentUserId => 'test_admin_id';
  @override String? get authToken => 'fake_token';
  @override String? get userRole => 'admin';
  @override Future<void> login(String identifier, String password) async {}
  @override Future<void> logout() async {}
  @override Future<void> register(String email, String password, {String? username, String? displayName}) async {}
  @override Future<void> verifyEmail(String email, String otp) async {}
  @override Future<void> requestOTP(String email) async {}
  @override Future<void> resetPassword(String email, String otp, String newPassword) async {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  getIt.registerLazySingleton<AuthContract>(() => FakeAuthContract());

  final db = DatabaseService();
  await db.init();
  
  final adminService = AdminService(dbService: db);
  getIt.registerSingleton<AdminService>(adminService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeService>()),
        ChangeNotifierProvider(create: (_) => getIt<AudioProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<LocaleProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<AdminService>()),
      ],
      child: const AdminExampleApp(),
    ),
  );
}

class AdminExampleApp extends StatelessWidget {
  const AdminExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Feature Example',
      theme: CozyTheme.light,
      home: const AdminDashboardScreen(),
    );
  }
}
