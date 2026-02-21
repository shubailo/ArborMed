import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/presentation/bloc/study_notifier.dart';
import 'package:student_app/features/study/presentation/bloc/study_state.dart';
import 'package:student_app/features/study/domain/entities/question.dart';
import 'package:student_app/features/study/presentation/pages/session_summary_page.dart';

import 'package:student_app/core/ui/cozy_panel.dart';
import 'package:student_app/features/study/presentation/widgets/cozy_progress_bar.dart';
import 'package:student_app/features/study/presentation/widgets/liquid_button.dart';
import 'package:student_app/features/study/presentation/widgets/floating_medical_icons.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';

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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(studyProvider.notifier).fetchNextQuestion(),
    );
  }

  void _handleOptionSelected(Question question, AnswerOption option) async {
    if (_showingFeedback || _submitting) return;

    setState(() {
      _selectedOptionId = option.id;
      _showingFeedback = true;
      if (option.isCorrect) _correctCount++;
      _sessionQuestions++;
    });

    // Provide weight feedback delay
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _submitAnswer(Question question) async {
    if (_selectedOptionId == null || _submitting) return;

    final selectedOption = question.options.firstWhere(
      (o) => o.id == _selectedOptionId,
    );

    setState(() => _submitting = true);

    // Submit to backend
    await ref
        .read(studyProvider.notifier)
        .submitAnswer(question.id, selectedOption.isCorrect);

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
          _selectedOptionId = null;
          _showingFeedback = false;
          _submitting = false;
        });
        ref.read(studyProvider.notifier).fetchNextQuestion();
      });
    } else {
      setState(() {
        _selectedOptionId = null;
        _showingFeedback = false;
        _submitting = false;
      });
      ref.read(studyProvider.notifier).fetchNextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);

    return Scaffold(
      backgroundColor: AppTheme.ivoryCream,
      body: Stack(
        children: [
          const FloatingMedicalIcons(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: state is StudyLoading && !_showingFeedback
                        ? const CircularProgressIndicator()
                        : state is StudyLoaded
                        ? _buildQuestionView(state.question)
                        : state is StudyEmpty
                        ? _buildEmptyState()
                        : state is StudyError
                        ? Text('Error: ${state.message}')
                        : const Text('Press start to study'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(CozyTheme.spacingLarge),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.warmBrown),
              ),
              Text(
                'Question $_sessionQuestions/$_sessionLimit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmBrown,
                ),
              ),
              const SizedBox(width: 48), // Spacer for centering balance
            ],
          ),
          const SizedBox(height: 8),
          CozyProgressBar(
            value: _sessionQuestions / _sessionLimit,
            pulse: _showingFeedback,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final mode = ref.read(studyModeProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          mode == 'MISTAKE_REVIEW' ? Icons.celebration : Icons.inbox,
          size: 64,
          color: AppTheme.sageGreen,
        ),
        const SizedBox(height: 16),
        Text(
          mode == 'MISTAKE_REVIEW'
              ? 'All caught up on recent mistakes!'
              : 'No questions available.',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Return'),
        ),
      ],
    );
  }

  Widget _buildQuestionView(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CozyTheme.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CozyPanel(
            animateIn: !_showingFeedback,
            child: Text(
              question.content,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ...question.options.map(
            (option) => _buildOptionTile(question, option),
          ),
          const SizedBox(height: 32),
          LiquidButton(
            label: _showingFeedback ? 'Next Question' : 'Submit Answer',
            onTap: _selectedOptionId != null
                ? () => _showingFeedback ? _submitAnswer(question) : null
                : null,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(Question question, AnswerOption option) {
    bool isSelected = _selectedOptionId == option.id;
    Color tileColor = Colors.white;
    Color borderColor = AppTheme.warmBrown.withValues(alpha: 0.1);
    Color textColor = AppTheme.warmBrown;

    if (_showingFeedback) {
      if (option.isCorrect) {
        tileColor = AppTheme.sageGreen.withValues(alpha: 0.2);
        borderColor = AppTheme.sageGreen;
        textColor = AppTheme.sageGreen;
      } else if (isSelected) {
        tileColor = AppTheme.softClay.withValues(alpha: 0.2);
        borderColor = AppTheme.softClay;
        textColor = AppTheme.softClay;
      }
    } else if (isSelected) {
      borderColor = AppTheme.sageGreen;
      tileColor = AppTheme.sageGreen.withValues(alpha: 0.05);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => _handleOptionSelected(question, option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: CozyTheme.borderMedium,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected ? CozyTheme.panelShadow : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  _showingFeedback
                      ? (option.isCorrect ? Icons.check_circle : Icons.cancel)
                      : Icons.radio_button_checked,
                  color: borderColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
