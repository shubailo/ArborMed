import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/cozy_theme.dart';
import '../../constants/api_endpoints.dart';
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
import '../../database/database.dart';
import 'package:drift/drift.dart' show Value, DoUpdate, Constant;

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
      final double initialProgress =
          (widget.initialData?['streakProgress'] != null)
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
      Provider.of<QuestionCacheService>(context, listen: false)
          .init(widget.systemSlug);
    }

    if (widget.initialData == null) {
      _startQuizSession();
    }

    // 🎵 ENFORCE MUSIC: If we came from somewhere quiet/broken, restart the vibe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).ensureMusicPlaying();
    });
  }

  Future<void> _startQuizSession() async {
    try {
      // Optimistic: Try network, but don't block
      _apiService.post(ApiEndpoints.quizStart, {}).then((session) {
        if (mounted) {
          setState(() {
            _sessionId = session['id'].toString();
          });
        }
      }).catchError((e) {
        debugPrint("Offline Session: Using local ID");
      });

      // Immediate start with local ID fallback
      if (_sessionId == null) {
        setState(() {
          _sessionId = "local_${DateTime.now().millisecondsSinceEpoch}";
        });
      }

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
      Provider.of<AuthProvider>(context, listen: false);

      if (_remainingMistakeIds != null) {
        // Mistake review logic (keep as is or migrate to local too?)
        // For now, let's keep it remote-or-bundled if IDs are provided.
        if (_remainingMistakeIds!.isEmpty) {
          setState(() {
            _isReviewFinished = true;
            _isLoading = false;
          });
          return;
        }
        final nextId = _remainingMistakeIds!.first;
        final q = await _apiService.get('${ApiEndpoints.quizQuestions}/$nextId');
        _remainingMistakeIds!.removeAt(0);
        setState(() {
          _currentQuestion = q;
          _levelProgress = (_totalMistakes - _remainingMistakeIds!.length - 1) /
              _totalMistakes;
          _isLoading = false;
        });
      } else {
        // 🚀 API-FIRST LOGIC
        final String endpoint = '${ApiEndpoints.quizNext}?topic=${widget.systemSlug}';
        final q = await _apiService.get(endpoint);

        if (q != null) {
          setState(() {
            _currentQuestion = q;
            _levelProgress = (q['streakProgress'] != null)
                ? (q['streakProgress'] as num).toDouble()
                : 0.0;
            _isLoading = false;
          });
          // Update local cache in background
          _updateLocalStatCache(q);
        } else {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      debugPrint("Error fetching question: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitAnswer() async {
    if (_isAnswerChecked ||
        _isSubmitting ||
        _sessionId == null ||
        _currentQuestion == null ||
        _userAnswer == null) {
      return;
    }

    // 1. Instant Local Check (Visual/Audio)
    final q = _currentQuestion!;
    final qType = q['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final formattedAnswer = renderer.formatAnswer(_userAnswer);

    // If backend sent the answer (optimized flow), show feedback immediately
    if (q.containsKey('correct_answer')) {
      final uNorm = (formattedAnswer?.toString() ?? "").trim().toLowerCase();
      final cNorm =
          (q['correct_answer']?.toString() ?? "").trim().toLowerCase();
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

      // 1. Submit to API (Truth)
      final response = await _apiService.post(ApiEndpoints.quizAnswer, {
        'sessionId': _sessionId,
        'questionId': _currentQuestion!['id'],
        'userAnswer': formattedAnswer,
        'responseTimeMs': 1000
      });

      if (response == null) {
        throw Exception("No response from server");
      }

      // 2. Update UI with Server Result
      setState(() {
        _isAnswerChecked = true;
        _showFeedback = true;
        _feedbackIsCorrect = response['isCorrect'] ?? false;
        _feedbackExplanation =
            response['explanation'] ?? "No explanation available.";
        _correctAnswerFromServer = response['correctAnswer'];
        _levelProgress = (response['streakProgress'] as num).toDouble();

        if (response['climber']?['event'] == 'PROMOTION' ||
            response['climber']?['event'] == 'LEVEL_UNLOCKED') {
          _confettiController.blast();
          _showLevelUpToast(response['climber']['newLevel']);
        }

        _isSubmitting = false;
      });

      // 3. Update Local Cache (Fire & Forget)
      _updateLocalProgressCache(response);
      auth.refreshUser(); // Refresh coins/streak from server
    } catch (e) {
      debugPrint("Error submitting answer: $e");
      // Optional: Show "Offline" retry or just fall back to local if we want to keep hybrid
      setState(() {
        _isSubmitting = false;
        _isAnswerChecked = true;
        _feedbackExplanation =
            "Submission failed. Please check your connection.";
      });
    }
  }

  Future<void> _updateLocalStatCache(Map<String, dynamic> q) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId == null) return;

    // Update Topic Progress Cache using proper upsert for {userId, topicSlug}
    await _db.into(_db.topicProgress).insert(
          TopicProgressCompanion.insert(
            userId: Value(userId),
            topicSlug: Value(widget.systemSlug),
            masteryScore: Value(((q['coverage'] as num?)?.toInt() ?? 0)),
            currentStreak: Value(((q['streak'] as num?)?.toInt() ?? 0)),
          ),
          onConflict: DoUpdate((old) => TopicProgressCompanion.custom(
            masteryScore: Constant(((q['coverage'] as num?)?.toInt() ?? 0)),
            currentStreak: Constant(((q['streak'] as num?)?.toInt() ?? 0)),
          )),
        );
  }

  Future<void> _updateLocalProgressCache(Map<String, dynamic> result) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId == null) return;

    // Update Topic Progress Cache using proper upsert for {userId, topicSlug}
    await _db.into(_db.topicProgress).insert(
          TopicProgressCompanion.insert(
            userId: Value(userId),
            topicSlug: Value(widget.systemSlug),
            masteryScore: Value(((result['coverage'] as num?)?.toInt() ?? 0)),
            currentStreak: Value(((result['streak'] as num?)?.toInt() ?? 0)),
          ),
          onConflict: DoUpdate((old) => TopicProgressCompanion.custom(
            masteryScore: Constant(((result['coverage'] as num?)?.toInt() ?? 0)),
            currentStreak: Constant(((result['streak'] as num?)?.toInt() ?? 0)),
          )),
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
        final newAnswer =
            renderer.getAnswerForIndex(context, q, index, _userAnswer);

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
              Icon(Icons.check_circle_outline,
                  color: palette.primary, size: 80),
              const SizedBox(height: 24),
              Text(
                "REVIEW COMPLETE!",
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: palette.paperWhite,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: palette.textPrimary
                                            .withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Row(
                                children: [
                                  Image.asset(
                                      'assets/ui/buttons/stethoscope_hud.png',
                                      width: 20,
                                      height: 20),
                                  const SizedBox(width: 6),
                                  Text("$totalCoins",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: palette.secondary)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _exitQuiz,
                              child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: palette.paperWhite,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.close,
                                      size: 20, color: palette.textSecondary)),
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
                        ? Center(
                            child: CircularProgressIndicator(
                                color: CozyTheme.of(context).primary))
                        : _currentQuestion == null
                            ? Center(
                                child: Text("No questions found!",
                                    style: TextStyle(
                                        color: palette.textSecondary)))
                            : Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 20, 16, 24),
                                      child: Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 600),
                                        child: TweenAnimationBuilder<double>(
                                          key:
                                              ValueKey(_currentQuestion!['id']),
                                          duration:
                                              const Duration(milliseconds: 600),
                                          curve: Curves.elasticOut,
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Transform.translate(
                                              offset:
                                                  Offset(0, 30 * (1.0 - value)),
                                              child: Opacity(
                                                opacity: value.clamp(0.0, 1.0),
                                                child: CozyCard(
                                                  title: widget.systemName
                                                      .toUpperCase(),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      // Delegate Content Rendering
                                                      renderer.buildQuestion(
                                                          context,
                                                          _currentQuestion!),

                                                      const SizedBox(
                                                          height: 24),

                                                      // Delegate Answer Input Rendering
                                                      renderer.buildAnswerInput(
                                                        context,
                                                        _currentQuestion!,
                                                        _userAnswer,
                                                        _isAnswerChecked
                                                            ? (_) {}
                                                            : (val) {
                                                                setState(() {
                                                                  _userAnswer =
                                                                      val;
                                                                });
                                                                // Auto-submit for specific types
                                                                if (qType ==
                                                                        'single_choice' ||
                                                                    qType ==
                                                                        'true_false') {
                                                                  _submitAnswer();
                                                                }
                                                              },
                                                        isChecked:
                                                            _isAnswerChecked,
                                                        correctAnswer:
                                                            _correctAnswerFromServer,
                                                      ),

                                                      const SizedBox(
                                                          height: 32),
                                                      // Submit Button
                                                      if (!(qType ==
                                                              'single_choice' ||
                                                          qType ==
                                                              'true_false'))
                                                        LiquidButton(
                                                          label:
                                                              "Submit Answer",
                                                          onPressed: hasAnswer &&
                                                                  !_isAnswerChecked &&
                                                                  !_isSubmitting
                                                              ? _submitAnswer
                                                              : null,
                                                          variant: hasAnswer
                                                              ? LiquidButtonVariant
                                                                  .primary
                                                              : LiquidButtonVariant
                                                                  .outline,
                                                          fullWidth: true,
                                                          icon: Icons
                                                              .send_rounded,
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
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: CozyTheme.of(context)
                                                    .primary)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber),
          const SizedBox(width: 12),
          Text(
            "PROMOTED TO LEVEL $newLevel!",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Session Complete"),
        content: const Text(
            "You've completed all available questions for this topic right now! Come back later for spaced repetition."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('Return to Room'),
          )
        ],
      ),
    );
  }
}
