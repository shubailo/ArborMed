import 'package:flutter/material.dart';
import '../cozy_palette.dart';

class DarkPalette extends CozyPalette {
  @override
  Color get background => const Color(0xFF2C241B); // Espresso

  @override
  Color get surface => const Color(0xFF3E342B); // Dark Roast

  @override
  Color get primary => const Color(0xFFA3CFA3); // Moonlit Sage (Lighter for dark mode)

  @override
  Color get primaryContainer => const Color(0xFF384B38); // Dark Green

  @override
  Color get secondary => const Color(0xFFE2B4A3); // Soft Clay

  @override
  Color get secondaryContainer => const Color(0xFF5D4037); // Dark Clay

  @override
  Color get textPrimary => const Color(0xFFFDFCF8); // Ivory White

  @override
  Color get textSecondary => const Color(0xFFD7CCC8); // Latte
  
  @override
  Color get textInverse => const Color(0xFF2C241B); // Dark Text for buttons

  @override
  Color get paperWhite => const Color(0xFF3E342B); // Dark Paper

  @override
  Color get paperCream => const Color(0xFF4E4239); // Lighter Dark Paper

  @override
  Color get success => const Color(0xFF81C784); // Lighter Green

  @override
  Color get error => const Color(0xFFE57373); // Lighter Red

  @override
  Color get warning => const Color(0xFFFFB74D); // Lighter Orange

  @override
  LinearGradient get sageGradient => const LinearGradient(
    colors: [Color(0xFF8CAA8C), Color(0xFF558B55)], // Darker Sage Gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  LinearGradient get clayGradient => const LinearGradient(
    colors: [Color(0xFFC48B76), Color(0xFF8D6E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  LinearGradient get magicGradient => const LinearGradient(
    colors: [Color(0xFF7986CB), Color(0xFFBA68C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  @override
  LinearGradient get goldGradient => const LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌥️ Shadows (Subtler in dark mode)
  @override
  List<BoxShadow> get shadowSmall => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  @override
  List<BoxShadow> get shadowMedium => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  @override
  List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6)),
  ];
}
