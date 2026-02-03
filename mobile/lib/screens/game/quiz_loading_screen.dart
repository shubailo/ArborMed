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
    
    // Main loading animation (3 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
      if (_mainController.isCompleted) {
        _startTransition();
      }
    });

    // Transition animation (0.8 seconds)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _mainController.forward();

    // Status cycler
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentStatus = _statuses[Random().nextInt(_statuses.length)];
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
            // Header
            Text(
              "PREPARING ${widget.systemName.toUpperCase()}...",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                color: CozyTheme.textPrimary.withValues(alpha: 0.8), 
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 40),

            // Central Animation Area
            _buildAnimationVariant(),

            const SizedBox(height: 40),

            // Progress Bar (Subtle)
            SizedBox(
              width: 200,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _mainController.value,
                    backgroundColor: CozyTheme.textPrimary.withValues(alpha: 0.05),
                    color: CozyTheme.primary,
                    minHeight: 4,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Text
            Text(
              _currentStatus, 
              style: TextStyle(
                color: CozyTheme.textSecondary, 
                fontStyle: FontStyle.italic,
                fontSize: 14
              )
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
              size: const Size(280, 160),
              painter: ECGMonitorPainter(
                progress: _mainController.value,
                transition: _transitionController.value,
                color: CozyTheme.primary,
              ),
            );
          case LoadingVariant.syringe:
            return CustomPaint(
              size: const Size(200, 120),
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
