import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';

class StartSessionHero extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const StartSessionHero(
      {super.key, required this.onTap, this.label = "START SESSION"});

  @override
  createState() => _StartSessionHeroState();
}

class _StartSessionHeroState extends State<StartSessionHero>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pressController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pressController]),
      builder: (context, child) {
        final palette = CozyTheme.of(context);
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 1.0, end: 0.9).animate(_pressController),
            child: GestureDetector(
              onTapDown: (_) {
                _pressController.forward();
              },
              onTapUp: (_) {
                _pressController.reverse();
                widget.onTap();
              },
              onTapCancel: () {
                _pressController.reverse();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(24), // Softer corners
                  boxShadow: const [], // Removed shadows
                ),
                child: Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.figtree(
                      // Align with new font choice
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.textInverse,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
