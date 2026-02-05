import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../theme/cozy_theme.dart';

enum LiquidButtonVariant { primary, secondary, outline, ghost }

class LiquidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LiquidButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;
  final bool? enabled;

  const LiquidButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LiquidButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    this.enabled,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool get _isEnabled => widget.enabled ?? (widget.onPressed != null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_controller);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    _controller.reverse();
    
    context.read<AudioProvider>().playSfx('click');
    widget.onPressed?.call();
    HapticFeedback.mediumImpact();
  }

  void _onTapCancel() {
    if (!_isEnabled) return;
    _controller.reverse();
  }

  Color _getBgColor(BuildContext context) {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return Colors.grey[300]!;
    switch (widget.variant) {
      case LiquidButtonVariant.primary: return palette.primary;
      case LiquidButtonVariant.secondary: return palette.secondary;
      case LiquidButtonVariant.outline: return Colors.white;
      case LiquidButtonVariant.ghost: return Colors.transparent;
    }
  }

  Color _getTextColor(BuildContext context) {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return Colors.grey[500]!;
    switch (widget.variant) {
      case LiquidButtonVariant.primary: return Colors.white;
      case LiquidButtonVariant.secondary: return Colors.white;
      case LiquidButtonVariant.outline: return palette.primary;
      case LiquidButtonVariant.ghost: return palette.textSecondary;
    }
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
          final bgColor = _getBgColor(context);
          final textColor = _getTextColor(context);
          
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isEnabled && widget.variant != LiquidButtonVariant.ghost 
                  ? [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.3 * (1.0 - _glowAnimation.value)),
                        blurRadius: 12 + (8 * _glowAnimation.value),
                        offset: Offset(0, 6 * (1.0 - _glowAnimation.value)),
                      )
                    ]
                  : [],
                border: widget.variant == LiquidButtonVariant.outline
                  ? Border.all(color: palette.primary.withValues(alpha: 0.5), width: 1.5)
                  : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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
