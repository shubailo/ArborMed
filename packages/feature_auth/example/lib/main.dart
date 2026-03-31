import 'package:flutter/material.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  
  // For UI example, we don't start Firebase to avoid crashes in isolation without configs
  // We just provide the AuthService which might crash if methods are called, but UI renders.
  final authService = AuthService();
  getIt.registerLazySingleton<AuthService>(() => authService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeService>()),
        ChangeNotifierProvider(create: (_) => getIt<AudioProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<LocaleProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<AuthService>()),
      ],
      child: const AuthExampleApp(),
    ),
  );
}

class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Feature Example',
      theme: CozyTheme.lightTheme,
      home: const RoleSelectionScreen(),
    );
  }
}
