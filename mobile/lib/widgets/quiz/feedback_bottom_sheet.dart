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
    final palette = CozyTheme.of(context);

    // App Design colors
    final isCorrectColor = palette.success;
    final isWrongColor = palette.error;

    // Use a very light tinted background for the sheet itself
    final sheetBg = isCorrect
        ? palette.success.withValues(alpha: 0.1)
        : palette.error.withValues(alpha: 0.1);

    final mainColor = isCorrect ? isCorrectColor : isWrongColor;
    final title = isCorrect ? "CORRECT!" : "INCORRECT";
    final icon = isCorrect ? Icons.check_rounded : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: palette.paperWhite,
        boxShadow: [
          BoxShadow(
            color: mainColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: mainColor.withValues(alpha: 0.1),
          width: 1,
        ),
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
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center icon with title
                children: [
                  // 1. Icon Bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mainColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: mainColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 2. Text Content
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: mainColor,
                      ),
                    ),
                  ),
                ],
              ),

              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: mainColor.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MEDICAL INSIGHT",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: mainColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        explanation,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 4. Action Button
              LiquidButton(
                label: "CONTINUE",
                variant: isCorrect
                    ? LiquidButtonVariant.primary
                    : LiquidButtonVariant.secondary,
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
