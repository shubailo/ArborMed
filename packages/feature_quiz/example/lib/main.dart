import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart' hide QuestType;
import 'package:feature_quiz/feature_quiz.dart';
import 'package:core_interop/core_interop.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

// --- MOCKS ---

class MockStudentContract extends ChangeNotifier implements StudentContract {
  int _xp = 100;
  int _coins = 50;

  @override Future<int> getCoins() async => _coins;
  @override Future<int> getXP() async => _xp;
  @override Future<int> getLevel() async => (_xp / 100).floor() + 1;
  
  @override Future<void> addXP(int amount) async { _xp += amount; notifyListeners(); }
  @override Future<void> addCoins(int amount) async { _coins += amount; notifyListeners(); }

  @override List<ActivityData> get activityData => [];
  @override ReadinessScore? get readinessScore => ReadinessScore(overall: 75, breakdown: []);
  @override List<SmartReviewItem> get smartReview => [];
  @override List<SubjectMastery> get subjectMastery => [];
  @override Future<void> fetchActivity(String timeframe) async {}
  @override Future<void> fetchReadiness() async {}
  @override Future<void> fetchSmartReview() async {}
  @override Future<void> fetchSummary() async {}

  @override Future<int> getMistakeCount() async => 0;
  @override Future<List<int>> getIncorrectQuestionIds() async => [];
}

class MockQuestContract implements QuestContract {
  @override Future<void> updateProgress(QuestType type, int amount) async {}
  @override Future<void> fetchQuests() async {}
  @override List<dynamic> get activeQuests => [];
}

// --- APP ---

void main() {
  final getIt = GetIt.instance;
  
  final studentMock = MockStudentContract();
  final questMock = MockQuestContract();
  
  getIt.registerSingleton<StudentContract>(studentMock);
  getIt.registerSingleton<QuestContract>(questMock);
  
  final quizService = QuizService(studentMock, questMock);
  getIt.registerSingleton<QuizContract>(quizService);
  getIt.registerSingleton<QuizService>(quizService);

  runApp(const QuizExampleApp());
}

class QuizExampleApp extends StatelessWidget {
  const QuizExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quiz Feature Example',
      theme: CozyTheme.light,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ExampleHome(),
    ),
    ...QuizRoutes.routes,
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Returned to Dashboard'))),
    ),
  ],
);

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Feature Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/quiz/cardiology'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Start Cardiology Quiz'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/quiz/neurology'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Start Neurology Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
