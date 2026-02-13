import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/question_cache_service.dart';
import '../../theme/cozy_theme.dart';
import '../../database/database.dart';
import '../../widgets/cozy/floating_medical_icons.dart';
import '../../widgets/cozy/confetti_overlay.dart';
import '../../widgets/cozy/coin_particle.dart';
import '../../widgets/quiz/promotion_overlay.dart';
import '../../providers/quiz_controller.dart';
import '../../widgets/quiz/components/quiz_header.dart';
import '../../widgets/quiz/components/quiz_body.dart';
import '../../widgets/quiz/components/quiz_feedback_overlay.dart';
import '../../services/audio_provider.dart';
import '../../widgets/cozy/cozy_progress_bar.dart'; // Solves PulseNotifier error

class QuizSessionScreen extends StatelessWidget {
  final String systemName;
  final String systemSlug;
  final Map<String, dynamic>? initialData;
  final String? sessionId;
  final List<int>? questionIds; // Restored for Mistake Review

  const QuizSessionScreen({
    super.key,
    required this.systemName,
    required this.systemSlug,
    this.initialData,
    this.sessionId,
    this.questionIds,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return ChangeNotifierProvider(
      create: (context) => QuizController(
        apiService: ApiService(), 
        cacheService: Provider.of<QuestionCacheService>(context, listen: false),
        db: AppDatabase(), 
        systemSlug: systemSlug,
        systemName: systemName,
        userId: user!.id,
        initialQuestion: initialData,
        initialSessionId: sessionId,
        questionIds: questionIds, // Pass to controller
      ),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView();

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> with WidgetsBindingObserver {
  // Visual Effects Controllers
  final ConfettiController _confettiController = ConfettiController();
  final PulseNotifier _progressPulseNotifier = PulseNotifier();
  final List<Widget> _coinParticles = [];
  final FocusNode _focusNode = FocusNode();
  
  StreamSubscription? _effectSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _subscribeToEffects();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final controller = Provider.of<QuizController>(context, listen: false);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      controller.resumeTimer();
    }
  }

  void _subscribeToEffects() {
    final controller = Provider.of<QuizController>(context, listen: false);
    _effectSubscription = controller.effects.listen((effect) {
      if (!mounted) return;

      switch (effect.type) {
        case QuizEffectType.confetti:
          _confettiController.blast();
          HapticFeedback.heavyImpact();
          break;
        case QuizEffectType.coins:
          if (effect.data is int) {
             _spawnCoinParticle(effect.data);
             // Also pulse the progress bar/coin HUD
             _progressPulseNotifier.pulse();
          }
          break;
        case QuizEffectType.hapticSuccess:
          HapticFeedback.mediumImpact();
          Provider.of<AudioProvider>(context, listen: false).playSfx('success');
          break;
        case QuizEffectType.hapticError:
          HapticFeedback.lightImpact();
          Provider.of<AudioProvider>(context, listen: false).playSfx('pop');
          break;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _effectSubscription?.cancel();
    _confettiController.dispose();
    _progressPulseNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _spawnCoinParticle(int amount) {
    if (amount <= 0) return;
    final key = UniqueKey();
     setState(() {
      _coinParticles.add(
        Positioned(
          top: 60,
          left: 20,
          child: CoinParticle(
            key: key,
            amount: amount,
            onComplete: () {
               if (mounted) {
                 setState(() {
                   _coinParticles.removeWhere((w) => w.key == key);
                 });
               }
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final controller = Provider.of<QuizController>(context);

    // Keyboard handling
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.space) {
           if (controller.state.isAnswerChecked) {
             controller.loadNextQuestion();
           } else {
             controller.submitAnswer();
           }
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: Stack(
          children: [
            // 0. Fluid Background Pattern
            Positioned.fill(
              child: FloatingMedicalIcons(
                color: palette.primary,
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
                  // 1. Header
                  QuizHeader(
                    onClose: () => Navigator.pop(context),
                    progressPulseNotifier: _progressPulseNotifier,
                  ),

                  // 2. The Body
                  Expanded(
                    child: QuizBody(systemName: controller.systemName),
                  ),
                ],
              ),
            ),

            // 3. Feedback Sheet
            const QuizFeedbackOverlay(),

            // 4. Promotion Overlay (State-driven is fine for this modal)
            if (controller.state.newLevel != null)
              PromotionOverlay( 
                newLevel: controller.state.newLevel!,
                onDismiss: () {
                   controller.loadNextQuestion();
                },
              ),
          ],
        ),
      ),
    );
  }
}
