import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/cozy/cozy_card.dart';
import '../../widgets/cozy/liquid_button.dart';
import '../../widgets/cozy/cozy_progress_bar.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/cozy/confetti_overlay.dart'; 
import '../../widgets/quiz/feedback_bottom_sheet.dart'; 
import '../../widgets/questions/question_renderer_registry.dart'; 
import '../../services/audio_provider.dart';
import 'package:flutter/services.dart';
import '../../services/question_cache_service.dart';

class QuizSessionScreen extends StatefulWidget {
  final String systemName;
  final String systemSlug;
  final List<int>? questionIds;

  const QuizSessionScreen({
    super.key, 
    required this.systemName, 
    required this.systemSlug,
    this.questionIds,
  });

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
  dynamic _correctAnswerFromServer;
  double _levelProgress = 0.0;
  
  // Feedback State
  final ConfettiController _confettiController = ConfettiController(); 
  
  bool _showFeedback = false;
  bool _feedbackIsCorrect = false;
  String _feedbackExplanation = "";

  // For Mistake Review Mode
  List<int>? _remainingMistakeIds;
  int _totalMistakes = 0;
  bool _isReviewFinished = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.questionIds != null && widget.questionIds!.isNotEmpty) {
      _remainingMistakeIds = List.from(widget.questionIds!);
      _totalMistakes = _remainingMistakeIds!.length;
    }
    
    // 🚀 Snappy UX: Init cache for the selected topic
    if (widget.questionIds == null) {
      Provider.of<QuestionCacheService>(context, listen: false).init(widget.systemSlug);
    }
    
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
      if (_remainingMistakeIds != null) {
        if (_remainingMistakeIds!.isEmpty) {
          setState(() {
            _isReviewFinished = true;
            _isLoading = false;
          });
          return;
        }

        final nextId = _remainingMistakeIds!.first;
        final q = await _apiService.get('/quiz/questions/$nextId');
        _remainingMistakeIds!.removeAt(0);        
        setState(() {
          _currentQuestion = q;
          _levelProgress = (_totalMistakes - _remainingMistakeIds!.length - 1) / _totalMistakes;
          _isLoading = false;
        });
      } else {
        // 🚀 Snappy UX: Get next question from cache
        final cache = Provider.of<QuestionCacheService>(context, listen: false);
        Map<String, dynamic>? q = cache.next();
        
        // If cache missed (unlikely but possible), fallback to direct API
        if (q == null) {
          debugPrint("📡 Quiz: Cache miss, pulling direct...");
          q = await _apiService.get('/quiz/next?topic=${widget.systemSlug}');
        }

        setState(() {
          _currentQuestion = q;
          if (q != null) {
            _levelProgress = (q['coverage'] != null) ? (q['coverage'] as num).toDouble() / 100.0 : _levelProgress;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching question: $e");
      setState(() { _isLoading = false; });
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitAnswer() async {
    if (_isAnswerChecked || _isSubmitting || _sessionId == null || _currentQuestion == null || _userAnswer == null) return;
    
    // 1. Instant Local Check (Visual/Audio)
    final q = _currentQuestion!;
    final qType = q['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final formattedAnswer = renderer.formatAnswer(_userAnswer);

    // If backend sent the answer (optimized flow), show feedback immediately
    if (q.containsKey('correct_answer')) {
      final uNorm = (formattedAnswer?.toString() ?? "").trim().toLowerCase();
      final cNorm = (q['correct_answer']?.toString() ?? "").trim().toLowerCase();
      final localIsCorrect = (uNorm == cNorm);

      setState(() {
        _isAnswerChecked = true;
        _feedbackIsCorrect = localIsCorrect;
        // Expose the known correct answer to the renderer so it can
        // immediately color the selected option correctly (avoid
        // briefly showing it as wrong before server response).
        _correctAnswerFromServer = q['correct_answer'];
        
        // Play SFX instantly
        final audio = Provider.of<AudioProvider>(context, listen: false);
        if (localIsCorrect) {
          audio.playSfx('success');
        } else {
          audio.playSfx('pop');
          HapticFeedback.vibrate(); // 📳 Haptic hit for mistake
        }
      });
    }

    setState(() {
      _isSubmitting = true; 
    });

    try {
      final result = await _apiService.post('/quiz/answer', {
        'sessionId': _sessionId,
        'questionId': _currentQuestion!['id'],
        'userAnswer': formattedAnswer,
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
        _correctAnswerFromServer = result['correctAnswer'];

        // Only update progress from backend if NOT in "Mistake Review" mode
        // In review mode, we calculate progress locally (1 - remaining/total).
        if (_remainingMistakeIds == null) {
          _levelProgress = (result['coverage'] != null) ? (result['coverage'] as num).toDouble() / 100.0 : _levelProgress;
        }

        // Play SFX only if we didn't do it locally
        if (!q.containsKey('correct_answer')) {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          if (_feedbackIsCorrect) {
            audio.playSfx('success');
          } else {
            audio.playSfx('pop');
            HapticFeedback.vibrate(); // 📳 Haptic hit for mistake
          }
        }

        // 🚀 Snappy UX: Notify cache that we just consumed a question
        Provider.of<QuestionCacheService>(context, listen: false).notifyAnswered();
      });

    } catch (e) {
      debugPrint("Error submitting answer: $e");
      setState(() {
        _isSubmitting = false;
        _isAnswerChecked = q.containsKey('correct_answer') ? true : false; 
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

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // 1. Space: Next or Submit
    if (key == LogicalKeyboardKey.space) {
      if (_showFeedback) {
        _fetchNextQuestion();
      } else {
        _submitAnswer();
      }
      return;
    }

    // 2. Numbers 1-9: Select Answer
    if (!_isAnswerChecked && _currentQuestion != null) {
      int? index;
      if (key == LogicalKeyboardKey.digit1) {
        index = 0;
      } else if (key == LogicalKeyboardKey.digit2) {
        index = 1;
      } else if (key == LogicalKeyboardKey.digit3) {
        index = 2;
      } else if (key == LogicalKeyboardKey.digit4) {
        index = 3;
      } else if (key == LogicalKeyboardKey.digit5) {
        index = 4;
      } else if (key == LogicalKeyboardKey.digit6) {
        index = 5;
      } else if (key == LogicalKeyboardKey.digit7) {
        index = 6;
      } else if (key == LogicalKeyboardKey.digit8) {
        index = 7;
      } else if (key == LogicalKeyboardKey.digit9) {
        index = 8;
      }

      if (index != null) {
        final q = _currentQuestion!;
        final qType = q['question_type'] ?? 'single_choice';
        final renderer = QuestionRendererRegistry.getRenderer(qType);
        final newAnswer = renderer.getAnswerForIndex(context, q, index, _userAnswer);
        
        if (newAnswer != _userAnswer) {
          setState(() {
            _userAnswer = newAnswer;
          });
          
          // Auto-submit for specific types (matching logic in build)
          if (qType == 'single_choice' || qType == 'true_false') {
             // Small delay to let the user see the selection? 
             // Existing code calls it immediately.
             _submitAnswer();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
      backgroundColor: CozyTheme.background,
      body: Center(child: CircularProgressIndicator(color: CozyTheme.primary))
    );
    }

    if (_isReviewFinished) {
      return Scaffold(
        backgroundColor: CozyTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: CozyTheme.primary, size: 80),
              const SizedBox(height: 24),
              Text(
                "REVIEW COMPLETE!",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: CozyTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                "You've addressed all your mistakes from this period.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: CozyTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              LiquidButton(
                label: "CONTINUE",
                onPressed: _exitQuiz,
                fullWidth: false,
              ),
            ],
          ),
        ),
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
      body: KeyboardListener(
        focusNode: _focusNode..requestFocus(),
        autofocus: true,
        onKeyEvent: _handleKeyPress,
        child: Stack(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        Row(
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
                        const SizedBox(height: 12),
                        CozyProgressBar(
                          current: (_levelProgress * 100).toInt(),
                          total: 100,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
  
                  // 2. The Question Card
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(_currentQuestion!['id']),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1.0 - value)),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
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
                                              // Auto-submit for specific types
                                              if (qType == 'single_choice' || qType == 'true_false') {
                                                _submitAnswer();
                                              }
                                            },
                                            isChecked: _isAnswerChecked,
                                            correctAnswer: _correctAnswerFromServer,
                                          ),
                                
                                          const SizedBox(height: 32),
                                          // Submit Button
                                          if (!(qType == 'single_choice' || qType == 'true_false'))
                                            LiquidButton(
                                              label: "Submit Answer",
                                              onPressed: hasAnswer && !_isAnswerChecked && !_isSubmitting ? _submitAnswer : null,
                                              variant: hasAnswer ? LiquidButtonVariant.primary : LiquidButtonVariant.outline,
                                              fullWidth: true,
                                              icon: Icons.send_rounded,
                                            ),
                                        ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}
