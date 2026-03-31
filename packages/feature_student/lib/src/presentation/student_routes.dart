import 'package:go_router/go_router.dart';
import 'screens/dashboard_screen.dart';

class StudentRoutes {
  static const String dashboard = '/student-dashboard';

  static List<RouteBase> get routes => [
    GoRoute(
      path: dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
  ];
}
