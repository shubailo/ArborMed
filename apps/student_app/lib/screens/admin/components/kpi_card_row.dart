import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class KpiCardRow extends StatelessWidget {
  final StatsProvider stats;
  final bool isMobile;

  const KpiCardRow({
    super.key,
    required this.stats,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attemptsList = stats.questionStats
        .where((q) => q.totalAttempts > 0)
        .toList();
    final avgCorrect = attemptsList.isEmpty
        ? 0.0
        : attemptsList.fold<int>(0, (sum, q) => sum + q.correctPercentage) /
              attemptsList.length;

    // Live Trends from backend
    final String userTrend = "+${stats.userStats['new_users_24h'] ?? 0}";
    final double classAvgTrendVal =
        double.tryParse(
          stats.userStats['class_avg_trend']?.toString() ?? '0',
        ) ??
        0;
    final String classTrend =
        "${classAvgTrendVal >= 0 ? '+' : ''}${classAvgTrendVal.toStringAsFixed(1)}%";
    final double bloomTrendVal =
        double.tryParse(stats.userStats['bloom_trend']?.toString() ?? '0') ?? 0;
    final String bloomTrend =
        "${bloomTrendVal >= 0 ? '+' : ''}${bloomTrendVal.toStringAsFixed(1)}";

    final kpiCards = [
      _buildKpiCard(
        context,
        l10n.adminTotalUsers,
        stats.userStats['total_users'].toString(),
        Icons.people_outline,
        stats.userStats['total_users'].toString(),
        l10n.adminRegisteredStudents,
        userTrend,
        true,
      ),
      _buildKpiCard(
        context,
        l10n.adminClassAvg,
        "${avgCorrect.toStringAsFixed(1)}%",
        Icons.timeline_rounded,
        "${avgCorrect.toStringAsFixed(1)}%",
        l10n.adminOverallCorrectness,
        classTrend,
        classAvgTrendVal >= 0,
      ),
      _buildKpiCard(
        context,
        l10n.adminAvgBloom,
        "L${stats.userStats['avg_bloom']?.toStringAsFixed(1) ?? '1.0'}",
        Icons.auto_graph_outlined,
        "L${stats.userStats['avg_bloom']?.toStringAsFixed(1) ?? '1.0'}",
        l10n.adminPedagogicalDepth,
        bloomTrend,
        bloomTrendVal >= 0,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          kpiCards[0],
          const SizedBox(height: 12),
          kpiCards[1],
          const SizedBox(height: 12),
          kpiCards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: kpiCards[0]),
        const SizedBox(width: 20),
        Expanded(child: kpiCards[1]),
        const SizedBox(width: 20),
        Expanded(child: kpiCards[2]),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String displayValue,
    IconData icon,
    String value,
    String subtitle,
    String trend,
    bool? isPositive,
  ) {
    final palette = CozyTheme.of(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, anim, child) => Transform.translate(
        offset: Offset(0, 20 * (1.0 - anim)),
        child: Opacity(opacity: anim, child: child),
      ),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: palette.paperWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [...palette.shadowSmall],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Texture
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.03,
                child: Icon(icon, size: 120, color: palette.textPrimary),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with Gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [palette.primary, palette.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            color: palette.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            color: palette.textSecondary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Trend Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive == null
                      ? palette.background
                      : (isPositive ? Colors.green : Colors.red).withValues(
                          alpha: 0.1,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPositive != null) ...[
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      trend,
                      style: TextStyle(
                        color: isPositive == null
                            ? palette.textSecondary
                            : (isPositive ? Colors.green : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
