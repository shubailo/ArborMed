import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_button.dart';

class FeedbackBottomSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;

  const FeedbackBottomSheet({
    Key? key,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // App Design colors
    const isCorrectColor = CozyTheme.primary; // Sage Green
    const isWrongColor = CozyTheme.accent;   // Clay Red
    
    // Use a very light tinted background for the sheet itself
    final sheetBg = isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7); // Lightest green/red tint

    final mainColor = isCorrect ? isCorrectColor : isWrongColor;
    final title = isCorrect ? "CORRECT!" : "INCORRECT";
    final icon = isCorrect ? Icons.check_rounded : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Center icon with title
                children: [
                  // 1. Icon Bubble
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon, 
                      color: mainColor,
                      size: 28, 
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 2. Text Content
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: mainColor, 
                      ),
                    ),
                  ),
                ],
              ),
              
              // 3. Explanation Area (Only for incorrect)
              if (!isCorrect && explanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    explanation,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: CozyTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 4. Action Button
              CozyButton(
                label: "CONTINUE",
                variant: isCorrect ? CozyButtonVariant.primary : CozyButtonVariant.secondary,
                fullWidth: true,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
