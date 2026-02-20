import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bloc/study_notifier.dart';
import '../bloc/study_state.dart';
import '../domain/entities/question.dart';
import 'session_summary_page.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _sessionQuestions = 0;
  int _correctCount = 0;
  final int _sessionLimit = 10;
  String? _selectedOptionId;
  bool _showingFeedback = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(studyProvider.notifier).fetchNextQuestion(),
    );
  }

  void _handleOptionSelected(Question question, AnswerOption option) async {
    if (_showingFeedback) return;

    setState(() {
      _selectedOptionId = option.id;
      _showingFeedback = true;
      if (option.isCorrect) _correctCount++;
      _sessionQuestions++;
    });

    // Provide weight feedback
    await Future.delayed(const Duration(milliseconds: 1000));

    // Submit to backend
    await ref.read(studyProvider.notifier).submitAnswer(
      question.id,
      option.isCorrect,
    );

    if (_sessionQuestions >= _sessionLimit) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionSummaryPage(
            correctAnswers: _correctCount,
            totalQuestions: _sessionQuestions,
            pointsEarned: _correctCount * 10,
          ),
        ),
      ).then((_) {
        // Reset session on return
        setState(() {
          _sessionQuestions = 0;
          _correctCount = 0;
        });
        ref.read(studyProvider.notifier).fetchNextQuestion();
      });
    }

    setState(() {
      _selectedOptionId = null;
      _showingFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Med-Buddy Alpha Quiz'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _sessionQuestions / _sessionLimit,
            backgroundColor: Colors.teal.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      ),
      body: Center(
        child: state is StudyLoading && !_showingFeedback
            ? const CircularProgressIndicator()
            : state is StudyLoaded
                ? _buildQuestionView(state.question)
                : state is StudyError
                    ? Text('Error: ${state.message}')
                    : const Text('Press start to study'),
      ),
    );
  }

  Widget _buildQuestionView(Question question) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Text(
              question.content,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ...question.options.map((option) => _buildOptionButton(question, option)),
        ],
      ),
    );
  }

  Widget _buildOptionButton(Question question, AnswerOption option) {
    bool isSelected = _selectedOptionId == option.id;
    Color buttonColor = Colors.white;
    Color textColor = Colors.teal;

    if (_showingFeedback) {
      if (option.isCorrect) {
        buttonColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        buttonColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            elevation: isSelected ? 4 : 0,
            side: BorderSide(
              color: isSelected ? textColor : Colors.teal.withOpacity(0.2),
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _handleOptionSelected(question, option),
          child: Text(option.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
