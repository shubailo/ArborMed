library feature_auth;

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'src/services/auth_service.dart';
import 'src/presentation/auth_routes.dart';

export 'src/services/auth_service.dart';
export 'src/presentation/screens/login_screen.dart';
export 'src/presentation/screens/role_selection_screen.dart';
export 'src/presentation/auth_routes.dart';

class FeatureAuth {
  static void register(GetIt di) {
    // We register both the implementation and the contract
    final authService = AuthService();
    di.registerLazySingleton<AuthService>(() => authService);
    di.registerLazySingleton<AuthContract>(() => authService);

    debugPrint("[FeatureAuth] Registered AuthService as AuthContract");
  }

  static List<RouteBase> get routes => AuthRoutes.routes;
}
