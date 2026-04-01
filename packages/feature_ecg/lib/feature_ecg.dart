library feature_ecg;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'src/services/drift_ecg_service.dart';
import 'src/presentation/ecg_routes.dart';

export 'src/services/drift_ecg_service.dart';
export 'src/presentation/ecg_routes.dart';
export 'src/presentation/screens/ecg_practice_screen.dart';

class FeatureECG {
  static void register(GetIt di) {
    final ecgService = DriftECGService(
      db: di.get<AppDatabase>(),
    );
    di.registerSingleton<ECGContract>(ecgService);
  }

  static List<RouteBase> get routes => ECGRoutes.routes;
}
