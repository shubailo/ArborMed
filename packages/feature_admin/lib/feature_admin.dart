library feature_admin;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'src/application/admin_service.dart';
import 'src/presentation/admin_routes.dart';

export 'src/application/admin_service.dart';
export 'src/presentation/screens/admin_dashboard_screen.dart';
export 'src/presentation/admin_routes.dart';

class FeatureAdmin {
  static void register(GetIt di) {
    final adminService = AdminService(
      dbService: di.get<DatabaseService>(),
    );
    di.registerSingleton<AdminService>(adminService);
  }

  static List<RouteBase> get routes => AdminRoutes.routes;
}
