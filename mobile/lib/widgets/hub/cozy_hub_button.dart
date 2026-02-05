import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../theme/cozy_theme.dart';

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
    
    // 🔊 AUDIO FEEDBACK
    try {
      final audio = Provider.of<AudioProvider>(context, listen: false);
      audio.playSfx('click');
      audio.ensureMusicPlaying();
    } catch (_) {
      // Audio is optional; don't block button functionality
    }

    widget.onTap();  }

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
                    final palette = CozyTheme.of(context);
                    // Fallback to Vector Style
                    return Container(
                      decoration: BoxDecoration(
                        color: palette.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1), width: 2), // Subtle border
                        boxShadow: palette.shadowSmall,
                      ),
                      child: Icon(
                        widget.fallbackIcon,
                        color: palette.primary, // Sage Green
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
