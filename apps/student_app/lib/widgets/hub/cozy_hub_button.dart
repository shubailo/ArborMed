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

class _CozyHubButtonState extends State<CozyHubButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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
    } catch (_) {}

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
    final palette = CozyTheme.of(context);
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [], // Removed shadows
            ),
            child: Image.asset(
              'assets/ui/buttons/${widget.assetName}.png',
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: palette.paperWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: palette.textSecondary.withValues(alpha: 0.1),
                        width: 2),
                    boxShadow: palette.shadowSmall,
                  ),
                  child: Icon(
                    widget.fallbackIcon,
                    color: palette.primary,
                    size: widget.size * 0.45,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
