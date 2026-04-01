import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthContract _auth;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _auth = GetIt.I<AuthContract>();
    _init();
  }

  Future<void> _init() async {
    // 1. Give it a tiny bit of time for the splash to be visible
    await Future.delayed(const Duration(milliseconds: 800));

    // 2. Initial state check
    if (_auth.authState != AuthState.loading) {
       _navigate(_auth.authState);
    } else {
       // 3. Wait for it to finish loading
       _sub = _auth.authStateStream.listen((state) {
          if (state != AuthState.loading) {
             _navigate(state);
          }
       });
    }
  }

  void _navigate(AuthState state) {
    if (!mounted) return;
    
    if (state == AuthState.authenticated) {
      final role = _auth.userRole ?? 'student';
      if (role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/student/home');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the correct logo path found in assets/logo/
            Image.asset(
              'assets/logo/app_icon.png',
              width: 120,
              errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
