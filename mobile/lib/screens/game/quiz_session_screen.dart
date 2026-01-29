import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import 'dart:convert'; // For jsonDecode
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/cozy/cozy_card.dart';
import '../../widgets/cozy/cozy_button.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/cozy/confetti_overlay.dart'; 
import '../../widgets/quiz/feedback_bottom_sheet.dart'; // Fixed import path
// Added for Haptics

class QuizSessionScreen extends StatefulWidget {
  final String systemName;
  final String systemSlug;

  const QuizSessionScreen({Key? key, required this.systemName, required this.systemSlug}) : super(key: key);

  @override
  _QuizSessionScreenState createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  String? _sessionId;
  
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;
  
  // Climber State
  int _currentBloomLevel = 1;

  // Feedback State
  int? _correctAnswerIndex;
  final ConfettiController _confettiController = ConfettiController(); 
  
  // Custom Overlay State
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
      print("Error starting session: $e");
    }
  }

  Future<void> _fetchNextQuestion() async {
    setState(() {
      if (_currentQuestion == null) _isLoading = true; // Only show spinner on first load
      _selectedOptionIndex = null;
      _isAnswerChecked = false;
      _correctAnswerIndex = null; // Reset
      _showFeedback = false; // Hide previous feedback
    });

    try {
      final q = await _apiService.get('/quiz/next?topic=${widget.systemSlug}');
      setState(() {
        _currentQuestion = q;
        _isLoading = false;
        if (q['bloom_level'] != null) {
            _currentBloomLevel = q['bloom_level'];
        }
      });
    } catch (e) {
      print("Error fetching question: $e");
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submitAnswer(int index) async {
    if (_isAnswerChecked || _sessionId == null || _currentQuestion == null) return;
    
    // Parse options for immediate UI usage
    List<dynamic> options = [];
    if (_currentQuestion!['options'] is String) {
        options = jsonDecode(_currentQuestion!['options']);
    } else {
        options = _currentQuestion!['options'];
    }
    final userAnswer = options[index];

    setState(() {
      _selectedOptionIndex = index;
      _isAnswerChecked = true; 
    });

    try {
      final result = await _apiService.post('/quiz/answer', {
        'sessionId': _sessionId,
        'questionId': _currentQuestion!['id'],
        'userAnswer': userAnswer,
        'userIndex': index, 
        'responseTimeMs': 1000 
      });

      // Update State from Result
      setState(() {
        if (result['correctAnswer'] is int) {
             _correctAnswerIndex = result['correctAnswer'];
        } else {
             _correctAnswerIndex = int.tryParse(result['correctAnswer'].toString());
        } 
        
        // Trigger global background refresh for coins/xp
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
        
        // Handle Climber Events
        if (result['climber'] != null) {
           final climber = result['climber'];
           _currentBloomLevel = climber['newLevel'];
           
           if (climber['event'] == 'PROMOTION') {
             _showOverlayMessage("LEVEL UP! Bloom Level $_currentBloomLevel 🧠🔥", Colors.amber[800]!);
             _confettiController.blast(); // Blast!
           } else if (climber['event'] == 'LEVEL_UNLOCKED') {
             _showOverlayMessage("NEW BLOOM LEVEL UNLOCKED! 🔓✨", Colors.purple[700]!); 
             _confettiController.blast(); // Blast!
           } else if (climber['event'] == 'DEMOTION') {
             _showOverlayMessage("Back to Basics. Level $_currentBloomLevel 🛡️", Colors.orange[800]!);
           } else if (climber['event'] == 'STREAK_EXTENDED') {
             // Subtle streak feedback can be added here if desired
           }
        }
        
        // 🔮 Update Feedback State instead of Modal
        // Wait a tiny bit for the red button animation to register visually
        Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() {
                _showFeedback = true;
                _feedbackIsCorrect = result['isCorrect'];
                _feedbackExplanation = result['isCorrect'] ? "" : (result['explanation'] ?? "Incorrect Answer.");
            });
        });

      });

    } catch (e) {
      print("Error submitting answer: $e");
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
    
    List<String> options = [];
    if (q['options'] is String) {
        options = List<String>.from(jsonDecode(q['options']));
    } else {
        options = List<String>.from(q['options']);
    }

    final user = Provider.of<AuthProvider>(context).user;
    final totalCoins = user?.coins ?? 0;

    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: Stack(
        children: [
          // 0. Fluid Background Pattern (Floating Icons)
          const Positioned.fill(
            child: FloatingMedicalIcons(
              color: CozyTheme.primary,
            ),
          ),

          // Confetti Layer (Top)
          ConfettiOverlay(controller: _confettiController),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Minimal Header (Coins Left, Close Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(20),
                           boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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

                  // 2. The Question Card (Single Unified Card)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: 24, 
                          bottom: _showFeedback ? 140 : 24, // Consistent padding
                          left: 24,
                          right: 24
                        ),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600), // Removed minHeight to prevent forced overflow
                          child: CozyCard(
                            title: widget.systemName.toUpperCase(),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Question Text (Animated)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      child: Text(
                                        q['text'] ?? "Question Text Missing",
                                        key: ValueKey<String>(q['text'] ?? ""), // Morph key
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.quicksand(
                                          fontSize: 24, 
                                          fontWeight: FontWeight.bold,
                                          color: CozyTheme.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                        
                                const SizedBox(height: 10),
                                Divider(color: CozyTheme.textSecondary.withOpacity(0.1)),
                                const SizedBox(height: 20),
                        
                                // Options List (Inside Card)
                                ...List.generate(options.length, (index) {
                                  bool isSelected = _selectedOptionIndex == index;
                                  CozyButtonVariant variant = CozyButtonVariant.outline;
                                  IconData? icon;
                        
                                  if (_isAnswerChecked && _correctAnswerIndex != null) {
                                      if (index == _correctAnswerIndex) {
                                          variant = CozyButtonVariant.primary; 
                                          icon = Icons.check_circle;
                                      } else if (isSelected && index != _correctAnswerIndex) {
                                          variant = CozyButtonVariant.secondary;
                                          icon = Icons.cancel;
                                      }
                                  } else if (isSelected) {
                                      variant = CozyButtonVariant.primary;
                                  }
                        
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: CozyButton(
                                        key: ValueKey<String>("btn_${index}_${options[index]}"), // Key per content
                                        label: options[index],
                                        variant: variant,
                                        fullWidth: true,
                                        icon: icon,
                                        onPressed: _isAnswerChecked ? null : () => _submitAnswer(index), 
                                        enabled: true, // Keep it vibrant even when not clickable
                                      ),
                                    ),
                                  );
                                }),
                        
                                const SizedBox(height: 10),

                                // Next Button (Hidden logic remains same)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: IgnorePointer(
                                    ignoring: !_isAnswerChecked,
                                    child: Opacity(
                                      opacity: _isAnswerChecked ? 1.0 : 0.5,
                                      child: SizedBox.shrink(), 
                                    ),
                                  ),
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
          ),

          // 3. Feedback Overlay (Duolingo Style)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0, 
            right: 0,
            bottom: _showFeedback ? 0 : -300, // Slide up/down
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
}
