import 'package:go_router/go_router.dart';
import 'screens/clinic_directory_screen.dart';

class SocialRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: '/social/directory',
      builder: (context, state) => const ClinicDirectoryScreen(),
    ),
  ];
}
