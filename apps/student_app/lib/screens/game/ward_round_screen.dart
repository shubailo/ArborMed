import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/ward_provider.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';

class WardRoundScreen extends StatefulWidget {
  const WardRoundScreen({super.key});

  @override
  State<WardRoundScreen> createState() => _WardRoundScreenState();
}

class _WardRoundScreenState extends State<WardRoundScreen> {
  String? _selectedAnswer;
  bool _hasVoted = false;

  @override
  Widget build(BuildContext context) {
    final wardProvider = Provider.of<WardProvider>(context);
    final question = wardProvider.currentCase;

    if (wardProvider.state == WardState.summary) {
      return _buildSummaryState(wardProvider);
    }

    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final options = List<String>.from(question['options'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ward Rounds'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Code: ${wardProvider.currentWardCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Votes: ${wardProvider.votesCast} / ${wardProvider.userCount}', style: const TextStyle(color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 24),
            // Clinical Case
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    question['text'] ?? 'Clinical case description...',
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Options
            ...options.map((option) {
              final isSelected = _selectedAnswer == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: _hasVoted ? null : () {
                    setState(() {
                      _selectedAnswer = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            CozyButton(
              label: _hasVoted ? 'Waiting for others...' : 'Submit Diagnosis',
              onPressed: (_hasVoted || _selectedAnswer == null) ? null : () {
                setState(() { _hasVoted = true; });
                wardProvider.submitVote(_selectedAnswer!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryState(WardProvider wardProvider) {
    final result = wardProvider.roundResult;
    if (result == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final bool isCorrect = result['isConsensusCorrect'];

    return Scaffold(
      appBar: AppBar(title: const Text('Round Summary'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error,
                size: 100,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isCorrect ? 'Consensus Reached!' : 'Diagnosis Incorrect',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Correct Answer:\n${result['correctAnswer']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              if (wardProvider.isHost)
                CozyButton(
                  label: 'Next Patient (Case)',
                  onPressed: () {
                    wardProvider.startRound();
                  },
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  wardProvider.leaveWard();
                  Navigator.of(context).pushReplacementNamed('/student_dashboard'); // Or back to lobby
                },
                child: const Text('Leave Ward', style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
