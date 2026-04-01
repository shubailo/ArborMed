import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cozy_palette.dart';

class LightPalette extends CozyPalette {
  @override
  Color get background => const Color(0xFFFDFCF8); // Ivory Cream

  @override
  Color get surface => Colors.white;

  @override
  Color get primary => const Color(0xFF8CAA8C); // Sage Green

  @override
  Color get primaryContainer => const Color(0xffDCEDDC); // Very light sage

  @override
  Color get secondary => const Color(0xFFC48B76); // Soft Clay

  @override
  Color get secondaryContainer => const Color(0xfff3e0da); // Light clay

  @override
  Color get textPrimary => const Color(0xFF4A3728); // Deeper, warmer brown

  @override
  Color get textSecondary => const Color(0xFF8D6E63); // Medium Brown

  @override
  Color get textInverse => Colors.white;

  @override
  Color get paperWhite => const Color(0xFFFFFFFF);

  @override
  Color get paperCream => const Color(0xFFFFFDF5);

  @override
  Color get success => const Color(0xFF4CAF50); // Vibrant Original Green

  @override
  Color get error => const Color(0xFFB37474); // Muted Terracotta Red (Aesthetic Pastel)

  @override
  Color get warning => const Color(0xFFFFA726);

  @override
  TextStyle get displayLarge => GoogleFonts.figtree(
      fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, height: 1.1);

  @override
  TextStyle get displayMedium => GoogleFonts.figtree(
      fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);

  @override
  TextStyle get displaySmall => GoogleFonts.figtree(
      fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary);

  @override
  TextStyle get bodyLarge => GoogleFonts.notoSans(
      fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary);

  @override
  TextStyle get bodyMedium => GoogleFonts.notoSans(
      fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary);

  @override
  TextStyle get bodySmall => GoogleFonts.notoSans(
      fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary);

  @override
  TextStyle get labelLarge => GoogleFonts.figtree(
      fontSize: 16, fontWeight: FontWeight.w700, color: textInverse, letterSpacing: 0.5);

  @override
  TextStyle get headingMedium => GoogleFonts.figtree(
      fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary);

  @override
  LinearGradient get sageGradient => const LinearGradient(
        colors: [Color(0xFF8CAA8C), Color(0xFFA8C6A8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  LinearGradient get clayGradient => const LinearGradient(
        colors: [Color(0xFFC48B76), Color(0xFFE2B4A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  LinearGradient get magicGradient => const LinearGradient(
        colors: [Color(0xFF8CAA8C), Color(0xFFC48B76)], // Sage → Clay (on-brand)
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  LinearGradient get goldGradient => const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // 🌥️ Shadows
  @override
  Color get divider => const Color(0xFFE2B4A3).withValues(alpha: 0.3); // Soft clay divider

  @override
  List<BoxShadow> get shadowSmall => [
        BoxShadow(
            color: textPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4)),
      ];

  @override
  List<BoxShadow> get shadowMedium => [
        BoxShadow(
            color: textPrimary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8)),
      ];

  @override
  List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6)),
      ];
}
