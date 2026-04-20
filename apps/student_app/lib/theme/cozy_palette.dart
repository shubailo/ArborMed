import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class CozyPalette {
  // 🎨 Core Colors
  Color get background;
  Color get surface; // Card background

  Color get primary; // Main brand color
  Color get primaryContainer; // Lighter variant for backgrounds
  Color get surfaceTertiary; // For secondary backgrounds
  Color get border; // Standard border

  Color get secondary; // Accent color
  Color get accent => secondary; // Alias for secondary to support legacy naming
  Color get secondaryContainer;

  // 🔤 Text Styles
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
  List<BoxShadow> get shadowSmall;
  List<BoxShadow> get shadowMedium;
  List<BoxShadow> coloredShadow(Color color);
}
