import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/locale_provider.dart';
import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/floating_medical_icons.dart';
import 'package:arbor_med/widgets/cozy/confetti_overlay.dart';
import 'package:arbor_med/widgets/cozy/coin_particle.dart';
import 'package:arbor_med/features/quiz/providers/quiz_controller.dart';
import 'package:arbor_med/features/quiz/providers/submission_queue.dart';
import 'package:arbor_med/features/quiz/widgets/components/quiz_header.dart';
import 'package:arbor_med/features/quiz/widgets/components/quiz_body.dart';
import 'package:arbor_med/features/quiz/widgets/components/quiz_feedback_overlay.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/widgets/cozy/cozy_progress_bar.dart'; // Solves PulseNotifier error
import 'package:arbor_med/features/quiz/models/quiz_ui_state.dart';

class QuizSessionScreen extends StatefulWidget {
  final int? ownerId;
  final String systemName;
  final String systemSlug;
  final Map<String, dynamic>? initialData;
  final String? sessionId;
  final List<int>? questionIds; // Restored for Mistake Review

  const QuizSessionScreen({
    super.key,
    this.ownerId,
    required this.systemName,
    required this.systemSlug,
    this.initialData,
    this.sessionId,
    this.questionIds,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  late final int? _owner;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _owner = widget.ownerId ?? context.read<AuthProvider>().user?.id;
  }

  @override
  Widget build(BuildContext context) {
    final active = context.select<AuthProvider, int?>((auth) => auth.user?.id);
    if (_owner == null || active != _owner) {
      _ended = true;
    }
    if (_ended) {
      final hu = Localizations.localeOf(context).languageCode == 'hu';
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(hu ? 'Ez a kvízmunkamenet véget ért.' : 'This quiz session has ended.'),
        ),
      );
    }
    final queue = context.read<SubmissionQueue>();
    return ChangeNotifierProvider(
      create: (context) => QuizController(
        apiService: queue.api,
        cacheService: context.read<QuestionCacheService>(),
        db: queue.db,
        queue: queue,
        systemSlug: widget.systemSlug,
        systemName: widget.systemName,
        userId: _owner!,
        initialQuestion: widget.initialData,
        initialSessionId: widget.sessionId,
        questionIds: widget.questionIds,
        languageCode: context.read<LocaleProvider>().locale.languageCode,
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
      if (!mounted) return;
      _subscribeToEffects();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final controller = Provider.of<QuizController>(context, listen: false);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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

            final auth = context.read<AuthProvider>();
            unawaited(auth.refreshUser().catchError((Object error) {
              debugPrint('Unable to refresh coin balance: $error');
            }));
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
          key: key,
          top: 30, // Align closer to the header HUD
          left: 40,
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
    return Focus(
      focusNode: _focusNode,
      autofocus: ModalRoute.isCurrentOf(context) ?? true,
      onKeyEvent: (node, event) {
        if (!node.hasPrimaryFocus ||
            event.logicalKey != LogicalKeyboardKey.space ||
            ModalRoute.of(context)?.isCurrent == false) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent) {
          if (controller.state.isAnswerChecked || controller.state.submissionRejected) {
            unawaited(controller.loadNextQuestion());
          } else {
            unawaited(controller.submitAnswer());
          }
        }
        return KeyEventResult.handled;
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
          ],
        ),
      ),
    );
  }
}
