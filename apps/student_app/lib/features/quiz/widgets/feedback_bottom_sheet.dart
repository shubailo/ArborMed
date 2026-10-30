import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/liquid_button.dart';
import '../../../features/quiz/widgets/questions/report_issue_dialog.dart';

class FeedbackBottomSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;
  final dynamic questionId;

  const FeedbackBottomSheet({
    super.key,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
    this.questionId,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    // App Design colors
    final isCorrectColor = palette.success;
    final isWrongColor = palette.error;

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final mainColor = isCorrect ? isCorrectColor : isWrongColor;
    final title = isCorrect 
        ? (isHu ? "HELYES!" : "CORRECT!") 
        : (isHu ? "HELYTELEN!" : "INCORRECT");
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
              Stack(
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
                  if (questionId != null)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: TextButton.icon(
                        icon: Icon(Icons.flag_outlined,
                            size: 16, color: palette.textSecondary),
                        label: Text(isHu ? "Hiba jelentése" : "Report Issue",
                            style: TextStyle(
                                color: palette.textSecondary, fontSize: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                ReportIssueDialog(questionId: questionId),
                          );
                        },
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
                        isHu ? "ORVOSI MAGYARÁZAT" : "MEDICAL INSIGHT",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: mainColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFormattedExplanation(explanation, palette, mainColor),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 4. Action Button
              LiquidButton(
                label: isHu ? "FOLYTATÁS" : "CONTINUE",
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

  Widget _buildFormattedExplanation(
      String text, CozyPalette palette, Color mainColor) {
    final stepRegex = RegExp(r'(\d+)\.\s*([A-Za-z0-9_ -]+):\s*([^0-9]+)');
    final matches = stepRegex.allMatches(text).toList();

    if (matches.length >= 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: matches.map((m) {
          final stepNum = m.group(1);
          final stepTitle = m.group(2)?.trim();
          final stepBody = m.group(3)?.trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stepNum ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$stepTitle: ",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: stepBody,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: palette.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final cleanText = text.replaceAll('**', '');
    return Text(
      cleanText,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: palette.textPrimary,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    );
  }
}
