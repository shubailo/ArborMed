import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/cozy_theme.dart';
import '../../services/stats_provider.dart';
import '../analytics/weakness_radar_chart.dart';

class SmartReviewSheet extends StatelessWidget {
  final Function(String name, String slug) onReviewSelected;

  const SmartReviewSheet({super.key, required this.onReviewSelected});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final stats = Provider.of<StatsProvider>(context);
    final readiness = stats.readiness;
    final recommended = stats.smartReview;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: palette.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart Review",
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    "Your AI-powered study plan",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              if (readiness != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getScoreColor(readiness.overall, palette)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getScoreColor(readiness.overall, palette)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 18,
                          color: _getScoreColor(readiness.overall, palette)),
                      const SizedBox(width: 6),
                      Text(
                        "${readiness.overall}% Ready",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(readiness.overall, palette),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Radar Chart
          if (readiness != null && readiness.breakdown.isNotEmpty)
            SizedBox(
              height: 200,
              child: WeaknessRadarChart(data: readiness.breakdown),
            )
          else
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 24),

          // Recommendations
          Text(
            "Recommended for you",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          if (recommended.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                  child: Text("All caught up! 🎉",
                      style: TextStyle(color: palette.textSecondary))),
            )
          else
            ...recommended.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewCard(context, item, palette),
                )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      BuildContext context, SmartReviewItem item, CozyPalette palette) {
    return GestureDetector(
      onTap: () => onReviewSelected(item.topic, item.slug),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.paperWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, color: palette.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.topic,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    "Retention: ${item.retention.toInt()}% • ${item.daysSince.toInt()}d ago",
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score, CozyPalette palette) {
    if (score >= 80) return palette.success;
    if (score >= 50) return palette.warning;
    return palette.error;
  }
}
