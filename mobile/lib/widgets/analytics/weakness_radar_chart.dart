import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
import '../../services/stats_provider.dart';

class WeaknessRadarChart extends StatelessWidget {
  final List<ReadinessDetail> data;

  const WeaknessRadarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data yet. Complete some quizzes!",
          style: TextStyle(color: CozyTheme.of(context).textSecondary),
        ),
      );
    }

    // Limit to top 6 dimensions for readability
    final chartData = data.length > 6 ? data.sublist(0, 6) : data;
    final palette = CozyTheme.of(context);

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: true),
          
          // Data Sets
          dataSets: [
            RadarDataSet(
              fillColor: palette.primary.withValues(alpha: 0.2),
              borderColor: palette.primary,
              entryRadius: 3,
              dataEntries: chartData.map((e) => RadarEntry(value: e.score.toDouble())).toList(),
              borderWidth: 2,
            ),
          ],
          
          // Chart Appearance
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          
          // Title (Labels) Configuration
          titlePositionPercentageOffset: 0.1,
          titleTextStyle: TextStyle(
              color: palette.textPrimary, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
          ),
          getTitle: (index, angle) {
            if (index >= chartData.length) return const RadarChartTitle(text: '');
            return RadarChartTitle(text: _formatLabel(chartData[index].topic));
          },
          
          // Ticks (Grid) Configuration
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          tickBorderData: BorderSide(
              color: palette.textSecondary.withValues(alpha: 0.1)
          ),
          gridBorderData: BorderSide(
              color: palette.textSecondary.withValues(alpha: 0.1), 
              width: 1
          ),
        ),
      ),
    );
  }

  String _formatLabel(String text) {
    if (text.length > 10) {
      return '${text.substring(0, 8)}...';
    }
    return text;
  }
}
