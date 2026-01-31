import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../widgets/questions/question_renderer_registry.dart';

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
  dynamic userAnswer; // Track user's selected answer

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
      userAnswer = null; // Reset answer
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

  void _submitAnswer(dynamic answer) async {
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

    // Get question type (default to single_choice for backward compatibility)
    final questionType = currentQuestion!['question_type'] as String? ?? 
                        currentQuestion!['type'] as String? ?? 
                        'single_choice';
    
    // Get the appropriate renderer
    final renderer = QuestionRendererRegistry.getRenderer(questionType);
    
    // Check if user has selected an answer
    final hasAnswer = renderer.hasAnswer(userAnswer);
    
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
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Submit Button
        ElevatedButton(
          onPressed: hasAnswer 
            ? () => _submitAnswer(renderer.formatAnswer(userAnswer))
            : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: hasAnswer ? Colors.blue : Colors.grey,
          ),
          child: Text(
            hasAnswer ? 'Submit Answer' : 'Select an answer',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
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
