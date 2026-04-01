import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arbormed_core/arbormed_core.dart' hide Question, QuestType;
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/choice_card.dart';
import '../widgets/feedback_sheet.dart';
import '../../services/quiz_service.dart';

class QuizSessionScreen extends StatefulWidget {
  final String topicId;
  final List<int>? questionIds;
  const QuizSessionScreen({super.key, required this.topicId, this.questionIds});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> with WidgetsBindingObserver {
  String? _selectedChoiceId;
  bool _isAnswered = false;
  bool _isCorrect = false;
  
  // Interaction lock
  bool _isLocked = false;
  DateTime? _lastSubmitTime;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _effectSubscription;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.requestFocus();
    _startSession();
    _subscribeToEffects();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _effectSubscription?.cancel();
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _subscribeToEffects() {
    final quiz = GetIt.I<QuizService>();
    _effectSubscription = quiz.effects.listen((effect) async {
       switch (effect.type) {
         case QuizEffectType.hapticSuccess:
           HapticFeedback.mediumImpact();
           await _audioPlayer.play(AssetSource('audio/success.mp3'));
           break;
         case QuizEffectType.hapticError:
           HapticFeedback.lightImpact();
           await _audioPlayer.play(AssetSource('audio/incorrect.mp3'));
           break;
         case QuizEffectType.coins:
           // Future: Spawn Coin Particles
           break;
         default: break;
       }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final quiz = GetIt.I<QuizService>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      quiz.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      quiz.resumeTimer();
    }
  }

  void _startSession() {
    final quiz = GetIt.I<QuizContract>();
    quiz.startSession(widget.topicId, questionIds: widget.questionIds);
  }

  void _handleSubmit() async {
    if (_selectedChoiceId == null || _isLocked) return;
    
    // Interaction lock guard
    if (_lastSubmitTime != null && DateTime.now().difference(_lastSubmitTime!).inMilliseconds < 500) return;
    
    setState(() => _isLocked = true);
    _lastSubmitTime = DateTime.now();
    
    final quiz = GetIt.I<QuizContract>();
    final correct = await quiz.submitAnswer(_selectedChoiceId!);
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });
  }

  void _handleNext() {
    final quiz = GetIt.I<QuizContract>();
    setState(() {
      _isAnswered = false;
      _selectedChoiceId = null;
      _isCorrect = false;
      _isLocked = false;
    });
    quiz.nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = GetIt.I<QuizContract>() as ChangeNotifier;
    final theme = CozyTheme.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (_isAnswered) {
            _handleNext();
          } else {
            _handleSubmit();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.background,
        body: ListenableBuilder(
          listenable: quiz,
          builder: (context, _) {
            final session = GetIt.I<QuizContract>();
            if (session.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final question = session.currentQuestion;
            if (question == null) {
              return const Center(child: Text('No questions found.'));
            }

            if (session.currentSession?.isFinished ?? false) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 context.pushReplacement('/quiz/results');
               });
               return const SizedBox.shrink();
            }

            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, session),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetadataChips(context, question),
                          const SizedBox(height: 16),
                          _buildQuestionBody(context, question),
                          const SizedBox(height: 32),
                          _buildChoiceList(context, question),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomAction(context, session),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QuizContract session) {
    final theme = CozyTheme.of(context);
    final progress = session.currentSession?.progress ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: theme.background,
                  color: theme.primary,
                ),
              ),
            ),
          ),
          Text(
            '${(session.currentSession?.currentIndex ?? 0) + 1}/${session.currentSession?.totalQuestions ?? 0}',
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips(BuildContext context, Question question) {
    final theme = CozyTheme.of(context);
    return Wrap(
      spacing: 8,
      children: [
        _buildChip(context, 'BLOOM ${question.bloomLevel}', theme.primary),
        _buildChip(context, question.difficulty.toUpperCase(), _getDifficultyColor(question.difficulty)),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    final theme = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.blue;
    }
  }

  Widget _buildQuestionBody(BuildContext context, Question question) {
    final theme = CozyTheme.of(context);
    return Text(question.text, style: theme.headingLarge);
  }

  Widget _buildChoiceList(BuildContext context, Question question) {
    return Column(
      children: question.choices.map((choice) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ChoiceCard(
            choice: choice,
            isSelected: _selectedChoiceId == choice.id,
            isCorrect: _isAnswered && question.correctAnswer == choice.id,
            isWrong: _isAnswered && _selectedChoiceId == choice.id && !_isCorrect,
            onTap: (_isAnswered || _isLocked) ? null : () {
              setState(() {
                _selectedChoiceId = choice.id;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction(BuildContext context, QuizContract session) {
    final theme = CozyTheme.of(context);

    if (_isAnswered) {
      return FeedbackSheet(
        isCorrect: _isCorrect,
        explanation: session.currentQuestion?.explanation,
        onNext: _handleNext,
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_selectedChoiceId == null || _isLocked) ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLocked && !_isAnswered 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Check Answer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
