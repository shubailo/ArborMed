import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/cozy_theme.dart';

class ConfettiController extends ChangeNotifier {
  void blast() {
    notifyListeners();
  }
}

class ConfettiOverlay extends StatefulWidget {
  final ConfettiController controller;
  
  const ConfettiOverlay({super.key, required this.controller});

  @override
  createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    
    _animController.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update();
        }
      });
    });

    widget.controller.addListener(_onBlast);
  }

  void _onBlast() {
    _particles.clear();
    // Spawn 50 particles
    for (int i = 0; i < 50; i++) {
        _particles.add(_createParticle());
    }
    _animController.forward(from: 0.0);
  }

  _Particle _createParticle() {
      // Explode from center 
      // Speed: 5.0 to 15.0
      double speed = 5.0 + _random.nextDouble() * 10.0;
      double angle = _random.nextDouble() * 2 * pi;
      
      Color color;
      int cIndex = _random.nextInt(4);
      if (cIndex == 0) {
        color = CozyTheme.primary;
      } else if (cIndex == 1) {
        color = CozyTheme.accent;
      } else if (cIndex == 2) {
        color = Colors.amber;
      } else {
        color = Colors.purpleAccent;
      }

      return _Particle(
          x: 0, 
          y: 0, 
          vx: cos(angle) * speed, 
          vy: sin(angle) * speed - 5, // Initial upward burst
          color: color, 
          size: 4 + _random.nextDouble() * 6,
      );
  }

  @override
  void dispose() {
    _animController.dispose();
    widget.controller.removeListener(_onBlast);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animController.isAnimating) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Center transform
          return Transform.translate(
            offset: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            child: CustomPaint(
              painter: _ConfettiPainter(_particles),
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
    double x;
    double y;
    double vx;
    double vy;
    final Color color;
    final double size;
    double rotation = 0;

    _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.size});

    void update() {
        x += vx;
        y += vy;
        vy += 0.5; // Gravity
        vx *= 0.98; // Air resistance
        rotation += 0.1;
    }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (var p in particles) {
      paint.color = p.color;
      // Draw as rect for rotation effect (simulated)
      canvas.drawCircle(Offset(p.x, p.y), p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
