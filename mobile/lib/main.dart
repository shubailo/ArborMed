import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/student/dashboard_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'services/shop_provider.dart';
import 'services/social_provider.dart';
import 'services/stats_provider.dart';

import 'theme/cozy_theme.dart';

import 'services/audio_provider.dart';
import 'services/notification_provider.dart';
import 'services/question_cache_service.dart';
import 'services/sync_service.dart';

import 'dart:ui'; // Required for PointerDeviceKind
import 'package:arbor_med/generated/l10n/app_localizations.dart';

import 'services/theme_service.dart';
import 'theme/palettes/light_palette.dart';
import 'theme/palettes/dark_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🏥 Initialize Local-First Services
  SyncService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
        ChangeNotifierProvider(create: (_) => ThemeService()), // 🎨 Theme Service
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..tryAutoLogin(), // 🔑 Auto-login on app start
        ),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (context, auth, audio) => audio!..updateAuthState(auth.isAuthenticated),
        ),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StatsProvider>(
          create: (context) => StatsProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous ?? StatsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous ?? NotificationProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, QuestionCacheService>(
          create: (context) => QuestionCacheService(Provider.of<AuthProvider>(context, listen: false).apiService),
          update: (context, auth, previous) => previous ?? QuestionCacheService(auth.apiService),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeService>(
        builder: (context, localeProvider, themeService, child) => MaterialApp(
          title: 'Arbor Med',
          theme: CozyTheme.create(LightPalette()), 
          darkTheme: CozyTheme.create(DarkPalette()),
          themeMode: themeService.themeMode,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hu'),
          ],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          },
          ),
          onGenerateRoute: (settings) {
          Widget builder;
          switch (settings.name) {
            case '/':
              builder = Consumer<AuthProvider>(
                builder: (ctx, auth, _) {
                  // 🔄 Show loading screen while checking for saved credentials
                  if (!auth.isInitialized) {
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading...', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // ✅ Auto-login complete, show appropriate screen
                  if (auth.isAuthenticated) {
                    final user = auth.user;
                    if (user != null && !user.isEmailVerified) {
                      return VerificationScreen(email: user.email ?? '');
                    }
                    return user?.role == 'admin' 
                      ? const AdminShell() 
                      : const DashboardScreen();
                  }
                  return const LoginScreen();
                }
              );
              break;
            case '/login':
              builder = const LoginScreen();
              break;
            case '/game':
              builder = const DashboardScreen();
              break;
            case '/admin':
              builder = const AdminShell();
              break;
            default:
              builder = const LoginScreen();
          }
          return MaterialPageRoute(
            builder: (ctx) => builder,
            settings: settings, // Explicitly pass settings to fix Web route assertion
          );
          },
        ),
      ),
    );
  }
}
