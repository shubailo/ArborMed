import 'package:flutter/material.dart';

class AppTheme {
  // Legacy Colors
  static const Color sageGreen = Color(0xFF8CAA8C);
  static const Color softClay = Color(0xFFC48B76);
  static const Color ivoryCream = Color(0xFFFDFCF8);
  static const Color warmBrown = Color(0xFF4A3728);
  
  // Paper Colors (Legacy UI)
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color paperCream = Color(0xFFFFFDF5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sageGreen,
        primary: sageGreen,
        secondary: softClay,
        surface: ivoryCream,
        onSurface: warmBrown,
      ),
      scaffoldBackgroundColor: ivoryCream,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: warmBrown,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: warmBrown,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Noto Sans',
          fontSize: 16,
          color: warmBrown,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Noto Sans',
          fontSize: 14,
          color: warmBrown,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: warmBrown,
        ),
        iconTheme: IconThemeData(color: warmBrown),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sageGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
