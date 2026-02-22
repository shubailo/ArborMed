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
import 'screens/auth/initial_splash_screen.dart';

import 'services/shop_provider.dart';
import 'services/social_provider.dart';
import 'services/stats_provider.dart';

import 'theme/cozy_theme.dart';

import 'services/audio_provider.dart';
import 'services/notification_provider.dart';
import 'services/question_cache_service.dart';

import 'dart:ui';
import 'package:arbor_med/generated/l10n/app_localizations.dart';

import 'services/theme_service.dart';
import 'theme/palettes/light_palette.dart';
import 'theme/palettes/dark_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LocaleProvider()..loadSavedLocale()),
        ChangeNotifierProvider(
            create: (_) => ThemeService()),
        ChangeNotifierProvider(
            create: (_) =>
              AuthProvider()..tryAutoLogin(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ShopProvider>(
          create: (_) => ShopProvider(),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? ShopProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (context, auth, audio) =>
              audio!..updateAuthState(
                auth.isAuthenticated, 
                isAdmin: auth.user?.role == 'admin',
              ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SocialProvider>(
          create: (_) => SocialProvider(),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? SocialProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, StatsProvider>(
          create: (context) =>
              StatsProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? StatsProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminUserProvider>(
          create: (context) =>
              AdminUserProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? AdminUserProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminQuestionProvider>(
          create: (context) =>
              AdminQuestionProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? AdminQuestionProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TopicProvider>(
          create: (context) =>
              TopicProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? TopicProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminContentProvider>(
          create: (context) =>
              AdminContentProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? AdminContentProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? NotificationProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, QuestionCacheService>(
          create: (context) => QuestionCacheService(
              Provider.of<AuthProvider>(context, listen: false).apiService),
          update: (context, auth, previous) =>
              previous ?? QuestionCacheService(auth.apiService),
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
            
            // Helper to wrap routes with Auth Logic
            Widget authGuard(Widget protectedChild) {
              return Consumer<AuthProvider>(builder: (ctx, auth, _) {
                if (!auth.isInitialized) {
                  return const InitialSplashScreen();
                }

                if (auth.isAuthenticated) {
                  final user = auth.user;
                  if (user != null && !user.isEmailVerified) {
                    return VerificationScreen(email: user.email ?? '');
                  }
                  return protectedChild;
                }
                return const LoginScreen();
              });
            }

            switch (settings.name) {
              case '/':
                // The root route handles its own logic to choose between admin/student
                builder = Consumer<AuthProvider>(builder: (ctx, auth, _) {
                  if (!auth.isInitialized) return const InitialSplashScreen();
                  
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
                });
                break;
              case '/login':
                builder = const LoginScreen();
                break;
              case '/game':
                builder = authGuard(const DashboardScreen());
                break;
              case '/admin':
                builder = authGuard(const AdminShell());
                break;
              default:
                builder = const LoginScreen();
            }
            return MaterialPageRoute(
              builder: (ctx) => builder,
              settings:
                  settings, // Explicitly pass settings to fix Web route assertion
            );
          },
        ),
      ),
    );
  }
}
