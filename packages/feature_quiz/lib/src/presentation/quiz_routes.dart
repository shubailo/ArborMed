import 'package:go_router/go_router.dart';
import 'screens/quiz_session_screen.dart';
import 'screens/quiz_results_screen.dart';

class QuizRoutes {
  static const String session = '/quiz/:topicId';
  static const String results = '/quiz/results';

  static List<RouteBase> get routes => [
    GoRoute(
      path: session,
      builder: (context, state) {
        final topicId = state.pathParameters['topicId']!;
        return QuizSessionScreen(topicId: topicId);
      },
    ),
    GoRoute(
      path: '/quiz/results',
      builder: (context, state) => const QuizResultsScreen(),
    ),
    GoRoute(
      path: '/quiz/review',
      builder: (context, state) {
        final ids = state.extra as List<int>?;
        return QuizSessionScreen(topicId: 'review', questionIds: ids);
      },
    ),
  ];
}
