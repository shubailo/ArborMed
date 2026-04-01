import 'package:flutter/material.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final getIt = GetIt.instance;
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<AudioProvider>(() => AudioProvider());
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  
  final authService = AuthService();
  getIt.registerSingleton<AuthService>(authService);
  getIt.registerSingleton<AuthContract>(authService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeService>()),
        ChangeNotifierProvider(create: (_) => getIt<AudioProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<LocaleProvider>()),
      ],
      child: const AuthExampleApp(),
    ),
  );
}

class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeService>(context);
    
    final router = GoRouter(
      initialLocation: '/auth',
      routes: AuthRoutes.routes,
    );

    return MaterialApp.router(
      title: 'Auth Feature Example',
      theme: CozyTheme.light,
      darkTheme: CozyTheme.dark,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
