import 'package:feature_auth/feature_auth.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:feature_student/feature_student.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_social/feature_social.dart';
import 'screens/auth/initial_splash_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'dart:ui';


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
          create: (context) => NotificationProvider(),
          update: (context, auth, previous) {
            if (!auth.isAuthenticated) previous?.resetState();
            return previous ?? NotificationProvider();
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
                        ? const AdminDashboardScreen()
                        : const StudentDashboardScreen();
                  }
                  return const LoginScreen();
                });
                break;
              case '/login':
                builder = const LoginScreen();
                break;
              case '/game':
                builder = authGuard(const StudentDashboardScreen());
                break;
              case '/admin':
                builder = authGuard(const AdminDashboardScreen());
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

