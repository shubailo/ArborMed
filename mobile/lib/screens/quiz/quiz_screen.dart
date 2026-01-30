import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class QuizScreen extends StatefulWidget {
  final String topicSlug;
  final String topicName;

  const QuizScreen({super.key, required this.topicSlug, required this.topicName});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Session State
  int? sessionId;
  Map<String, dynamic>? currentQuestion;
  bool isLoading = true;
  String? feedbackMessage;
  bool isCorrect = false;
  int? coinsEarned;

  @override
  void initState() {
    super.initState();
    _startSession();
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
    setState(() {
      isLoading = true;
      feedbackMessage = null;
      currentQuestion = null;
    });

    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final question = await api.get('/quiz/next?topic=${widget.topicSlug}');
      
      setState(() {
        currentQuestion = question;
        isLoading = false;
      });
    } catch (e) {
      // API returns 404 when no more questions
      if (e.toString().contains('404')) {
        _showCompletionDialog();
      } else {
        _showError('Failed to load question: $e');
      }
    }
  }

  void _submitAnswer(String answer) async {
    if (sessionId == null || currentQuestion == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.post('/quiz/answer', {
        'sessionId': sessionId,
        'questionId': currentQuestion!['id'],
        'userAnswer': answer,
        'responseTimeMs': 5000 // Placeholder
      });

      setState(() {
        isLoading = false;
        feedbackMessage = response['isCorrect'] ? 'Correct!' : 'Incorrect';
        isCorrect = response['isCorrect'];
        coinsEarned = response['coinsEarned'];
      });

    } catch (e) {
      _showError('Failed to submit answer: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    setState(() => isLoading = false);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: const Text('You have finished all questions for this topic.'),
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

    final options = List<String>.from(currentQuestion!['options']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Header
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Chip(label: Text('Bloom: ${currentQuestion!['bloom_level']}')),
             Chip(label: Text('Difficulty: ${currentQuestion!['difficulty']}')),
           ],
        ),
        const SizedBox(height: 20),
        AutoSizeText(
          currentQuestion!['text'],
          maxLines: 4,
          minFontSize: 12,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        ...options.map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton(
            onPressed: () => _submitAnswer(opt),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(opt, style: const TextStyle(fontSize: 16)),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildFeedbackView() {
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
              child: Text('+ $coinsEarned 🩺', style: const TextStyle(fontSize: 20, color: Colors.blue)),
            ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _loadNextQuestion,
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }
}
