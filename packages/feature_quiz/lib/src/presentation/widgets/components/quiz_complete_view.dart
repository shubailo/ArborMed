import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/quiz_controller.dart';

class QuizCompleteView extends StatelessWidget {
  final String systemName;

  const QuizCompleteView({super.key, required this.systemName});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final controller = Provider.of<QuizController>(context, listen: false);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: CozyPanel(
          variant: CozyPanelVariant.cream,
          title: "SESSION COMPLETE",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 80,
                  color: palette.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Excellent Work!",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You've completed the current set of questions for $systemName.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              LiquidButton(
                label: "Back to Topics",
                onPressed: () => Navigator.pop(context),
                fullWidth: true,
                variant: LiquidButtonVariant.primary,
                icon: Icons.arrow_back_rounded,
              ),
              const SizedBox(height: 12),
              LiquidButton(
                label: "Review Session",
                onPressed: () {
                  // TODO: Implement review mode for current session?
                  // For now, just show a message or pop
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review mode coming soon!")),
                  );
                },
                fullWidth: true,
                variant: LiquidButtonVariant.outline,
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
