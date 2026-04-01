import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class CozyPalette {
  // 🎨 Core Colors
  Color get background;
  Color get surface; // Card background

  Color get primary; // Main brand color
  Color get primaryContainer; // Lighter variant for backgrounds
  Color get primaryLight => primaryContainer; // Alias for consistent UI access

  Color get secondary; // Accent color
  Color get accent => secondary; // Alias for secondary to support legacy naming
  Color get secondaryContainer;
  Color get secondaryLight => secondaryContainer; // Alias for consistent UI access

  // 🔤 Text Styles
  TextStyle get displayLarge;
  TextStyle get displayMedium;
  TextStyle get displaySmall;
  TextStyle get headingLarge => displaySmall; // Alias for legacy support
  TextStyle get headingSmall => bodyLarge.copyWith(fontWeight: FontWeight.bold); // Alias for legacy support
  TextStyle get bodyLarge;
  TextStyle get bodyMedium;
  TextStyle get bodySmall;
  TextStyle get labelLarge;
  TextStyle get headingMedium;

  TextStyle get dialogTitle => GoogleFonts.figtree(
      fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary);

  // 🔤 Text
  Color get textPrimary;
  Color get textSecondary;
  Color get textInverse; // Text on primary background

  // 📄 Paper Colors (For learning cards)
  Color get paperWhite;
  Color get paperCream;

  // 🚦 Semantic
  Color get success;
  Color get error;
  Color get warning;

  // 🌈 Gradients
  LinearGradient get sageGradient;
  LinearGradient get clayGradient;
  LinearGradient get magicGradient;
  LinearGradient get goldGradient; // For premium features

  // 🌥️ Shadows
  Color get divider;
  List<BoxShadow> get shadowSmall;
  List<BoxShadow> get shadowMedium;
  List<BoxShadow> coloredShadow(Color color);
}
