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
import '../../widgets/cozy/coin_particle.dart';
import '../../widgets/quiz/feedback_bottom_sheet.dart';
import '../../widgets/quiz/promotion_overlay.dart';
import '../../widgets/questions/question_renderer_registry.dart';
import '../../services/audio_provider.dart';
import 'package:flutter/services.dart';
import '../../services/question_cache_service.dart';
import '../../database/database.dart';
import 'package:drift/drift.dart' hide Column;

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

  // Promotion Overlay State
  int? _promotionNewLevel;
  bool _showPromotionOverlay = false;

  // Coin Particle State
  final List<Widget> _coinParticles = [];

  // Progress Bar Pulse
  final PulseNotifier _progressPulseNotifier = PulseNotifier();

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
      _loadInitialProgress();
      _startQuizSession();
    }

    // 🎵 ENFORCE MUSIC: If we came from somewhere quiet/broken, restart the vibe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).ensureMusicPlaying();
      _focusNode.requestFocus();
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
      if (_remainingMistakeIds != null) {
        // Mistake review logic (keep as is)
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
        // 🚀 CACHE-FIRST LOGIC
        final cache =
            Provider.of<QuestionCacheService>(context, listen: false);
        Map<String, dynamic>? q = cache.next();

        if (q != null) {
          debugPrint("⚡ UI: Cache hit! Loading question instantly.");
          _setQuestion(q);
        } else {
          debugPrint("⏳ UI: Cache empty. Developing waiting strategy...");
          
          // If cache is empty, we have two options: 
          // 1. Wait for cache (if it's fetching)
          // 2. Direct fetch (fallback)
          
          // For now, let's try a direct fetch as fallback to ensure we never block
          final String endpoint =
              '${ApiEndpoints.quizNext}?topic=${widget.systemSlug}';
          q = await _apiService.get(endpoint);

          if (q != null) {
             _setQuestion(q);
             // Update local cache stat in background
             _updateLocalStatCache(q);
          } else {
            _showCompletionDialog();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching question: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setQuestion(Map<String, dynamic> q) {
    setState(() {
      _currentQuestion = q;
      _isLoading = false;
    });
  }


  Future<void> _loadInitialProgress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId == null) return;

    try {
      final existing = await (_db.select(_db.topicProgress)
            ..where((t) =>
                t.userId.equals(userId) &
                t.topicSlug.equals(widget.systemSlug)))
          .getSingleOrNull();

      if (existing != null && mounted) {
        setState(() {
          // Assuming 20 is the streak target for a level
          _levelProgress = (existing.currentStreak / 20.0).clamp(0.0, 1.0);
          debugPrint("📋 Persistence: Loaded progress for ${widget.systemSlug}: $_levelProgress");
        });
      }
    } catch (e) {
      debugPrint("❌ Persistence Load Error: $e");
    }
  }

  bool _isActuallySubmitting = false;

  Future<void> _submitAnswer() async {
    if (_isAnswerChecked ||
        _isActuallySubmitting ||
        _sessionId == null ||
        _currentQuestion == null ||
        _userAnswer == null) {
      return;
    }

    _isActuallySubmitting = true;

    // 1. Instant Local Check (Visual/Audio)
    final q = _currentQuestion!;
    final qType = q['question_type'] ?? 'single_choice';
    final renderer = QuestionRendererRegistry.getRenderer(qType);
    final formattedAnswer = renderer.formatAnswer(_userAnswer);

    // If backend sent the answer (optimized flow), show feedback immediately
    if (q.containsKey('correct_answer')) {
      final bool localIsCorrect =
          renderer.validateAnswer(_userAnswer, q['correct_answer']);

      setState(() {
        _isAnswerChecked = true;
        _feedbackIsCorrect = localIsCorrect;
        _correctAnswerFromServer = q['correct_answer'];
        _showFeedback = true;

        final locale = Localizations.localeOf(context).languageCode;
        String baseExplanation = "";

        if (locale == 'hu' && q['explanation_hu'] != null) {
          baseExplanation = q['explanation_hu'];
        } else if (q['explanation_en'] != null) {
          baseExplanation = q['explanation_en'];
        } else {
          baseExplanation = q['explanation'] ?? "No explanation available.";
        }

        if (!localIsCorrect) {
          final label = (locale == 'hu') ? "Helyes válasz" : "Correct answer";
          // Helper to format correct answer for display
          String displayAnswer = q['correct_answer'].toString();
          if (q['correct_answer'] is List) {
            displayAnswer = (q['correct_answer'] as List).join(", ");
          }
          _feedbackExplanation = "$label: **$displayAnswer**\n\n$baseExplanation";
        } else {
          _feedbackExplanation = baseExplanation;
        }

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
      // Keep state for UI spinner if needed, but primary guard is above
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

        final locale = Localizations.localeOf(context).languageCode;
        if (locale == 'en' && response['explanation_en'] != null) {
          _feedbackExplanation = response['explanation_en'];
        } else if (locale == 'hu' && response['explanation_hu'] != null) {
          _feedbackExplanation = response['explanation_hu'];
        } else {
          _feedbackExplanation =
              response['explanation'] ?? "No explanation available.";
        }
        _correctAnswerFromServer = response['correctAnswer'];
        _levelProgress = (response['streakProgress'] as num).toDouble();

        if (response['event'] == 'PROMOTION' ||
            response['event'] == 'LEVEL_UNLOCKED') {
          _confettiController.blast();
          _promotionNewLevel = (response['newLevel'] as num?)?.toInt() ?? 1;
          _showPromotionOverlay = true;
          // Haptics for bigger celebration
          HapticFeedback.heavyImpact();
        }

        // Spawn coin particle on correct answer
        if (response['isCorrect'] == true) {
          final coinsEarned = (response['coinsEarned'] as num?)?.toInt() ?? 1;
          _spawnCoinParticle(coinsEarned);
          _progressPulseNotifier.pulse(); // Trigger progress bar pulse
        }

        _isActuallySubmitting = false;
      });

      // 3. Update Local Cache (Fire & Forget)
      _updateLocalProgressCache(response);
      auth.refreshUser(); // Refresh coins/streak from server
    } catch (e) {
      debugPrint("Error submitting answer: $e");
      // Optional: Show "Offline" retry or just fall back to local if we want to keep hybrid
      setState(() {
        _isActuallySubmitting = false;
        _isAnswerChecked = true;
        _showFeedback = true; // FORCE SHOW FEEDBACK
        _feedbackIsCorrect = false; // Error context
        _feedbackExplanation =
            "Submission failed. Please check your connection.";
      });
    }
  }

  Future<void> _updateLocalStatCache(Map<String, dynamic> q) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId == null) return;

    await _syncTopicProgress(
      userId,
      (q['streak'] as num?)?.toInt() ?? 0,
      (q['coverage'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _updateLocalProgressCache(Map<String, dynamic> result) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId == null) return;

    await _syncTopicProgress(
      userId,
      (result['streak'] as num?)?.toInt() ?? 0,
      (result['coverage'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _syncTopicProgress(int userId, int streak, int mastery) async {
    try {
      final existing = await (_db.select(_db.topicProgress)
            ..where((t) =>
                t.userId.equals(userId) &
                t.topicSlug.equals(widget.systemSlug)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.topicProgress)..where((t) => t.id.equals(existing.id)))
            .write(
          TopicProgressCompanion(
            currentStreak: Value(streak),
            masteryScore: Value(mastery),
            lastStudiedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await _db.into(_db.topicProgress).insert(
              TopicProgressCompanion.insert(
                userId: Value(userId),
                topicSlug: Value(widget.systemSlug),
                currentStreak: Value(streak),
                masteryScore: Value(mastery),
                lastStudiedAt: Value(DateTime.now()),
              ),
            );
      }
    } catch (e) {
      debugPrint("❌ Database Sync Error: $e");
    }
  }

  void _exitQuiz() {
    Navigator.pop(context);
  }

  /// Spawns a floating "+X" particle when coins are earned
  void _spawnCoinParticle(int amount) {
    if (amount <= 0) return;
    final key = UniqueKey();
    setState(() {
      _coinParticles.add(
        Positioned(
          top: 60, // Near coin counter
          left: 20,
          child: CoinParticle(
            key: key,
            amount: amount,
            onComplete: () {
              setState(() {
                _coinParticles.removeWhere((w) => w.key == key);
              });
            },
          ),
        ),
      );
    });
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
        focusNode: _focusNode,
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

            // Coin Particles Layer
            ..._coinParticles,

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header (Coins & Close)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🏁 Integrated Motivational Hub
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: palette.paperWhite.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: palette.textPrimary.withValues(alpha: 0.05))
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                          'assets/ui/buttons/stethoscope_hud.png',
                                          width: 18,
                                          height: 18),
                                      const SizedBox(width: 6),
                                      Text("$totalCoins",
                                          style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: palette.secondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Minimal Close
                            GestureDetector(
                              onTap: _exitQuiz,
                              child: Icon(Icons.close_rounded,
                                  size: 24, color: palette.textSecondary.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Slimmer, Sleeker Progress
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: CozyProgressBar(
                                current: (_levelProgress * 100).toInt(),
                                total: 100,
                                height: 10,
                                pulseNotifier: _progressPulseNotifier,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              "Level Progress",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: palette.textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              "${(_levelProgress * 20).round()} / 20",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: palette.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
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
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 500),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder: (Widget child, Animation<double> animation) {
                                            final inAnimation = Tween<Offset>(
                                              begin: const Offset(1.2, 0.0),
                                              end: const Offset(0.0, 0.0),
                                            ).animate(animation);

                                            final outAnimation = Tween<Offset>(
                                              begin: const Offset(-1.2, 0.0),
                                              end: const Offset(0.0, 0.0),
                                            ).animate(animation);

                                            if (child.key == ValueKey(_currentQuestion?['id'])) {
                                              return SlideTransition(
                                                position: inAnimation,
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            } else {
                                              return SlideTransition(
                                                position: outAnimation,
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            }
                                          },
                                          child: CozyCard(
                                            key: ValueKey(_currentQuestion?['id']),
                                            title: widget.systemName.toUpperCase(),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // Delegate Content Rendering
                                                renderer.buildQuestion(
                                                    context, _currentQuestion!),

                                                const SizedBox(height: 24),

                                                // Delegate Answer Input Rendering
                                                renderer.buildAnswerInput(
                                                  context,
                                                  _currentQuestion!,
                                                  _userAnswer,
                                                  _isAnswerChecked
                                                      ? (_) {}
                                                      : (val) {
                                                          setState(() {
                                                            _userAnswer = val;
                                                          });
                                                          // Auto-submit for specific types
                                                          if (qType == 'single_choice' ||
                                                              qType == 'true_false') {
                                                            _submitAnswer();
                                                          }
                                                        },
                                                  isChecked: _isAnswerChecked,
                                                  correctAnswer:
                                                      _correctAnswerFromServer,
                                                ),

                                                const SizedBox(height: 32),
                                                // Submit Button
                                                if (!(qType == 'single_choice' ||
                                                    qType == 'true_false'))
                                                  LiquidButton(
                                                    label: "Submit Answer",
                                                    onPressed: hasAnswer &&
                                                            !_isAnswerChecked &&
                                                            !_isActuallySubmitting
                                                        ? _submitAnswer
                                                        : null,
                                                    variant: hasAnswer
                                                        ? LiquidButtonVariant.primary
                                                        : LiquidButtonVariant.outline,
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

            // 4. Enhanced Promotion Overlay
            if (_showPromotionOverlay && _promotionNewLevel != null)
              PromotionOverlay(
                newLevel: _promotionNewLevel!,
                onDismiss: () {
                  setState(() {
                    _showPromotionOverlay = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _progressPulseNotifier.dispose();
    super.dispose();
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
