import 'package:flutter/material.dart';
import 'pressable_mixin.dart';
import 'shake_animation.dart';

/// Reusable answer button with physical press-hold behavior.
/// Uses [PressableMixin] for centralized sound and haptics logic.
class PressableAnswerButton extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final bool isSelected;
  final bool isWrong;
  final bool isDisabled;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsets padding;

  const PressableAnswerButton({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    this.isSelected = false,
    this.isWrong = false,
    this.isDisabled = false,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  State<PressableAnswerButton> createState() => _PressableAnswerButtonState();
}

class _PressableAnswerButtonState extends State<PressableAnswerButton>
    with PressableMixin {
  @override
  Widget build(BuildContext context) {
    // Physical button: pressed = scale down + shadow moves closer
    final double scale = isPressed ? 0.95 : (widget.isSelected ? 1.02 : 1.0);
    final double shadowOffset = isPressed ? 2 : (widget.isSelected ? 6 : 4);
    final double shadowBlur = isPressed ? 4 : (widget.isSelected ? 12 : 8);

    return buildPressable(
      onTap: widget.isDisabled ? null : widget.onTap,
      isEnabled: !widget.isDisabled,
      child: ShakeAnimation(
        shake: widget.isWrong,
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: isPressed ? 80 : 300),
          curve: isPressed ? Curves.easeOut : Curves.elasticOut,
          child: AnimatedContainer(
            duration: Duration(milliseconds: isPressed ? 80 : 200),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor,
                width: widget.isSelected ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? widget.borderColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: shadowBlur,
                  offset: Offset(0, shadowOffset),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
