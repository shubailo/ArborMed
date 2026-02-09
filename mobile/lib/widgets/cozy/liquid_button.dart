import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../theme/cozy_theme.dart';
import 'pressable_mixin.dart';

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

class _LiquidButtonState extends State<LiquidButton> with PressableMixin {
  bool get _isEnabled => widget.enabled ?? (widget.onPressed != null);

  void _onTap() {
    context.read<AudioProvider>().playSfx('click');
    widget.onPressed?.call();
  }

  Color _getBgColor(BuildContext context) {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return palette.textSecondary.withValues(alpha: 0.1);
    switch (widget.variant) {
      case LiquidButtonVariant.primary:
        return palette.primary;
      case LiquidButtonVariant.secondary:
        return palette.secondary;
      case LiquidButtonVariant.outline:
        return palette.paperWhite;
      case LiquidButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor(BuildContext context) {
    final palette = CozyTheme.of(context);
    if (!_isEnabled) return palette.textSecondary.withValues(alpha: 0.5);
    switch (widget.variant) {
      case LiquidButtonVariant.primary:
        return palette.textInverse;
      case LiquidButtonVariant.secondary:
        return palette.textInverse;
      case LiquidButtonVariant.outline:
        return palette.primary;
      case LiquidButtonVariant.ghost:
        return palette.textSecondary;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowOffset = getShadowOffset();
    final shadowBlur = getShadowBlur();

    return buildPressable(
      isEnabled: _isEnabled,
      onTap: _onTap,
      child: AnimatedContainer(
        duration: getAnimationDuration(),
        width: widget.fullWidth ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: _getBgColor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isEnabled &&
                  widget.variant != LiquidButtonVariant.ghost
              ? [
                  BoxShadow(
                    color: _getBgColor(context).withValues(alpha: 0.3),
                    blurRadius: shadowBlur,
                    offset: Offset(0, shadowOffset),
                  )
                ]
              : [],
          border: widget.variant == LiquidButtonVariant.outline
              ? Border.all(
                  color: CozyTheme.of(context).primary.withValues(alpha: 0.5),
                  width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: _getTextColor(context), size: 22),
              const SizedBox(width: 10),
            ],
            Text(
              widget.label,
              style: GoogleFonts.outfit(
                color: _getTextColor(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
