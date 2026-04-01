import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';

import 'package:feature_auth/feature_auth.dart';
import 'package:feature_student/feature_student.dart';
import 'package:feature_quiz/feature_quiz.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_ecg/feature_ecg.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:feature_social/feature_social.dart';

import 'di/service_locator.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Dependency Injection
  await setupServiceLocator();
  
  // 2. Database already initialized inside setupServiceLocator

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

class ArborMedApp extends StatefulWidget {
  const ArborMedApp({super.key});

  @override
  State<ArborMedApp> createState() => _ArborMedAppState();
}

class _ArborMedAppState extends State<ArborMedApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // 3. Federated Route Collection
    final featureRoutes = [
      ...FeatureAuth.routes,
      ...FeatureStudent.routes,
      ...FeatureQuiz.routes,
      ...FeatureGame.routes,
      ...FeatureECG.routes,
      ...FeatureAdmin.routes,
      ...FeatureSocial.routes,
    ];

    _router = AppRouter.createRouter(featureRoutes, GetIt.I<AuthContract>());
  }

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
      routerConfig: _router,
    );
  }
}
