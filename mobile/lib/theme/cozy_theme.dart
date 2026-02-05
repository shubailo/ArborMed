import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CozyTheme {
  // 🎨 Palette
  static const Color background = Color(0xFFFDFCF8); // Ivory Cream (Refined)
  static const Color primary = Color(0xFF8CAA8C);    // Sage Green
  static const Color accent = Color(0xFFC48B76);     // Soft Clay
  static const Color textPrimary = Color(0xFF4A3728); // Deeper, warmer brown
  static const Color textSecondary = Color(0xFF8D6E63); // Medium Brown
  static const Color paperWhite = Color(0xFFFFFFFF); // Pure white for high-contrast paper cards
  static const Color paperCream = Color(0xFFFFFDF5); // Warm paper ivory

  static const Color success = Color(0xFF66BB6A);    // Aesthetic Green (Material 400)
  static const Color error = Color(0xFFEF5350);      // Aesthetic Red (Material 400)

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
    BoxShadow(color: textPrimary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(color: textPrimary.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  // 🔤 Typography (Professional Medical Aesthetic)
  static TextTheme get textTheme {
    return TextTheme(
      // Headers -> Figtree (Clean, Premium, Trust)
      displayLarge: GoogleFonts.figtree(
        fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.figtree(
        fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      displaySmall: GoogleFonts.figtree(
        fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      
      // Body -> Noto Sans (Global Standard for Clarity)
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
      ),
      labelLarge: GoogleFonts.figtree(
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
      fontFamily: GoogleFonts.notoSans().fontFamily,
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
            borderRadius: BorderRadius.circular(24), // More rounded
          ),
          textStyle: GoogleFonts.figtree(fontWeight: FontWeight.bold),
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

  // Helper Styles
  static TextStyle get dialogTitle => GoogleFonts.figtree(
    fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary
  );

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
