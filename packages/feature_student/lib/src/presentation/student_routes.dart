import 'package:feature_student/src/presentation/screens/dashboard_screen.dart';
import 'package:feature_student/src/presentation/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';

class StudentRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const StudentProfileScreen(),
    ),
  ];
}
