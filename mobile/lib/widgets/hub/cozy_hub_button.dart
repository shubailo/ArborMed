import 'package:flutter/material.dart';

class CozyHubButton extends StatefulWidget {
  final String label;
  final String assetName; // e.g. "profile", "shop"
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final double size;

  const CozyHubButton({
    super.key,
    required this.label,
    required this.assetName,
    required this.fallbackIcon,
    required this.onTap,
    this.size = 75.0,
  });

  @override
  createState() => _CozyHubButtonState();
}


class _CozyHubButtonState extends State<CozyHubButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // OPTIMIZED: Faster duration (70ms) and snappier curve (easeOutCubic)
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 70));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: RepaintBoundary( // OPTIMIZATION: Isolate animation redraws
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Image.asset(
                  'assets/ui/buttons/${widget.assetName}.png',
                  fit: BoxFit.contain,
                  gaplessPlayback: true, // OPTIMIZATION: Prevent flickering
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to Vector Style
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF0F0F0), width: 2), // Subtle border
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Icon(
                        widget.fallbackIcon,
                        color: const Color(0xFF8CAA8C), // Sage Green
                        size: widget.size * 0.5,
                      ),
                    );
                  },
                ),
              ),
              // Optional: Label below if needed, but clean icons usually suffice.
              // keeping it clean for now as per ref images.
            ],
          ),
        ),
      ),
    );
  }
}
