import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/features/profile/providers/rank_provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';
import 'package:arbor_med/widgets/cozy/cozy_dialog_sheet.dart';

class MissionControlView extends StatelessWidget {
  final VoidCallback onBack;

  const MissionControlView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final rank = Provider.of<RankProvider>(context);
    final stats = Provider.of<StatsProvider>(context);
    final palette = CozyTheme.of(context);

    // Dynamic Clinical Trial Progress Calculation (Simulated Live)
    // Formula: Slowly crawls between 40% and 48% depending on the hour/minute
    // We base it on current day of the year to ensure it looks like community-wide progress
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final double trialProgress = (42.0 + (dayOfYear % 10) + (now.hour / 24.0 * 2) + (now.minute / 60.0)).clamp(40.0, 99.9);

    return CozyDialogSheet(
      onTapOutside: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER SECTION
          Container(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.3),
              border: Border(bottom: BorderSide(color: palette.textSecondary.withValues(alpha: 0.1))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CIVILIAN MEDICAL CORPS",
                        style: GoogleFonts.figtree(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rank.currentRank.label,
                        style: GoogleFonts.quicksand(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rank.rankRequirement,
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: palette.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStrikeIndicator(rank, palette),
              ],
            ),
          ),

          // 2. MAIN MISSION LOG
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("DAILY CLINICAL ROUNDS", palette),
                  const SizedBox(height: 16),
                  _buildRoundsCard(stats, rank, palette),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader("COLLECTIVE EFFORT", palette),
                  const SizedBox(height: 16),
                  _buildGlobalTrialCard(trialProgress, palette),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader("RECORDS OFFICE", palette),
                  const SizedBox(height: 16),
                  _buildStatsRow(stats, palette),
                ],
              ),
            ),
          ),

          // 3. ACTION BAR
          Padding(
            padding: const EdgeInsets.all(32),
            child: CozyButton(
              label: 'EXIT THE STATION',
              variant: CozyButtonVariant.secondary,
              fullWidth: true,
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, CozyPalette palette) {
    return Text(
      title,
      style: GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: palette.textPrimary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildRoundsCard(StatsProvider stats, RankProvider rank, CozyPalette palette) {
    final correctToday = stats.todayCorrectAnswers;
    final progress = (correctToday / RankProvider.dailyRoundsGoal).clamp(0.0, 1.0);
    final isDone = rank.hasDoneRoundsToday;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "LICENSURE MAINTENANCE",
                style: GoogleFonts.figtree(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (isDone)
                const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20)
              else
                Text(
                  "$correctToday / ${RankProvider.dailyRoundsGoal} FINDINGS",
                  style: GoogleFonts.figtree(fontWeight: FontWeight.bold, color: palette.primary, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Secure clinical findings through quiz sessions to maintain your standing.",
            style: GoogleFonts.figtree(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: palette.surfaceTertiary,
              color: isDone ? Colors.green : palette.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalTrialCard(double percent, CozyPalette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: 0.15), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.biotech_rounded, color: palette.primary, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OPERATION: CARDIO-VASCULAR OUTBREAK",
                  style: GoogleFonts.figtree(fontWeight: FontWeight.w900, fontSize: 12, color: palette.primary),
                ),
                Text(
                  "Pooled community data for rare pathology discovery.",
                  style: GoogleFonts.figtree(fontSize: 12, color: palette.textPrimary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Text(
            "${percent.toStringAsFixed(1)}%",
            style: GoogleFonts.figtree(fontWeight: FontWeight.w900, color: palette.primary, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(StatsProvider stats, CozyPalette palette) {
    return Row(
      children: [
        _buildStatBox("SUCCESS RATE", "84%", palette),
        const SizedBox(width: 16),
        _buildStatBox("TOTAL ROUNDS", "128", palette),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, CozyPalette palette) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceTertiary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.textSecondary.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.figtree(fontSize: 20, fontWeight: FontWeight.w900, color: palette.textPrimary)),
            Text(label, style: GoogleFonts.figtree(fontSize: 9, fontWeight: FontWeight.bold, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrikeIndicator(RankProvider rank, CozyPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "RECORD INTEGRITY",
          style: GoogleFonts.figtree(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: rank.malpracticeStrikes > 0 ? Colors.redAccent : palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final active = index < rank.malpracticeStrikes;
            return Container(
              width: 24,
              height: 6,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: active ? Colors.redAccent : palette.surfaceTertiary,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
