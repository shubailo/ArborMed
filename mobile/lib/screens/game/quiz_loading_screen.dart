import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/cozy_theme.dart';
import 'widgets/ecg_monitor_painter.dart';
import 'widgets/syringe_painter.dart';

enum LoadingVariant { ecg, syringe }

class QuizLoadingScreen extends StatefulWidget {
  final String systemName;
  final Future<Map<String, dynamic>> dataFuture;
  final Function(Map<String, dynamic> data) onComplete;

  const QuizLoadingScreen({
    super.key, 
    required this.systemName, 
    required this.dataFuture,
    required this.onComplete,
  });

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

  Map<String, dynamic>? _fetchedData;
  bool _isAnimationDone = false;

  @override
  void initState() {
    super.initState();
    _variant = LoadingVariant.values[Random().nextInt(LoadingVariant.values.length)];
    
    // Main loading animation (3.0 seconds minimum)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationDone = true;
        _checkIfReady();
      }
    });

    // Start fetching data immediately
    widget.dataFuture.then((data) {
      if (mounted) {
        setState(() => _fetchedData = data);
        _checkIfReady();
      }
    }).catchError((e) {
      // If data fails, still transition so QuizSession can show error
      if (mounted) {
        setState(() => _fetchedData = {"error": e.toString()});
        _checkIfReady();
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

  void _checkIfReady() {
    // We only leave if BOTH the animation minimum duration and data are ready
    if (_isAnimationDone && _fetchedData != null) {
      _startTransition();
    }
  }

  void _startTransition() {
    if (_transitionController.isAnimating || _transitionController.isCompleted) return;
    
    _transitionController.forward().then((_) {
      if (mounted) {
        widget.onComplete(_fetchedData!);
      }
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

            // 💡 Linear Progress Indicator Removed per user request
            const SizedBox(height: 3),
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
