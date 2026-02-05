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
import '../../services/local_adaptive_engine.dart';
import '../../services/sync_service.dart';
import '../../database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:convert'; // For jsonEncode

class QuizSessionScreen extends StatefulWidget {
  final String systemName;
  final String systemSlug;
  final List<int>? questionIds;
  final Map<String, dynamic>? initialData;
  final String? sessionId;

  const QuizSessionScreen({
    super.key, 
    required this.systemName, 
    required this.systemSlug,
    this.questionIds,
    this.initialData,
    this.sessionId,
  });

  @override
  createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  String? _sessionId;
  final LocalAdaptiveEngine _localEngine = LocalAdaptiveEngine();
  final SyncService _syncService = SyncService();
  final AppDatabase _db = AppDatabase();
  
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
    
    // 🚀 Instantly Boot if data was pre-fetched!
    if (widget.initialData != null) {
      _currentQuestion = widget.initialData;
      _sessionId = widget.sessionId;
      _isLoading = false;
      
      // Sync progress from pre-fetched data
      final double initialProgress = (widget.initialData?['streakProgress'] != null) 
          ? (widget.initialData?['streakProgress'] as num).toDouble() 
          : 0.0;
      _levelProgress = initialProgress;

      // If we got an error from the pre-fetcher, handle it
      if (_currentQuestion!.containsKey('error')) {
        _isLoading = false;
      }
    }

    // 🚀 Snappy UX: Init cache for the selected topic
    if (widget.questionIds == null) {
      Provider.of<QuestionCacheService>(context, listen: false).init(widget.systemSlug);
    }
    
    if (widget.initialData == null) {
      _startQuizSession();
    }
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
      _userAnswer = null;
      _isAnswerChecked = false;
      _showFeedback = false; 
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.id ?? 0;

      if (_remainingMistakeIds != null) {
        // Mistake review logic (keep as is or migrate to local too?)
        // For now, let's keep it remote-or-bundled if IDs are provided.
        if (_remainingMistakeIds!.isEmpty) {
          setState(() { _isReviewFinished = true; _isLoading = false; });
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
        // 🚀 NEW LOCAL-FIRST LOGIC
        final localQ = await _localEngine.getNextQuestion(userId, widget.systemSlug);
        
        if (localQ != null) {
          // Convert LocalQuestion to Map (renderer expects Map)
          final qMap = {
            'id': localQ.serverId,
            'text': localQ.questionText,
            'question_type': localQ.type,
            'options': localQ.options,
            'correct_answer': localQ.correctAnswer,
            'explanation': localQ.explanation,
            'bloom_level': localQ.bloomLevel,
          };

          setState(() {
            _currentQuestion = qMap;
            _isLoading = false;
          });
        } else {
          // Fallback to API if local has no questions (maybe first run?)
          debugPrint("📡 Quiz: Local empty, pulling from Remote...");
          final q = await _apiService.get('/quiz/next?topic=${widget.systemSlug}');
          setState(() {
            _currentQuestion = q;
            _isLoading = false;
          });
        }
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
        }
      });
    }

    setState(() {
      _isSubmitting = true; 
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.id ?? 0;

      // 1. Local Process (Instant)
      final localResult = await _localEngine.processAnswerResult(
        userId, 
        widget.systemSlug, 
        _feedbackIsCorrect, 
        _currentQuestion!['id']
      );

      setState(() {
        _isAnswerChecked = true;
        _showFeedback = true;
        _feedbackExplanation = _feedbackIsCorrect ? "" : (_currentQuestion!['explanation'] ?? "Incorrect Answer.");
        _correctAnswerFromServer = _currentQuestion!['correct_answer'];
        _levelProgress = (localResult['coverage'] as num).toDouble() / 100.0;
        
        if (localResult['event'] == 'PROMOTION' || localResult['event'] == 'LEVEL_UNLOCKED') {
          _confettiController.blast();
          _showLevelUpToast(localResult['newLevel']);
        }
        
        _isSubmitting = false;
      });

      // 2. Queue for Sync (Up-Sync)
      await _db.into(_db.syncActions).insert(
        SyncActionsCompanion.insert(
          actionType: const Value('QUIZ_RESULT'),
          payload: Value(jsonEncode({
            'topicSlug': widget.systemSlug,
            'questionId': _currentQuestion!['id'],
            'isCorrect': _feedbackIsCorrect,
            'responseTimeMs': 1000,
          })),
          createdAt: Value(DateTime.now()),
        ),
      );
      
      // Trigger sync attempt
      _syncService.processQueue();

      // 3. Optional: Background Remote call for instant server sync if online
      _apiService.post('/quiz/answer', {
        'sessionId': _sessionId,
        'questionId': _currentQuestion!['id'],
        'userAnswer': formattedAnswer,
        'responseTimeMs': 1000 
       }).then((_) {
        auth.refreshUser();
      }).catchError((e) {
        debugPrint("Background sync failed: $e");
        return null; // Explicitly return null for FutureOr<Null>
      });

    } catch (e) {
      debugPrint("Error submitting answer: $e");
      setState(() {
        _isSubmitting = false;
        _isAnswerChecked = true; 
      });
    }
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
    final palette = CozyTheme.of(context);
    if (_isReviewFinished) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: palette.primary, size: 80),
              const SizedBox(height: 24),
              Text(
                "REVIEW COMPLETE!",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: palette.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                "You've addressed all your mistakes from this period.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: palette.textSecondary),
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

    final q = _currentQuestion;
    final user = Provider.of<AuthProvider>(context).user;
    final totalCoins = user?.coins ?? 0;
    
    // Determine Renderer
    final qType = q?['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final hasAnswer = q != null && renderer.hasAnswer(_userAnswer);

    return Scaffold(
      backgroundColor: palette.background,
      body: KeyboardListener(
        focusNode: _focusNode..requestFocus(),
        autofocus: true,
        onKeyEvent: _handleKeyPress,
        child: Stack(
          children: [
            // 0. Fluid Background Pattern
            Positioned.fill(
              child: FloatingMedicalIcons(
                color: CozyTheme.of(context).primary,
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
                                   Text("$totalCoins", style: TextStyle(fontWeight: FontWeight.bold, color: palette.secondary)),
                                 ],
                               ),
                             ),
                             GestureDetector(
                               onTap: _exitQuiz,
                               child: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                 child: Icon(Icons.close, size: 20, color: palette.textSecondary)
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
  
                  // 2. The Body (Question OR Loading OR Empty)
                  Expanded(
                    child: _isLoading && _currentQuestion == null
                      ? Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary))
                      : _currentQuestion == null
                        ? Center(child: Text("No questions found!", style: TextStyle(color: palette.textSecondary)))
                        : Stack(
                            children: [
                              Align(
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
                                                    renderer.buildQuestion(context, _currentQuestion!),
                                          
                                                    const SizedBox(height: 24),
                                          
                                                    // Delegate Answer Input Rendering
                                                    renderer.buildAnswerInput(
                                                      context, 
                                                      _currentQuestion!, 
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
                              
                              // Loading Overlay (Subtle)
                              if (_isLoading)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    child: Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary)),
                                  ),
                                ),
                            ],
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
  void _showLevelUpToast(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 12),
            Text(
              "PROMOTED TO LEVEL $newLevel!",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }
}
