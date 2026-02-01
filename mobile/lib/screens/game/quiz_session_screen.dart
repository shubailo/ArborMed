import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/cozy/cozy_card.dart';
import '../../widgets/cozy/cozy_button.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/cozy/confetti_overlay.dart'; 
import '../../widgets/quiz/feedback_bottom_sheet.dart'; 
import '../../widgets/questions/question_renderer_registry.dart'; // Added
// Added

class QuizSessionScreen extends StatefulWidget {
  final String systemName;
  final String systemSlug;

  const QuizSessionScreen({super.key, required this.systemName, required this.systemSlug});

  @override
  createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  String? _sessionId;
  
  // Replaced index with dynamic answer
  dynamic _userAnswer; 
  bool _isAnswerChecked = false;
  
  // Feedback State
  final ConfettiController _confettiController = ConfettiController(); 
  
  bool _showFeedback = false;
  bool _feedbackIsCorrect = false;
  String _feedbackExplanation = "";

  @override
  void initState() {
    super.initState();
    _startQuizSession();
  }

  Future<void> _startQuizSession() async {
    try {
      final session = await _apiService.post('/quiz/start', {});
      setState(() {
        _sessionId = session['id'].toString();
      });
      _fetchNextQuestion();
    } catch (e) {
      debugPrint("Error starting session: $e");
    }
  }

  Future<void> _fetchNextQuestion() async {
    setState(() {
      if (_currentQuestion == null) _isLoading = true; 
      _userAnswer = null; // Reset answer
      _isAnswerChecked = false;
      _showFeedback = false; 
    });

    try {
      final q = await _apiService.get('/quiz/next?topic=${widget.systemSlug}');
      setState(() {
        _currentQuestion = q;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching question: $e");
      setState(() { _isLoading = false; });
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitAnswer() async {
    if (_isAnswerChecked || _isSubmitting || _sessionId == null || _currentQuestion == null || _userAnswer == null) return;
    
    setState(() {
      _isSubmitting = true; 
    });

    // Determine renderer to format answer
    final qType = _currentQuestion!['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final formattedAnswer = renderer.formatAnswer(_userAnswer);

    try {
      final result = await _apiService.post('/quiz/answer', {
        'sessionId': _sessionId,
        'questionId': _currentQuestion!['id'],
        'userAnswer': formattedAnswer,
        // 'userIndex': ... // Not sending index anymore as generic answers don't always have one
        'responseTimeMs': 1000 
      });

      if (!mounted) return;

      setState(() {
        _isAnswerChecked = true; 
        _isSubmitting = false;
        
        // Trigger global background refresh
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
        
        // Handle Climber Events
        if (result['climber'] != null) {
           final climber = result['climber'];
           if (climber['event'] == 'PROMOTION' || climber['event'] == 'LEVEL_UNLOCKED') {
              _confettiController.blast(); 
           }
        }
        
        _showFeedback = true;
        _feedbackIsCorrect = result['isCorrect'];
        _feedbackExplanation = result['isCorrect'] ? "" : (result['explanation'] ?? "Incorrect Answer.");
      });

    } catch (e) {
      debugPrint("Error submitting answer: $e");
      setState(() {
        _isSubmitting = false;
        _isAnswerChecked = false; 
      });
      _showOverlayMessage("Error: $e", Colors.red);
    }
  }



  void _showOverlayMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        duration: const Duration(seconds: 3),
      )
    );
  }

  void _exitQuiz() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
      backgroundColor: CozyTheme.background,
      body: Center(child: CircularProgressIndicator(color: CozyTheme.primary))
    );
    }

    if (_currentQuestion == null) {
      return const Scaffold(
      backgroundColor: CozyTheme.textSecondary,
      body: Center(child: Text("No questions found!", style: TextStyle(color: Colors.white)))
    );
    }

    final q = _currentQuestion!;
    final user = Provider.of<AuthProvider>(context).user;
    final totalCoins = user?.coins ?? 0;
    
    // Determine Renderer
    final qType = q['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final hasAnswer = renderer.hasAnswer(_userAnswer);

    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: Stack(
        children: [
          // 0. Fluid Background Pattern
          const Positioned.fill(
            child: FloatingMedicalIcons(
              color: CozyTheme.primary,
            ),
          ),

          // Confetti Layer
          ConfettiOverlay(controller: _confettiController),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Coins & Close)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(20),
                           boxShadow: [
                             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                           ]
                         ),
                         child: Row(
                           children: [
                             Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 20, height: 20),
                             const SizedBox(width: 6),
                             Text("$totalCoins", style: const TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.accent)),
                           ],
                         ),
                       ),
                       GestureDetector(
                         onTap: _exitQuiz,
                         child: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                           child: const Icon(Icons.close, size: 20, color: CozyTheme.textSecondary)
                         ),
                       ),
                    ],
                  ),
                ),

                // 2. The Question Card
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: CozyCard(
                          title: widget.systemName.toUpperCase(),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Delegate Content Rendering
                                renderer.buildQuestion(context, q),
                      
                                const SizedBox(height: 24),
                      
                                // Delegate Answer Input Rendering
                                renderer.buildAnswerInput(
                                  context, 
                                  q, 
                                  _userAnswer, 
                                  _isAnswerChecked ? (_) {} : (val) {
                                    setState(() {
                                      _userAnswer = val;
                                    });
                                  }
                                ),
                      
                                const SizedBox(height: 32),
                                // Submit Button
                                CozyButton(
                                  label: "Submit Answer",
                                  onPressed: hasAnswer && !_isAnswerChecked && !_isSubmitting ? _submitAnswer : null,
                                  variant: hasAnswer ? CozyButtonVariant.primary : CozyButtonVariant.outline,
                                  fullWidth: true,
                                  icon: Icons.send_rounded,
                                ),
                              ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Feedback Sheet
          if (_showFeedback)
            Positioned(
              left: 0, 
              right: 0, 
              bottom: 0, 
              child: FeedbackBottomSheet(
                isCorrect: _feedbackIsCorrect,
                explanation: _feedbackExplanation,
                onContinue: _fetchNextQuestion,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
