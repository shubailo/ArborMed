import 'package:flutter/material.dart';

class CozyTheme {
  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 32.0;

  static BorderRadius get borderSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderLarge => BorderRadius.circular(radiusLarge);

  // Shadows
  static List<BoxShadow> get cardShadow => panelShadow;

  static List<BoxShadow> get panelShadow => shadowMedium;

  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: const Color(0xFF4A3728).withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: const Color(0xFF4A3728).withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  // Gradients
  static const LinearGradient clinicOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black12],
  );

  static const LinearGradient sageGradient = LinearGradient(
    colors: [Color(0xFF8CAA8C), Color(0xFFA8C6A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient clayGradient = LinearGradient(
    colors: [Color(0xFFC48B76), Color(0xFFE2B4A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magicGradient = LinearGradient(
    colors: [Color(0xFF9FA8DA), Color(0xFFE1BEE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
}
