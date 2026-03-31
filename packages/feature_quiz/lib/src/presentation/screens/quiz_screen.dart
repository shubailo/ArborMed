import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  final String topicSlug;

  const QuizScreen({super.key, required this.topicSlug});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService(GetIt.I<DatabaseService>().isar);
    _quizService.loadQuestions(widget.topicSlug);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final isDark = ThemeService.of(context).isDarkMode;

    return ChangeNotifierProvider.value(
      value: _quizService,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'ArborMed Quiz: ${widget.topicSlug.toUpperCase()}',
            style: theme.textTheme.titleMedium.copyWith(color: theme.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<QuizService>(
          builder: (context, service, child) {
            if (service.questions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (service.isFinished) {
              return _buildFinishedState(context, service, theme);
            }

            final question = service.questions[service.currentIndex];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: service.progress,
                    backgroundColor: theme.surfaceSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                  const SizedBox(height: 24),
                  
                  // Question Card
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildContent(question, theme, isDark),
                          const SizedBox(height: 32),
                          ...List.generate(
                            question.optionsEn.length,
                            (index) => _buildOption(index, question, service, theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(question, theme, isDark) {
    return Column(
      children: [
        Text(
          question.textEn,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          question.textHu,
          style: theme.textTheme.bodyMedium.copyWith(
            color: theme.textSecondary.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOption(int index, question, service, theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ArborButton.secondary(
        label: question.optionsEn[index],
        onPressed: () => service.answerQuestion(index),
      ),
    );
  }

  Widget _buildFinishedState(BuildContext context, QuizService service, CozyTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: theme.textTheme.headlineMedium.copyWith(color: theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Score: ${service.score} / ${service.questions.length}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ArborButton.primary(
            label: 'Back to Dashboard',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
