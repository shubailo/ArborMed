library feature_game;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'src/services/game_service.dart';
import 'src/presentation/game_routes.dart';

export 'src/services/game_service.dart';
export 'src/presentation/game_routes.dart';
export 'src/presentation/screens/study_room_screen.dart';
export 'src/presentation/screens/shop_screen.dart';

class FeatureGame {
  static void register(GetIt di) {
    final gameService = GameService(di.get<AppDatabase>());
    di.registerSingleton<GameService>(gameService);
    di.registerSingleton<GameContract>(gameService);
  }

  static List<RouteBase> get routes => GameRoutes.routes;
}
