import 'package:flutter/material.dart';
import 'dart:ui';
import '../cozy/floating_medical_icons.dart';

class GamePortalButton extends StatelessWidget {
  final VoidCallback onTap;

  const GamePortalButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const Center(
              child: Icon(Icons.school_rounded, color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizFloatingWindow extends StatefulWidget {
  final VoidCallback onClose;
  final Widget child;

  const QuizFloatingWindow({Key? key, required this.onClose, required this.child}) : super(key: key);

  @override
  _QuizFloatingWindowState createState() => _QuizFloatingWindowState();
}

class _QuizFloatingWindowState extends State<QuizFloatingWindow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dimmed Background with Floating Icons
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleClose, // Tap outside to close
              child: Container(
                color: Colors.black.withOpacity(0.4), // Dim
                child: FloatingMedicalIcons(
                   color: Colors.white.withOpacity(0.15), // Subtle icons on dim bg
                ),
              ),
            ),
          ),

          // 2. The Cozy Menu Card
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 600, // Widened to match Quiz Card
                // height: 500, // Let child determine height or fixed? Fixed is safer for "Card" look
                constraints: const BoxConstraints(maxHeight: 600),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5), // CozyTheme.paperWhite
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 4), // Brown border like a clipboard
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Slightly smaller than container to prevent bleed
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Clipboard Top Handle Clip (Visual only)
                        Container(
                          width: 100,
                          height: 12,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D6E63),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Content
                        Flexible(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
