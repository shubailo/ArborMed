library feature_quiz;

import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'src/services/quiz_service.dart';
import 'src/presentation/quiz_routes.dart';

export 'src/services/quiz_service.dart';
export 'src/presentation/quiz_routes.dart';
export 'src/presentation/screens/quiz_session_screen.dart';
export 'src/presentation/screens/quiz_results_screen.dart';

class FeatureQuiz {
  static void register(GetIt di) {
    final quizService = QuizService(
      di.get<StudentContract>(),
      di.get<QuestContract>(),
    );
    di.registerSingleton<QuizService>(quizService);
    di.registerSingleton<QuizContract>(quizService);
  }

  static List<RouteBase> get routes => QuizRoutes.routes;
}
