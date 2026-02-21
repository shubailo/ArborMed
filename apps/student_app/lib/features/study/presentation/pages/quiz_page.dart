import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/presentation/bloc/study_notifier.dart';
import 'package:student_app/features/study/presentation/bloc/study_state.dart';
import 'package:student_app/features/study/domain/entities/question.dart';
import 'package:student_app/features/study/presentation/pages/session_summary_page.dart';

import 'package:student_app/core/ui/cozy_progress_bar.dart';
import 'package:student_app/core/ui/cozy_button.dart';
import 'package:student_app/core/ui/pressable_answer_button.dart';
import 'package:student_app/features/study/presentation/widgets/legacy_question_card.dart';
import 'package:student_app/core/ui/floating_medical_icons.dart';
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
          const FloatingMedicalIcons(color: AppTheme.warmBrown),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: state is StudyLoading && !_showingFeedback
                      ? const Center(child: CircularProgressIndicator())
                      : state is StudyLoaded
                      ? _buildQuestionCard(state.question)
                      : state is StudyEmpty
                      ? _buildEmptyState()
                      : state is StudyError
                      ? Center(child: Text('Error: ${state.message}'))
                      : const Center(child: Text('Press start to study')),
                ),
                if (state is StudyLoaded) _buildFooter(state.question),
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
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          CozyProgressBar(
            current: _sessionQuestions,
            total: _sessionLimit,
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
        CozyButton(
          label: 'RETURN TO CLINIC',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return LegacyQuestionCard(
      title: 'KÉRDÉS',
      question: Text(
        question.content,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.warmBrown,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
      answers: Column(
        children: question.options.map(
          (option) => _buildOptionButton(question, option),
        ).toList(),
      ),
    );
  }

  Widget _buildOptionButton(Question question, AnswerOption option) {
    final isSelected = _selectedOptionId == option.id;
    final isCorrect = option.isCorrect;
    
    Color bgColor = Colors.white;
    Color borderColor = AppTheme.warmBrown.withValues(alpha: 0.15);

    if (_showingFeedback) {
      if (isCorrect) {
        bgColor = AppTheme.sageGreen.withValues(alpha: 0.1);
        borderColor = AppTheme.sageGreen;
      } else if (isSelected) {
        bgColor = AppTheme.softClay.withValues(alpha: 0.1);
        borderColor = AppTheme.softClay;
      }
    } else if (isSelected) {
      borderColor = AppTheme.sageGreen;
      bgColor = AppTheme.sageGreen.withValues(alpha: 0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableAnswerButton(
        isSelected: isSelected,
        isWrong: _showingFeedback && isSelected && !isCorrect,
        isDisabled: _showingFeedback,
        backgroundColor: bgColor,
        borderColor: borderColor,
        onTap: () => _handleOptionSelected(question, option),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: AppTheme.warmBrown,
                ),
              ),
            ),
            if (_showingFeedback && (isSelected || isCorrect))
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppTheme.sageGreen : AppTheme.softClay,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Question question) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: CozyButton(
        label: _showingFeedback ? 'CONTINUE' : 'SUBMIT',
        fullWidth: true,
        enabled: _selectedOptionId != null,
        isLoading: _submitting,
        onTap: () {
          if (_showingFeedback) {
            _submitAnswer(question);
          } else {
            // Manual submit if preferred, but currently auto-submits via _handleOptionSelected
          }
        },
      ),
    );
  }
}
