import 'package:go_router/go_router.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verification_screen.dart';

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
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerificationScreen(email: email);
      },
    ),
  ];
}
