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
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CozyButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    this.enabled,
    this.isLoading = false,
  });

  final bool isLoading;

  /// Specialized "Lub-Dub" Heartbeat Haptic
  static Future<void> heartbeat() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  @override
  createState() => _CozyButtonState();
}

class _CozyButtonState extends State<CozyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  bool get _isEnabled =>
      (widget.enabled ?? (widget.onPressed != null)) && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.0,
      upperBound: 0.04, // Subtle squish
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    _controller.forward();
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) async {
    if (!_isEnabled) return;
    _controller.reverse();
    setState(() => _isPressed = false);

    // 🔊 AUDIO FEEDBACK
    context.read<AudioProvider>().playSfx('click');
    context.read<AudioProvider>().ensureMusicPlaying();

    widget.onPressed?.call();

    // Smooth Haptic
    HapticFeedback.lightImpact();
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  // Grant Gradients
  Gradient? _getGradient() {
    if (!_isEnabled) return null;
    final palette = CozyTheme.of(context);
    switch (widget.variant) {
      case CozyButtonVariant.primary:
        return palette.sageGradient;
      case CozyButtonVariant.secondary:
        return palette.clayGradient;
      default:
        return null;
    }
  }

  Color _getBgColor() {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return palette.textSecondary.withValues(alpha: 0.1);
    switch (widget.variant) {
      case CozyButtonVariant.primary:
        return palette.primary;
      case CozyButtonVariant.secondary:
        return palette.secondary;
      case CozyButtonVariant.outline:
        return palette.surface;
      case CozyButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return palette.textSecondary.withValues(alpha: 0.5);
    switch (widget.variant) {
      case CozyButtonVariant.primary:
      case CozyButtonVariant.secondary:
        return palette.textInverse;
      case CozyButtonVariant.outline:
        return palette.primary;
      case CozyButtonVariant.ghost:
        return palette.textSecondary;
    }
  }

  List<BoxShadow> _getShadows() {
    if (!_isEnabled ||
        _isPressed ||
        widget.variant == CozyButtonVariant.ghost ||
        widget.variant == CozyButtonVariant.outline) {
      return [];
    }

    final palette = CozyTheme.of(context);
    if (widget.variant == CozyButtonVariant.primary) {
      return palette.coloredShadow(palette.primary);
    }
    if (widget.variant == CozyButtonVariant.secondary) {
      return palette.coloredShadow(palette.secondary);
    }

    return palette.shadowSmall;
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
          final palette = CozyTheme.of(context);
          final gradient = _getGradient();
          final bgColor = gradient != null ? null : _getBgColor();

          return Transform.scale(
            scale: 1.0 - _controller.value,
            alignment: Alignment.center,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                border: widget.variant == CozyButtonVariant.outline
                    ? Border.all(
                        color: _isEnabled
                            ? palette.primary
                            : palette.textSecondary.withValues(alpha: 0.1),
                        width: 2)
                    : null,
                boxShadow: _getShadows(),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Loading Indicator
                  if (widget.isLoading)
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getTextColor()))),

                  // Content
                  Opacity(
                    opacity: widget.isLoading ? 0.0 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: _getTextColor(), size: 18),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.figtree(
                            color: _getTextColor(),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
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
