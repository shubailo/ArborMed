import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/ui/pressable_mixin.dart';

enum CozyButtonVariant { primary, secondary, outline, ghost }

class CozyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final CozyButtonVariant variant;
  final IconData? icon;
  final Color? color;
  final bool fullWidth;
  final bool isLoading;
  final bool enabled;
  final bool large;

  const CozyButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = CozyButtonVariant.primary,
    this.icon,
    this.color,
    this.fullWidth = false,
    this.isLoading = false,
    this.enabled = true,
    this.large = false,
  });

  @override
  State<CozyButton> createState() => _CozyButtonState();
}

class _CozyButtonState extends State<CozyButton> with PressableMixin {
  bool get _isEnabled => widget.enabled && !widget.isLoading && widget.onTap != null;

  Color _getBgColor() {
    if (!_isEnabled) return AppTheme.warmBrown.withValues(alpha: 0.1);
    if (widget.color != null) return widget.color!;
    
    switch (widget.variant) {
      case CozyButtonVariant.primary:
        return AppTheme.sageGreen;
      case CozyButtonVariant.secondary:
        return AppTheme.softClay;
      case CozyButtonVariant.outline:
        return Colors.white;
      case CozyButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (!_isEnabled) return AppTheme.warmBrown.withValues(alpha: 0.3);
    
    switch (widget.variant) {
      case CozyButtonVariant.primary:
      case CozyButtonVariant.secondary:
        return Colors.white;
      case CozyButtonVariant.outline:
        return AppTheme.sageGreen;
      case CozyButtonVariant.ghost:
        return AppTheme.warmBrown.withValues(alpha: 0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBgColor();
    final textColor = _getTextColor();
    final shadowOffset = getShadowOffset(pressed: 1, normal: 4);
    final shadowBlur = getShadowBlur(pressed: 2, normal: 8);

    return buildPressable(
      isEnabled: _isEnabled,
      onTap: widget.onTap,
      scale: 0.92, // Legacy squish intensity
      child: AnimatedContainer(
        duration: getAnimationDuration(),
        width: widget.fullWidth ? double.infinity : null,
        constraints: BoxConstraints(minHeight: widget.large ? 64 : 52),
        padding: EdgeInsets.symmetric(
          horizontal: widget.large ? 32 : 24,
          vertical: widget.large ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: widget.variant == CozyButtonVariant.outline
              ? Border.all(
                  color: _isEnabled ? AppTheme.sageGreen : AppTheme.warmBrown.withValues(alpha: 0.1),
                  width: 2)
              : null,
          boxShadow: _isEnabled && widget.variant != CozyButtonVariant.ghost
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.25),
                    blurRadius: shadowBlur,
                    offset: Offset(0, shadowOffset),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
            Opacity(
              opacity: widget.isLoading ? 0.0 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.figtree(
                      color: textColor,
                      fontSize: widget.large ? 16 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
