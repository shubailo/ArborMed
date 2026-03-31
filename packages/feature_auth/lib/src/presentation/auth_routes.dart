import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';

class AuthRoutes {
  static List<RouteBase> get routes => [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/login/:role',
          builder: (context, state) {
            final role = state.pathParameters['role'] ?? 'student';
            return LoginScreen(role: role);
          },
        ),
      ];
}
