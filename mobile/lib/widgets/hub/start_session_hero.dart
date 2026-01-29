import 'package:flutter/material.dart';

class StartSessionHero extends StatefulWidget {
  final VoidCallback onTap;

  const StartSessionHero({Key? key, required this.onTap}) : super(key: key);

  @override
  _StartSessionHeroState createState() => _StartSessionHeroState();
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF8CAA8C), // Sage Green (Matches Quiz)
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7A967A), width: 3), // Darker Sage border
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
            ]
          ),
          child: const Text(
            "START SESSION",
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
    );
  }
}
