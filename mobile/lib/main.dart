import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/dashboard_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/questions_screen.dart';

import 'services/shop_provider.dart';
import 'services/social_provider.dart';
import 'services/stats_provider.dart';

import 'theme/cozy_theme.dart';


import 'services/audio_provider.dart';

import 'dart:ui'; // Required for PointerDeviceKind

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StatsProvider>(
          create: (context) => StatsProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous ?? StatsProvider(auth),
        ),

      ],
      child: MaterialApp(
        title: 'Med Buddy',
        theme: CozyTheme.themeData,
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
                  if (auth.isAuthenticated) {
                    return auth.user?.role == 'admin' 
                      ? const AdminDashboardScreen() 
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
            case '/admin/dashboard':
              builder = const AdminDashboardScreen();
              break;
            case '/admin/questions':
              builder = const AdminQuestionsScreen();
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
    );
  }
}
