import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../analytics/providers/stats_provider.dart';
import '../../analytics/widgets/weakness_radar_chart.dart';

class SmartReviewSheet extends StatefulWidget {
  final void Function(String name, String slug) onReviewSelected;
  const SmartReviewSheet({super.key, required this.onReviewSelected});

  @override
  State<SmartReviewSheet> createState() => _SmartReviewSheetState();
}

class _SmartReviewSheetState extends State<SmartReviewSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stats = context.read<StatsProvider>();
      if (stats.readinessState == ReviewLoadState.initial) {
        stats.fetchReadiness();
      }
      if (stats.reviewState == ReviewLoadState.initial) {
        stats.fetchSmartReview();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final strings = AppLocalizations.of(context)!;
    final hu = Localizations.localeOf(context).languageCode == 'hu';
    final score = stats.readiness;
    return SafeArea(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.quizReviewTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (stats.readinessState == ReviewLoadState.error)
              TextButton(
                  onPressed: stats.fetchReadiness,
                  child: Text(strings.quizReadinessRetry))
            else if (stats.readinessState != ReviewLoadState.ready)
              const LinearProgressIndicator()
            else if (score == null || score.breakdown.isEmpty)
              Text(strings.quizNoReadiness)
            else ...[
              Text(strings.quizReadyPercent(score.overall)),
              WeaknessRadarChart(data: score.breakdown),
            ],
            const Divider(height: 24),
            Text(strings.quizRecommendations,
                style: Theme.of(context).textTheme.titleMedium),
            if (stats.reviewState == ReviewLoadState.error)
              TextButton(
                  onPressed: stats.fetchSmartReview,
                  child: Text(strings.quizReviewRetry))
            else if (stats.reviewState != ReviewLoadState.ready)
              const LinearProgressIndicator()
            else if (stats.smartReview.isEmpty)
              Text(strings.quizReviewEmpty)
            else
              for (final item in stats.smartReview)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.label(hu)),
                    subtitle: Text([
                      strings.quizRetention(item.retention.round()),
                      if (item.daysSince != null)
                        strings.quizDaysSince(item.daysSince!.floor())
                    ].join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        widget.onReviewSelected(item.label(hu), item.slug)),
          ]),
    ));
  }
}
