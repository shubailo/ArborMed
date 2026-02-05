import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';

class StartSessionHero extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const StartSessionHero({super.key, required this.onTap, this.label = "START SESSION"});

  @override
  createState() => _StartSessionHeroState();
}

class _StartSessionHeroState extends State<StartSessionHero> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        final palette = CozyTheme.of(context);
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: palette.primary, // Sage Green (Matches Quiz)
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.primary.withValues(alpha: 0.8), width: 3), // Darker Sage border
                boxShadow: palette.shadowMedium,
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.textInverse,
                  letterSpacing: 1.1
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
