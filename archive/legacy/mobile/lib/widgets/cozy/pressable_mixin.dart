import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import '../../services/haptic_service.dart';

/// Mixin that provides physical press-hold behavior for buttons.
/// 
/// Press down → scales down + shadow lifts
/// Hold → stays pressed
/// Release → elastic bounce back
/// 
/// Usage:
/// ```dart
/// class _MyButtonState extends State<MyButton> with PressableMixin {
///   @override
///   Widget build(BuildContext context) {
///     return buildPressable(
///       isEnabled: widget.enabled,
///       onTap: widget.onPressed,
///       scale: 0.95,
///       child: Container(...),
///     );
///   }
/// }
/// ```
mixin PressableMixin<T extends StatefulWidget> on State<T> {
  bool _isPressed = false;
  bool get isPressed => _isPressed;

  void handleTapDown(TapDownDetails details, {bool haptic = true}) {
    setState(() => _isPressed = true);
    if (haptic) CozyHaptics.lightTap();
  }

  void handleTapUp(TapUpDetails details, VoidCallback? onTap, {bool haptic = true}) {
    setState(() => _isPressed = false);
    if (haptic) {
      CozyHaptics.mediumTap();
      // Try/catch safely in case AudioProvider isn't in tree or other issues
      try {
        Provider.of<AudioProvider>(context, listen: false).playSfx('click');
      } catch (_) {}
    }
    onTap?.call();
  }

  void handleTapCancel() {
    setState(() => _isPressed = false);
  }

  /// Wraps child with press-hold animation behavior.
  /// 
  /// [scale] - Scale factor when pressed (default 0.95)
  /// [shadowOffsetPressed] - Shadow Y offset when pressed
  /// [shadowOffsetNormal] - Shadow Y offset when normal
  Widget buildPressable({
    required Widget child,
    required bool isEnabled,
    VoidCallback? onTap,
    double scale = 0.95,
    double shadowOffsetPressed = 2,
    double shadowOffsetNormal = 6,
    double shadowBlurPressed = 4,
    double shadowBlurNormal = 12,
    bool hapticOnDown = true,
    bool hapticOnUp = true,
  }) {
    final currentScale = _isPressed ? scale : 1.0;

    return GestureDetector(
      onTapDown: isEnabled 
          ? (d) => handleTapDown(d, haptic: hapticOnDown) 
          : null,
      onTapUp: isEnabled 
          ? (d) => handleTapUp(d, onTap, haptic: hapticOnUp) 
          : null,
      onTapCancel: isEnabled ? handleTapCancel : null,
      child: AnimatedScale(
        scale: currentScale,
        duration: Duration(milliseconds: _isPressed ? 80 : 300),
        curve: _isPressed ? Curves.easeOut : Curves.elasticOut,
        child: child,
      ),
    );
  }

  /// Get current shadow offset based on pressed state
  double getShadowOffset({double pressed = 2, double normal = 6}) {
    return _isPressed ? pressed : normal;
  }

  /// Get current shadow blur based on pressed state
  double getShadowBlur({double pressed = 4, double normal = 12}) {
    return _isPressed ? pressed : normal;
  }

  /// Get animation duration based on pressed state
  Duration getAnimationDuration({int pressedMs = 80, int normalMs = 200}) {
    return Duration(milliseconds: _isPressed ? pressedMs : normalMs);
  }
}
