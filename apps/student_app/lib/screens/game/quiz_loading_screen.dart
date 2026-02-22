import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/cozy_theme.dart';
import 'widgets/ecg_monitor_painter.dart';
import 'widgets/syringe_painter.dart';
import 'widgets/heartbeat_painter.dart';
import 'widgets/iv_drip_painter.dart';
import 'widgets/stethoscope_painter.dart';

enum LoadingVariant { ecg, syringe, heartbeat, ivDrip, stethoscope }

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

class _QuizLoadingScreenState extends State<QuizLoadingScreen>
    with TickerProviderStateMixin {
  late LoadingVariant _variant;
  late AnimationController _mainController;
  late AnimationController _transitionController;
  late AnimationController _statusFadeController;
  late AnimationController _floatingController;

  String _currentStatus = "Initializing clinical environment...";
  late Timer _statusTimer;
  final List<String> _statuses = [
    "Calibrating diagnostic tools...",
    "Indexing pathology database...",
    "Readying clinical case...",
    "Sterilizing instruments...",
    "Reviewing patient history...",
    "Preparing examination room...",
    "Syncing with medical records...",
    "Loading anatomical references...",
  ];

  Map<String, dynamic>? _fetchedData;
  bool _isAnimationDone = false;

  // Floating icons data
  late List<_FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();
    _variant =
        LoadingVariant.values[Random().nextInt(LoadingVariant.values.length)];

    // Initialize floating icons
    final random = Random();
    _floatingIcons = List.generate(6, (index) {
      return _FloatingIcon(
        icon: _getRandomMedicalIcon(random),
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 16 + random.nextDouble() * 12,
        speed: 0.3 + random.nextDouble() * 0.4,
        opacity: 0.04 + random.nextDouble() * 0.06,
      );
    });

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
      if (mounted) {
        setState(() => _fetchedData = {"error": e.toString()});
        _checkIfReady();
      }
    });

    // Transition animation
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _statusFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // Floating icons animation (continuous loop)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _mainController.forward();

    // Status cycler
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
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

  IconData _getRandomMedicalIcon(Random random) {
    const icons = [
      Icons.medical_services_outlined,
      Icons.healing_outlined,
      Icons.favorite_outline,
      Icons.science_outlined,
      Icons.biotech_outlined,
      Icons.health_and_safety_outlined,
    ];
    return icons[random.nextInt(icons.length)];
  }

  void _checkIfReady() {
    if (_isAnimationDone && _fetchedData != null) {
      _startTransition();
    }
  }

  void _startTransition() {
    if (_transitionController.isAnimating ||
        _transitionController.isCompleted) {
      return;
    }

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
    _floatingController.dispose();
    _statusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CozyPalette palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          // Vignette background
          _buildVignetteBackground(palette),

          // Floating medical icons
          _buildFloatingIcons(palette),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                _buildHeader(context, palette),
                const SizedBox(height: 60),

                // Central animation
                _buildAnimationVariant(palette),
                const SizedBox(height: 60),

                // Status text
                _buildStatusText(context, palette),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVignetteBackground(CozyPalette palette) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              palette.background,
              palette.background,
              Color.lerp(palette.background, Colors.black, 0.15)!,
            ],
            stops: const [0.0, 0.6, 1.0],
            radius: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcons(CozyPalette palette) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: _floatingIcons.map((icon) {
            double yOffset =
                (icon.y + _floatingController.value * icon.speed) % 1.2 - 0.1;
            double xOffset = icon.x +
                sin(_floatingController.value * 2 * pi + icon.x * 10) * 0.03;

            return Positioned(
              left: xOffset * MediaQuery.of(context).size.width,
              top: yOffset * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: icon.opacity * (1 - _transitionController.value),
                child: Icon(
                  icon.icon,
                  size: icon.size,
                  color: palette.primary,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CozyPalette palette) {
    return Column(
      children: [
        Text(
          "Preparing ${widget.systemName}",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: palette.textPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.primary.withValues(alpha: 0.1),
                palette.primary.withValues(alpha: 0.5),
                palette.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationVariant(CozyPalette palette) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _transitionController]),
      builder: (context, child) {
        final progress = _mainController.value;
        final transition = _transitionController.value;

        Widget painter;
        Size size;

        switch (_variant) {
          case LoadingVariant.ecg:
            size = const Size(320, 200);
            painter = CustomPaint(
              size: size,
              painter: ECGMonitorPainter(
                progress: progress,
                transition: transition,
                color: palette.primary,
              ),
            );
          case LoadingVariant.syringe:
            size = const Size(240, 160);
            painter = CustomPaint(
              size: size,
              painter: SyringePainter(
                progress: progress,
                transition: transition,
                color: palette.primary,
              ),
            );
          case LoadingVariant.heartbeat:
            size = const Size(200, 200);
            painter = CustomPaint(
              size: size,
              painter: HeartbeatPainter(
                progress: progress,
                transition: transition,
                color: palette.primary,
              ),
            );
          case LoadingVariant.ivDrip:
            size = const Size(160, 220);
            painter = CustomPaint(
              size: size,
              painter: IVDripPainter(
                progress: progress,
                transition: transition,
                color: palette.primary,
              ),
            );
          case LoadingVariant.stethoscope:
            size = const Size(200, 200);
            painter = CustomPaint(
              size: size,
              painter: StethoscopePainter(
                progress: progress,
                transition: transition,
                color: palette.primary,
              ),
            );
        }

        // Add subtle scale animation on transition
        return Transform.scale(
          scale: 1.0 + transition * 0.1,
          child: Opacity(
            opacity: 1.0 - transition,
            child: painter,
          ),
        );
      },
    );
  }

  Widget _buildStatusText(BuildContext context, CozyPalette palette) {
    return FadeTransition(
      opacity: _statusFadeController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _currentStatus,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _FloatingIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
