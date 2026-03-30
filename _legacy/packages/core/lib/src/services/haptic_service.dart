import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

/// Central service for premium, medical-themed haptic feedback.
class CozyHaptics {
  /// Subtle selection click - Premium "Tap Down" feel
  static Future<void> lightTap() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> mediumTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Heavy impact - Strong "Thud" feel
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Heartbeat Pattern for Success (Lub-Dub)
  static Future<void> success() async {
    if (kIsWeb) {
      await HapticFeedback.mediumImpact();
      return;
    }

    try {
      if (await Vibration.hasVibrator() == true) {
        if (await Vibration.hasCustomVibrationsSupport() == true) {
          // Lub (40ms, 50% intensity) -> Wait (120ms) -> Dub (20ms, 25% intensity)
          await Vibration.vibrate(
            pattern: [0, 40, 120, 20],
            intensities: [0, 128, 0, 64],
          );
        } else {
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
        }
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Double Heavy Impact for Error/Mistake
  static Future<void> error() async {
    if (kIsWeb) {
      await HapticFeedback.heavyImpact();
      return;
    }

    try {
      if (await Vibration.hasVibrator() == true) {
        if (await Vibration.hasCustomVibrationsSupport() == true) {
          // Double buzz: 100ms (Heavy) -> 50ms wait -> 100ms (Heavy)
          await Vibration.vibrate(
            pattern: [0, 100, 50, 100],
            intensities: [0, 255, 0, 255],
          );
        } else {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.heavyImpact();
        }
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Big celebration (Level Up)
  static Future<void> celebrate() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
