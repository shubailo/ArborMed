library feature_student;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'src/services/student_service.dart';
import 'src/presentation/student_routes.dart';

export 'src/services/student_service.dart';
export 'src/presentation/student_routes.dart';

class FeatureStudent {
  static void register(GetIt di) {
    final studentService = StudentService(di.get<AppDatabase>());
    di.registerSingleton<StudentService>(studentService);
    di.registerSingleton<StudentContract>(studentService);
    di.registerSingleton<QuestContract>(studentService);
  }

  static List<RouteBase> get routes => StudentRoutes.routes;
}

