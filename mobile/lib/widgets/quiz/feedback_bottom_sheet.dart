import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/liquid_button.dart';

class FeedbackBottomSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;

  const FeedbackBottomSheet({
    super.key,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // App Design colors
    final isCorrectColor = CozyTheme.success; 
    final isWrongColor = CozyTheme.error;   
    
    // Use a very light tinted background for the sheet itself
    final sheetBg = isCorrect 
        ? CozyTheme.success.withValues(alpha: 0.1) 
        : CozyTheme.error.withValues(alpha: 0.1); 

    final mainColor = isCorrect ? isCorrectColor : isWrongColor;
    final title = isCorrect ? "CORRECT!" : "INCORRECT";
    final icon = isCorrect ? Icons.check_rounded : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      color: mainColor.withValues(alpha: 0.2),
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
                      style: GoogleFonts.outfit(
                        fontSize: 22, 
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
                    color: Colors.white.withValues(alpha: 0.5),
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
              LiquidButton(
                label: "CONTINUE",
                variant: isCorrect ? LiquidButtonVariant.primary : LiquidButtonVariant.secondary,
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
