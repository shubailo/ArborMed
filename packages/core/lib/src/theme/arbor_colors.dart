import 'package:flutter/material.dart';
import 'cozy_theme.dart';

/// Legacy color aliases for backward compatibility with ArborMed-v1 code.
/// It is recommended to use [CozyTheme.of(context)] or [CozyPalette] instead.
class ArborColors {
  static const Color primary = CozyTheme.primary;
  static const Color secondary = CozyTheme.accent;
  static const Color accent = CozyTheme.accent;
  static const Color background = CozyTheme.background;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = CozyTheme.textPrimary;
  static const Color textSecondary = CozyTheme.textSecondary;
  static const Color success = CozyTheme.success;
  static const Color error = CozyTheme.error;
  static const Color paperWhite = CozyTheme.paperWhite;
  static const Color paperCream = CozyTheme.paperCream;
}
