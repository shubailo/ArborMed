import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';

class FloatingMedicalIcons extends StatefulWidget {
  const FloatingMedicalIcons({super.key});

  @override
  State<FloatingMedicalIcons> createState() => _FloatingMedicalIconsState();
}

class _FloatingMedicalIconsState extends State<FloatingMedicalIcons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MedicalIcon> _icons = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 15; i++) {
      _icons.add(_MedicalIcon());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _icons
              .map((icon) => icon.build(_controller.value))
              .toList(),
        );
      },
    );
  }
}

class _MedicalIcon {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double size = 15.0 + math.Random().nextDouble() * 15.0;
  final IconData icon = [
    Icons.medical_services_outlined,
    Icons.favorite_border,
    Icons.medication_outlined,
    Icons.science_outlined,
  ][math.Random().nextInt(4)];
  final double speed = 0.05 + math.Random().nextDouble() * 0.1;

  Widget build(double animationValue) {
    double currentY = (y - animationValue * speed) % 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: x * constraints.maxWidth,
          top: currentY * constraints.maxHeight,
          child: Opacity(
            opacity: 0.1,
            child: Icon(icon, size: size, color: AppTheme.warmBrown),
          ),
        );
      },
    );
  }
}
