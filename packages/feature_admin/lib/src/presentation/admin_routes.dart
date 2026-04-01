import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../application/admin_service.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_question_list_screen.dart';
import 'screens/admin_user_list_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/admin_ecg_list_screen.dart';

class AdminRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => ChangeNotifierProvider.value(
        value: GetIt.I<AdminService>(),
        child: const AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/questions',
      builder: (context, state) => ChangeNotifierProvider.value(
        value: GetIt.I<AdminService>(),
        child: const AdminQuestionListScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => ChangeNotifierProvider.value(
        value: GetIt.I<AdminService>(),
        child: const AdminUserListScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/analytics',
      builder: (context, state) => ChangeNotifierProvider.value(
        value: GetIt.I<AdminService>(),
        child: const AdminAnalyticsScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/ecg',
      builder: (context, state) => ChangeNotifierProvider.value(
        value: GetIt.I<AdminService>(),
        child: const AdminECGListScreen(),
      ),
    ),
  ];
}
