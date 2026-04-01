import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    final quiz = GetIt.I<QuizContract>();
    final accuracy = quiz.currentSession?.accuracy ?? 0;
    if (accuracy > 0.7) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final quiz = GetIt.I<QuizContract>();
    final session = quiz.currentSession;
    
    if (session == null) {
      return const Scaffold(body: Center(child: Text('Session data lost.')));
    }

    final accuracy = (session.accuracy * 100).toInt();
    final xpEarned = session.correctCount * 10;
    final coinsEarned = session.correctCount * 5;
    final mistakeCount = session.mistakeCount;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [theme.primary, theme.accent, Colors.green, Colors.orange],
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildResultsCard(context, session, accuracy),
                  const SizedBox(height: 32),
                  _buildRewardsSection(context, xpEarned, coinsEarned),
                  if (mistakeCount > 0) ...[
                    const SizedBox(height: 32),
                    _buildMistakesCard(context, mistakeCount),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context, QuizSession session, int accuracy) {
    final theme = CozyTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: theme.shadowSmall,
      ),
      child: Column(
        children: [
          Text(
            accuracy > 70 ? 'Great Job!' : 'Keep Practicing',
            style: theme.headingLarge,
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: session.accuracy,
                  strokeWidth: 15,
                  backgroundColor: theme.background,
                  color: accuracy > 70 ? Colors.green : theme.accent,
                ),
              ),
              Column(
                children: [
                  Text('$accuracy%', style: theme.headingLarge.copyWith(fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('Accuracy', style: theme.bodySmall.copyWith(color: theme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(context, 'Total', session.totalQuestions.toString()),
              _buildStat(context, 'Correct', session.correctCount.toString()),
              _buildStat(context, 'Mistakes', session.mistakeCount.toString(), color: (session.mistakeCount > 0) ? theme.accent : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, {Color? color}) {
    final theme = CozyTheme.of(context);
    return Column(
      children: [
        Text(value, style: theme.headingSmall.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.bodySmall.copyWith(color: theme.textSecondary)),
      ],
    );
  }

  Widget _buildRewardsSection(BuildContext context, int xp, int coins) {
    return Row(
      children: [
        Expanded(child: _buildRewardItem(context, Icons.bolt, '+$xp XP', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildRewardItem(context, Icons.currency_bitcoin, '+$coins Coins', Colors.amber)),
      ],
    );
  }

  Widget _buildRewardItem(BuildContext context, IconData icon, String label, Color color) {
    final theme = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMistakesCard(BuildContext context, int count) {
    final theme = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.accent.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count Mistakes Identified', style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                Text('Practice these again to improve.', style: theme.bodySmall.copyWith(color: theme.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, // Future Feature: Review Session
            child: Text('REVIEW', style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
