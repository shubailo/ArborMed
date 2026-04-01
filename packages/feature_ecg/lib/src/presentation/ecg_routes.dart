import 'package:go_router/go_router.dart';
import 'screens/ecg_practice_screen.dart';

class ECGRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: '/ecg-practice',
      builder: (context, state) => const ECGPracticeScreen(),
    ),
  ];
}
