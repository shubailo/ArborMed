import 'package:flutter/material.dart';
import 'package:student_app/core/ui/pressable_mixin.dart';
import 'package:student_app/core/ui/shake_animation.dart';

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
    final double scale = isPressed ? 0.96 : (widget.isSelected ? 1.02 : 1.0);
    final double shadowOffset = isPressed ? 1.5 : (widget.isSelected ? 6 : 3);
    final double shadowBlur = isPressed ? 3 : (widget.isSelected ? 12 : 6);

    return buildPressable(
      onTap: widget.isDisabled ? null : widget.onTap,
      isEnabled: !widget.isDisabled,
      scale: scale,
      child: ShakeAnimation(
        shake: widget.isWrong,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor,
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? widget.borderColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: shadowBlur,
                offset: Offset(0, shadowOffset),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
