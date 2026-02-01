import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../theme/cozy_theme.dart';

enum CozyButtonVariant { primary, secondary, outline, ghost }

class CozyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CozyButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;
  final bool? enabled; // New: explicitly control visual state

  const CozyButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.variant = CozyButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    this.enabled,
  }) : super(key: key);

  @override
  createState() => _CozyButtonState();
}

class _CozyButtonState extends State<CozyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // late Animation<double> _scaleAnimation; // Unused
  bool _isPressed = false;

  bool get _isEnabled => widget.enabled ?? (widget.onPressed != null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05, // Squish by 5%
    );
    // _scaleAnimation assignment removed
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _controller.forward();
    HapticFeedback.lightImpact(); // Subtle tap feel
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    _controller.reverse();
    setState(() => _isPressed = false);
    
    // 🔊 AUDIO FEEDBACK
    // Play Click Sound
    context.read<AudioProvider>().playSfx('click');
    // Ensure BGM starts if allowed (fixes Autoplay policy)
    context.read<AudioProvider>().ensureMusicPlaying();

    widget.onPressed?.call();
    HapticFeedback.mediumImpact(); // Confirmation thud
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  // Grant Gradients
  Gradient? _getGradient() {
    if (!_isEnabled) return null; // Use disabled color
    switch (widget.variant) {
      case CozyButtonVariant.primary: return CozyTheme.sageGradient;
      case CozyButtonVariant.secondary: return CozyTheme.clayGradient;
      case CozyButtonVariant.outline: return null;
      case CozyButtonVariant.ghost: return null;
    }
  }

  Color _getBgColor() {
    if (!_isEnabled) return Colors.grey[300]!;
    switch (widget.variant) {
      case CozyButtonVariant.primary: return CozyTheme.primary; // Fallback
      case CozyButtonVariant.secondary: return CozyTheme.accent; // Fallback
      case CozyButtonVariant.outline: return Colors.white;
      case CozyButtonVariant.ghost: return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (!_isEnabled) return Colors.grey[500]!;
    switch (widget.variant) {
      case CozyButtonVariant.primary: return Colors.white;
      case CozyButtonVariant.secondary: return Colors.white;
      case CozyButtonVariant.outline: return CozyTheme.primary;
      case CozyButtonVariant.ghost: return CozyTheme.textSecondary;
    }
  }

  List<BoxShadow> _getShadows() {
    if (!_isEnabled || widget.variant == CozyButtonVariant.ghost || widget.variant == CozyButtonVariant.outline) return [];
    
    // Pressed = No Shadow (Pressed into paper)
    if (_isPressed) return [];

    // Elevated State
    if (widget.variant == CozyButtonVariant.primary) return CozyTheme.coloredShadow(CozyTheme.primary);
    if (widget.variant == CozyButtonVariant.secondary) return CozyTheme.coloredShadow(CozyTheme.accent);
    
    return CozyTheme.shadowSmall;
  }

  BorderSide _getBorder() {
    if (widget.variant == CozyButtonVariant.outline) {
      return BorderSide(color: _isEnabled ? CozyTheme.primary : Colors.grey, width: 2);
    }
    // Return transparent border of same width to prevent layout shift (jitter)
    return const BorderSide(color: Colors.transparent, width: 2);
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final gradient = _getGradient();
          final bgColor = gradient != null ? null : _getBgColor();

          return Transform.scale(
            scale: 1.0 - _controller.value, // Manual control for squish
            alignment: Alignment.center,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              constraints: const BoxConstraints(minHeight: 56), // 🛡️ STABILIZE HEIGHT
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjusted for minHeight
              decoration: BoxDecoration(
                color: bgColor,
                gradient: gradient,
                borderRadius: BorderRadius.circular(20), // Pill Shape
                border: Border.fromBorderSide(_getBorder()),
                boxShadow: _getShadows(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🩺 Reserve space for icon if needed or use fixed size row
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: _getTextColor(), size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        color: _getTextColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w700, // Bold
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
