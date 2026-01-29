import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CozyTheme {
  // 🎨 Palette
  static const Color background = Color(0xFFFDF7E7); // Warm Cream
  static const Color primary = Color(0xFF8CAA8C);    // Sage Green
  static const Color accent = Color(0xFFC48B76);     // Soft Clay
  static const Color textPrimary = Color(0xFF5D4037); // Dark Brown
  static const Color textSecondary = Color(0xFF8D6E63); // Medium Brown
  static const Color paperWhite = Color(0xFFFFFDF5); // Slightly brighter cream for cards

  // 🌈 Semantic Gradients (Hybrid Model)
  static const LinearGradient sageGradient = LinearGradient(
    colors: [Color(0xFF8CAA8C), Color(0xFFA8C6A8)], // Sage -> Mint
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient clayGradient = LinearGradient(
    colors: [Color(0xFFC48B76), Color(0xFFE2B4A3)], // Clay -> Terra
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magicGradient = LinearGradient(
    colors: [Color(0xFF9FA8DA), Color(0xFFE1BEE7)], // Lavender -> Orchid (For Mastery)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌥️ Cozy Shadows (Smart Shadows)
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(color: textPrimary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(color: textPrimary.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  // 🔤 Typography (Tuned for Contrast)
  static TextTheme get textTheme {
    return TextTheme(
      // Headers -> Quicksand (Bold, Friendly)
      displayLarge: GoogleFonts.quicksand(
        fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, // w900/800 for pop
        height: 1.1,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      displaySmall: GoogleFonts.quicksand(
        fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      
      // Body -> Inter (Clean, legible)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, // Slightly heavier
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  // 🖌️ Global Theme Data
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      
      // Default font family if GoogleFonts fails
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        centerTitle: true,
      ),

      // Button Theme (Pill Shape)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat by default
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
    );
  }
}
