import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../models/readiness.dart';

class WeaknessRadarChart extends StatelessWidget {
  final List<ReadinessDetail> data;
  const WeaknessRadarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (data.isEmpty) return Text(strings.quizNoReadiness);
    final sorted = [...data]..sort((a, b) {
        final byScore = a.score.compareTo(b.score);
        return byScore == 0 ? a.slug.compareTo(b.slug) : byScore;
      });
    final topics = sorted.take(6).toList();
    final hu = Localizations.localeOf(context).languageCode == 'hu';
    final primary = Theme.of(context).colorScheme.primary;
    final drawRadar = topics.length >= 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (drawRadar)
        ExcludeSemantics(
            child: SizedBox(
                height: 180,
                child: RadarChart(
                  key: ValueKey(topics.length),
                  RadarChartData(
                    isMinValueAtCenter: true,
                    tickCount: 4,
                    radarTouchData: RadarTouchData(enabled: false),
                    ticksTextStyle: const TextStyle(color: Colors.transparent),
                    getTitle: (index, angle) =>
                        RadarChartTitle(text: '${index + 1}'),
                    dataSets: [
                      // fl_chart derives the radial domain from its datasets. Anchor percentages at 0 and 100.
                      RadarDataSet(
                          dataEntries: [
                            for (int i = 0; i < topics.length; i++)
                              RadarEntry(value: i == 0 ? 100 : 0)
                          ],
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          borderWidth: 0,
                          entryRadius: 0),
                      RadarDataSet(
                          dataEntries: [
                            for (final topic in topics)
                              RadarEntry(value: topic.score.toDouble())
                          ],
                          fillColor: primary.withValues(alpha: 0.2),
                          borderColor: primary,
                          borderWidth: 2,
                          entryRadius: 3),
                    ],
                  ),
                  duration: Duration.zero,
                ))),
      for (final (index, topic) in topics.indexed)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
                '${drawRadar ? "${index + 1}. " : ""}${topic.label(hu)} · ${topic.score}%')),
    ]);
  }
}
