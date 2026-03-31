import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import 'di/service_locator.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Dependency Injection
  await setupServiceLocator();
  
  // 2. Database Init
  final dbService = GetIt.I<DatabaseService>();
  await dbService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GetIt.I<ThemeService>()),
        ChangeNotifierProvider.value(value: GetIt.I<AudioProvider>()),
        ChangeNotifierProvider.value(value: GetIt.I<LocaleProvider>()),
      ],
      child: const ArborMedApp(),
    ),
  );
}

class ArborMedApp extends StatelessWidget {
  const ArborMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      title: 'ArborMed',
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: CozyTheme.light,
      darkTheme: CozyTheme.dark,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Localization
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('hu', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Navigation
      routerConfig: AppRouter.createRouter([]),
    );
  }
}
