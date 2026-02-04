import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/cozy_theme.dart';
import 'widgets/ecg_monitor_painter.dart';
import 'widgets/syringe_painter.dart';

enum LoadingVariant { ecg, syringe }

class QuizLoadingScreen extends StatefulWidget {
  final String systemName;
  final VoidCallback onAnimationComplete;

  const QuizLoadingScreen({super.key, required this.systemName, required this.onAnimationComplete});

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen> with TickerProviderStateMixin {
  late LoadingVariant _variant;
  late AnimationController _mainController;
  late AnimationController _transitionController;
  late AnimationController _statusFadeController;
  
  String _currentStatus = "Initializing clinical environment...";
  late Timer _statusTimer;
  final List<String> _statuses = [
    "Calibrating diagnostic tools...",
    "Indexing pathology database...",
    "Readying clinical case...",
    "Sterilizing instruments...",
    "Reviewing patient history...",
    "Preparing fluid path...",
    "Syncing with medical cloud...",
  ];

  @override
  void initState() {
    super.initState();
    _variant = LoadingVariant.values[Random().nextInt(LoadingVariant.values.length)];
    
    // Main loading animation (3.5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startTransition();
      }
    });

    // Transition animation (0.5 seconds - faster exit)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _statusFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _mainController.forward();

    // Status cycler (Smoother with fades)
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        _statusFadeController.reverse().then((_) {
            if (mounted) {
                setState(() {
                    _currentStatus = _statuses[Random().nextInt(_statuses.length)];
                });
                _statusFadeController.forward();
            }
        });
      }
    });
  }

  void _startTransition() {
    _transitionController.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _transitionController.dispose();
    _statusFadeController.dispose();
    _statusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header (Styled for premium feel)
            Text(
              "Preparing ${widget.systemName}",
              style: CozyTheme.textTheme.displayMedium?.copyWith(
                color: CozyTheme.textPrimary.withValues(alpha: 0.9), 
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: CozyTheme.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(height: 60),

            // Central Animation Area
            _buildAnimationVariant(),

            const SizedBox(height: 60),

            // Status Text (With Fade)
            FadeTransition(
              opacity: _statusFadeController,
              child: Text(
                _currentStatus, 
                style: CozyTheme.textTheme.bodyMedium?.copyWith(
                  color: CozyTheme.textSecondary.withValues(alpha: 0.7), 
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                )
              ),
            ),
            
            const SizedBox(height: 32),

            // Progress Bar (Subtle & Slim)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 180,
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _mainController.value,
                      backgroundColor: CozyTheme.primary.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(CozyTheme.primary.withValues(alpha: 0.4)),
                      minHeight: 3,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationVariant() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _transitionController]),
      builder: (context, child) {
        switch (_variant) {
          case LoadingVariant.ecg:
            return CustomPaint(
              size: const Size(300, 180),
              painter: ECGMonitorPainter(
                progress: _mainController.value,
                transition: _transitionController.value,
                color: CozyTheme.primary,
              ),
            );
          case LoadingVariant.syringe:
            return CustomPaint(
              size: const Size(220, 140),
              painter: SyringePainter(
                progress: _mainController.value,
                transition: _transitionController.value,
                color: CozyTheme.primary,
              ),
            );
        }
      },
    );
  }
}
