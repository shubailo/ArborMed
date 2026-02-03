import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/student/dashboard_screen.dart';

import 'services/shop_provider.dart';
import 'services/social_provider.dart';
import 'services/stats_provider.dart';

import 'theme/cozy_theme.dart';

import 'services/audio_provider.dart';
import 'services/notification_provider.dart';

import 'dart:ui'; // Required for PointerDeviceKind
import 'package:mobile/generated/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadSavedLocale()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..tryAutoLogin(), // 🔑 Auto-login on app start
        ),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StatsProvider>(
          create: (context) => StatsProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous ?? StatsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous ?? NotificationProvider(auth),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) => MaterialApp(
          title: 'Med Buddy',
          theme: CozyTheme.themeData,
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
                    return auth.user?.role == 'admin' 
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
