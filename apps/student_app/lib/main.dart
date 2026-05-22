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

import 'features/shop/providers/shop_provider.dart';
import 'package:arbor_med/features/social/providers/social_provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/features/profile/providers/quest_provider.dart';


import 'theme/cozy_theme.dart';

import 'services/audio_provider.dart';
import 'services/notification_provider.dart';
import 'features/quiz/providers/question_cache_service.dart';

import 'dart:ui';
import 'package:arbor_med/generated/l10n/app_localizations.dart';

import 'services/theme_service.dart';
import 'theme/palettes/light_palette.dart';
import 'theme/palettes/dark_palette.dart';

import 'services/admin_user_provider.dart';
import 'services/admin_question_provider.dart';
import 'services/admin_content_provider.dart';
import 'features/quiz/providers/topic_provider.dart';
import 'features/profile/providers/rank_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions.apiKey.isNotEmpty) {
    try {
      await Firebase.initializeApp(
        options: firebaseOptions,
      );
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  } else {
    debugPrint("Firebase API Key is missing. Skipping Firebase initialization.");
  }

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
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..tryAutoLogin(),
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
          update: (context, auth, audio) => audio!
            ..updateAuthState(
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
        ChangeNotifierProxyProvider<AuthProvider, QuestProvider>(
          create: (context) =>
              QuestProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            return previous ?? QuestProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminUserProvider>(
          create: (context) => AdminUserProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? AdminUserProvider(auth);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminQuestionProvider>(
          create: (context) => AdminQuestionProvider(
              Provider.of<AuthProvider>(context, listen: false)),
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
          create: (context) => AdminContentProvider(
              Provider.of<AuthProvider>(context, listen: false)),
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
        ChangeNotifierProxyProvider<AuthProvider, RankProvider>(
          create: (context) =>
              RankProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) =>
              previous ?? RankProvider(auth),
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
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) {
                Widget authGuard(Widget Function(dynamic user) builder) {
                  return Consumer<AuthProvider>(builder: (context, auth, _) {
                    if (!auth.isInitialized) return const InitialSplashScreen();
                    if (auth.isAuthenticated) {
                      final user = auth.user;
                      if (user != null && !user.isEmailVerified) {
                        return VerificationScreen(email: user.email ?? '');
                      }
                      return builder(user);
                    }
                    return const LoginScreen();
                  });
                }

                switch (settings.name) {
                  case '/':
                    return authGuard((user) => user?.role == 'admin'
                        ? const AdminShell()
                        : const DashboardScreen());
                  case '/login':
                    return const LoginScreen();
                  case '/game':
                    return authGuard((_) => const DashboardScreen());
                  case '/admin':
                    return authGuard((_) => const AdminShell());
                  default:
                    return const LoginScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
