import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/duel_provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/cozy/cozy_button.dart';
import '../../widgets/cozy/cozy_progress_bar.dart';
import '../../widgets/cozy/pressable_answer_button.dart';
import '../../widgets/cozy/cozy_panel.dart';

class DuelGameScreen extends StatefulWidget {
  const DuelGameScreen({super.key});

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  String? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final duelProvider = context.watch<DuelProvider>();

    // If game is over, we should show the results overlay
    // For now we'll handle it via returning a different widget tree if finished
    if (duelProvider.state == DuelState.finished) {
      return _buildResults(context, duelProvider);
    }

    if (duelProvider.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = duelProvider.questions[duelProvider.currentQuestionIndex];
    final options = _getOptions(currentQuestion);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreboard(context, duelProvider),
            const SizedBox(height: 8),
            _buildTimerBar(context, duelProvider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildQuestionCard(context, currentQuestion),
                    const SizedBox(height: 24),
                    ...options.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PressableAnswerButton(
                            isSelected: _selectedAnswer == opt,
                            onTap: () {
                              setState(() => _selectedAnswer = opt);
                              duelProvider.submitAnswer(opt);
                              // We don't reset _selectedAnswer here immediately because 
                              // we wait for question index to change or game to end.
                            },
                            backgroundColor: _selectedAnswer == opt 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            borderColor: _selectedAnswer == opt 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                opt,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getOptions(Map<String, dynamic> question) {
    dynamic optionsData;
    
    // Check nested content first (standard)
    if (question['content'] != null && question['content'] is Map) {
      optionsData = question['content']['options'];
    }
    
    // Fallback to top-level options (legacy)
    optionsData ??= question['options'];
    
    if (optionsData == null) return [];
    
    // Handle localized structure: { "en": [...], "hu": [...] }
    if (optionsData is Map && (optionsData.containsKey('en') || optionsData.containsKey('hu'))) {
      // Priority: hu if locale is HU (not implemented yet), otherwise en
      optionsData = optionsData['en'] ?? optionsData['hu'];
    }

    if (optionsData == null) return [];
    
    // Handle List
    if (optionsData is Iterable) {
      return List<String>.from(optionsData.map((e) => e.toString()));
    }
    
    // Handle indexed Map (if keys are indices: { "0": "...", "1": "..." })
    if (optionsData is Map) {
      final sortedKeys = optionsData.keys.toList()..sort((a, b) {
        final aInt = int.tryParse(a.toString());
        final bInt = int.tryParse(b.toString());
        if (aInt != null && bInt != null) return aInt.compareTo(bInt);
        return a.toString().compareTo(b.toString());
      });
      return List<String>.from(sortedKeys.map((k) => optionsData[k].toString()));
    }
    
    return [];
  }

  Widget _buildScoreboard(BuildContext context, DuelProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerScore(
            context, 
            "YOU", 
            provider.role == 'p1' ? provider.p1Score : provider.p2Score,
            isMe: true
          ),
          const Text("VS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey)),
          _buildPlayerScore(
            context, 
            provider.opponentName ?? "OPPONENT", 
            provider.role == 'p1' ? provider.p2Score : provider.p1Score,
            isMe: false
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(BuildContext context, String label, int score, {required bool isMe}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold,
            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBar(BuildContext context, DuelProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TIME REMAINING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text("${provider.timeRemaining}s", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          CozyProgressBar(
            current: provider.timeRemaining,
            total: 60,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> question) {
    final text = question['q'] ?? question['text'] ?? 'Question missing';
    return CozyPanel(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        width: double.infinity,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, DuelProvider provider) {
    final bool isWon = provider.winner == provider.role;
    final bool isDraw = provider.winner == 'draw';
    final int pot = provider.potWon > 0 ? provider.potWon : (isWon ? provider.currentWager * 2 : (isDraw ? provider.currentWager : 0));

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWon)
                const Icon(Icons.emoji_events, size: 100, color: Colors.amber)
              else if (isDraw)
                const Icon(Icons.handshake, size: 100, color: Colors.blueGrey)
              else
                const Icon(Icons.sentiment_very_dissatisfied, size: 100, color: Colors.grey),
              
              const SizedBox(height: 24),
              Text(
                isWon ? "MISSION SUCCESS" : (isDraw ? "STALEMATE" : "MISSION FAILED"),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWon ? "Victory is yours, Doctor!" : (isDraw ? "Both specialists are equal." : "Better luck next shift."),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Currency Reward Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isWon 
                      ? const Color(0xFF8CAA8C).withValues(alpha: 0.2)
                      : (isDraw ? Colors.grey.withValues(alpha: 0.15) : const Color(0xFFC48B76).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWon 
                        ? const Color(0xFF8CAA8C)
                        : (isDraw ? Colors.grey : const Color(0xFFC48B76)),
                  ),
                ),
                child: Text(
                  isWon
                      ? "+$pot 🩺 Pot Won!"
                      : (isDraw ? "+$pot 🩺 Wager Refunded" : "-${provider.currentWager} 🩺 Wager Lost"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWon 
                        ? const Color(0xFF2E5E35) 
                        : (isDraw ? Colors.blueGrey : const Color(0xFF944B36)),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              CozyPanel(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlayerScore(context, "YOUR SCORE", provider.role == 'p1' ? provider.p1Score : provider.p2Score, isMe: true),
                    _buildPlayerScore(context, provider.opponentName ?? "OPPONENT", provider.role == 'p1' ? provider.p2Score : provider.p1Score, isMe: false),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              CozyButton(
                label: "LEAVE ARENA",
                onPressed: () async {
                  await context.read<AuthProvider>().refreshUser();
                  provider.reset();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
