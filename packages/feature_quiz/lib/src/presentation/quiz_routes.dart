import 'package:go_router/go_router.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'screens/quiz_screen.dart';

class QuizRoutes {
  static const String quiz = '/quiz/:topicSlug';

  static List<RouteBase> get routes => [
    GoRoute(
      path: quiz,
      builder: (context, state) {
        final topicSlug = state.pathParameters['topicSlug'] ?? 'general';
        return QuizScreen(topicSlug: topicSlug);
      },
    ),
  ];
}
