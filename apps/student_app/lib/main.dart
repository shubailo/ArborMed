import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/screens/room_shell_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med-Buddy: Cozy Clinical',
      theme: AppTheme.lightTheme,
      home: const RoomShellScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
