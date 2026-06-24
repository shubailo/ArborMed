import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:provider/provider.dart';
import '../../analytics/providers/stats_provider.dart';
import '../../profile/providers/rank_provider.dart';

class ProbationOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const ProbationOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final rankProvider = Provider.of<RankProvider>(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    
    final correctAnswersToday = statsProvider.todayCorrectAnswers;
    final progress = (correctAnswersToday / RankProvider.dailyRoundsGoal).clamp(0.0, 1.0);
    final isEligible = rankProvider.hasReachedRoundsThreshold(correctAnswersToday);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85), // Dense dark overlay
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Misconduct Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: palette.error, width: 2),
            ),
            child: Icon(Icons.gavel_rounded, color: palette.error, size: 48),
          ),
          const SizedBox(height: 24),
          
          Text(
            "NOTICE OF MISCONDUCT",
            style: GoogleFonts.figtree(
              color: palette.error,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            "Due to missed clinical shifts, you have accumulated ${rankProvider.malpracticeStrikes} malpractice strikes and are now on administrative probation.",
            textAlign: TextAlign.center,
            style: GoogleFonts.figtree(
              color: palette.textSecondary.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          
          // Progression requirement
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                Text(
                  "RESTORE STANDING",
                  style: GoogleFonts.figtree(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Complete 10 correct answers today to remove one strike.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: palette.surfaceTertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.6 * progress,
                      decoration: BoxDecoration(
                        color: isEligible ? palette.success : palette.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "$correctAnswersToday / 10 Rounds Finished",
                  style: GoogleFonts.figtree(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Action Button
          if (isEligible)
            ElevatedButton(
              onPressed: () async {
                final success = await rankProvider.syncCompletedRounds();
                if (success) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Clinical standing updated. Strike removed."))
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "SYNC ROUNDS",
                style: GoogleFonts.figtree(fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(
              "Finish your shift to restore access.",
              style: GoogleFonts.figtree(
                color: palette.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
