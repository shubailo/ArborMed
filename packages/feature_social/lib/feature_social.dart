library feature_social;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'src/application/social_service.dart';
import 'src/presentation/social_routes.dart';

export 'src/application/social_service.dart';
export 'src/presentation/screens/clinic_directory_screen.dart';
export 'src/presentation/social_routes.dart';

class FeatureSocial {
  static void register(GetIt di) {
    final socialService = SocialService();
    di.registerSingleton<SocialService>(socialService);
  }

  static List<RouteBase> get routes => SocialRoutes.routes;
}
