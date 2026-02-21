import 'package:flutter/material.dart';

mixin PressableMixin<T extends StatefulWidget> on State<T> {
  bool isPressed = false;

  void setPressed(bool pressed) {
    if (isPressed != pressed) {
      setState(() {
        isPressed = pressed;
      });
    }
  }

  double getScale({double scale = 0.95}) => isPressed ? scale : 1.0;

  double getShadowOffset({double pressed = 1.0, double normal = 4.0}) =>
      isPressed ? pressed : normal;

  double getShadowBlur({double pressed = 2.0, double normal = 10.0}) =>
      isPressed ? pressed : normal;

  Duration getAnimationDuration() => const Duration(milliseconds: 100);

  Widget buildPressable({
    required Widget child,
    required VoidCallback? onTap,
    bool isEnabled = true,
    double scale = 0.95,
  }) {
    return GestureDetector(
      onTapDown: isEnabled ? (_) => setPressed(true) : null,
      onTapUp: isEnabled ? (_) => setPressed(false) : null,
      onTapCancel: isEnabled ? () => setPressed(false) : null,
      onTap: isEnabled ? onTap : null,
      child: AnimatedScale(
        scale: getScale(scale: scale),
        duration: getAnimationDuration(),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}
