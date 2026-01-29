import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/dashboard_screen.dart';

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
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            // Simple Auth Gate
            // For MVP: If we have a user in memory, go to Dashboard
            // Otherwise Login. 
            // Better to use Token persistence in future.
            
            return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
