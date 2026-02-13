import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/questions/question_renderer_registry.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';

class QuizScreen extends StatefulWidget {
  final String topicSlug;
  final String topicName;

  const QuizScreen(
      {super.key, required this.topicSlug, required this.topicName});

  @override
  createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  // Session State
  int? sessionId;
  Map<String, dynamic>? currentQuestion;
  bool isLoading = true;
  String? feedbackMessage;
  bool isCorrect = false;
  int? coinsEarned;
  dynamic userAnswer; // Track user's selected answer

  // Stability & Anti-skip guards
  bool _isInteractionLocked = false;
  DateTime? _lastQuestionLoadTime;
  int _accumulatedTimeMs = 0; // Track time across pauses
  DateTime? _timerStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_timerStartTime != null) {
        _accumulatedTimeMs += DateTime.now().difference(_timerStartTime!).inMilliseconds;
        _timerStartTime = null;
        debugPrint("⏱️ Legacy Quiz Timer Paused: $_accumulatedTimeMs ms");
      }
    } else if (state == AppLifecycleState.resumed) {
      if (currentQuestion != null && feedbackMessage == null) {
        _timerStartTime = DateTime.now();
        debugPrint("⏱️ Legacy Quiz Timer Resumed");
      }
    }
  }

  void _startSession() async {
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final session = await api.post('/quiz/start', {});

      setState(() {
        sessionId = session['id'];
      });

      _loadNextQuestion();
    } catch (e) {
      _showError('Failed to start session: $e');
    }
  }

  void _loadNextQuestion() async {
    if (_isInteractionLocked) return;

    setState(() {
      _isInteractionLocked = true;
      isLoading = true;
      feedbackMessage = null;
      currentQuestion = null;
      userAnswer = null; // Reset answer
      _accumulatedTimeMs = 0;
      _timerStartTime = null;
    });

    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final question = await api.get('/quiz/next?topic=${widget.topicSlug}');

      setState(() {
        currentQuestion = question;
        _lastQuestionLoadTime = DateTime.now();
        _timerStartTime = DateTime.now();
        isLoading = false;
        _isInteractionLocked = false;
      });
    } catch (e) {
      setState(() => _isInteractionLocked = false);
      // API returns 404 when no more questions
      if (e.toString().contains('404')) {
        _showCompletionDialog();
      } else {
        _showError('Failed to load question: $e');
      }
    }
  }

  void _submitAnswer(dynamic answer) async {
    if (sessionId == null || currentQuestion == null || _isInteractionLocked) return;

    // Prevention of accidental skips (cooldown)
    if (_lastQuestionLoadTime != null) {
      final diff = DateTime.now().difference(_lastQuestionLoadTime!);
      if (diff.inMilliseconds < 500) {
        debugPrint("Guard: Tap ignored (only ${diff.inMilliseconds}ms since load)");
        return;
      }
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isInteractionLocked = true;
      isLoading = true;
    });

    try {
      if (_timerStartTime != null) {
        _accumulatedTimeMs += DateTime.now().difference(_timerStartTime!).inMilliseconds;
      }
      final totalTime = _accumulatedTimeMs > 0 ? _accumulatedTimeMs : 1000;

      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.post('/quiz/answer', {
        'sessionId': sessionId,
        'questionId': currentQuestion!['id'],
        'userAnswer': answer,
        'responseTimeMs': totalTime
      });

      setState(() {
        isLoading = false;
        feedbackMessage =
            response['isCorrect'] ? l10n.quizCorrect : l10n.quizIncorrect;
        isCorrect = response['isCorrect'];
        coinsEarned = response['coinsEarned'];
        _isInteractionLocked = false;
      });
    } catch (e) {
      setState(() => _isInteractionLocked = false);
      _showError('Failed to submit answer: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    setState(() => isLoading = false);
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quizFinish),
        content: const Text(
            'You have finished all questions for this topic.'), // Could localize this too
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('Back to Dashboard'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topicName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : feedbackMessage != null
                ? _buildFeedbackView()
                : _buildQuestionView(),
      ),
    );
  }

  Widget _buildQuestionView() {
    if (currentQuestion == null) return Container();
    final l10n = AppLocalizations.of(context)!;

    // Get question type (default to single_choice for backward compatibility)
    final questionType = currentQuestion!['question_type'] as String? ??
        currentQuestion!['type'] as String? ??
        'single_choice';

    // Get the appropriate renderer
    final renderer = QuestionRendererRegistry.getRenderer(questionType);

    // Check if user has selected an answer
    final hasAnswer = renderer.hasAnswer(userAnswer);

    // Determine if we should show the submit button for this question type
    final showSubmitButton = [
      'multiple_choice',
      'relation_analysis',
      'matching',
      'case_study'
    ].contains(questionType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(
                label:
                    Text('${l10n.level}: ${currentQuestion!['bloom_level']}')),
            Chip(
                label: Text(
                    '${l10n.difficulty}: ${currentQuestion!['difficulty']}')),
          ],
        ),
        const SizedBox(height: 20),

        // Question Display (using renderer)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Render question content
                renderer.buildQuestion(context, currentQuestion!),
                const SizedBox(height: 30),

                // Render answer input
                renderer.buildAnswerInput(
                  context,
                  currentQuestion!,
                  userAnswer,
                  (newAnswer) {
                    setState(() {
                      userAnswer = newAnswer;
                    });

                    // Auto-submit for specific types
                    if (!showSubmitButton) {
                      _submitAnswer(renderer.formatAnswer(newAnswer));
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Submit Button (Conditional)
        if (showSubmitButton)
          ElevatedButton(
            onPressed: hasAnswer
                ? () => _submitAnswer(renderer.formatAnswer(userAnswer))
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: hasAnswer ? Colors.blue : Colors.grey,
            ),
            child: Text(
              hasAnswer
                  ? l10n.quizSubmit
                  : l10n.quizSubmit, // Or 'Select Answer'
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildFeedbackView() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            feedbackMessage!,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (coinsEarned != null && coinsEarned! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('+ $coinsEarned ${l10n.coins}',
                  style: const TextStyle(fontSize: 20, color: Colors.blue)),
            ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _loadNextQuestion,
            child: Text(l10n.quizNext),
          ),
        ],
      ),
    );
  }
}
