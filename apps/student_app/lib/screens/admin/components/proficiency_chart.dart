import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../utils/extensions/list_extensions.dart';

class ProficiencyChart extends StatelessWidget {
  final List<dynamic> data;

  const ProficiencyChart({super.key, required this.data});

  // Chart mapping constants
  static const double _maxChartScale = 100.0;
  static const double _maxTimeSeconds = 120.0;
  static const double _timeToScaleRatio = _maxTimeSeconds / _maxChartScale;

  double _mapChartScaleToSeconds(double scaleValue) => scaleValue * _timeToScaleRatio;
  double _mapSecondsToChartScale(double seconds) => (seconds / _timeToScaleRatio).clamp(0, _maxChartScale);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CozyTheme.of(context).shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.adminTopicProficiency,
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CozyTheme.of(context).textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.adminDetails,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CozyTheme.of(context).accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 400, // BIGGER as requested
            child: data.isEmpty
                ? Center(child: Text(l10n.adminNoDataSubject))
                : BarChart(
                    key: ValueKey(data.length),
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              CozyTheme.of(context, listen: false).paperWhite,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data.safeGet(groupIndex);
                            if (item == null) return null;
                            final label = rodIndex == 0
                                ? l10n.adminSuccessRate
                                : l10n.adminAvgTime;
                            final value = rodIndex == 0
                                ? '${rod.toY.toInt()}%'
                                : '${_mapChartScaleToSeconds(rod.toY).toStringAsFixed(1)}s';
                            return BarTooltipItem(
                              "$label\n$value",
                              TextStyle(
                                color: CozyTheme.of(
                                  context,
                                  listen: false,
                                ).textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 14.0,
                                  right: 10,
                                ),
                                child: Transform.rotate(
                                  angle: -0.6, // Tilted for readability
                                  child: Text(
                                    data[index]['section']?.toString() ?? '...',
                                    style: TextStyle(
                                      color: CozyTheme.of(
                                        context,
                                        listen: false,
                                      ).textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 60,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 25,
                            getTitlesWidget: (value, meta) => Text(
                              "${value.toInt()}%",
                              style: TextStyle(
                                color: CozyTheme.of(
                                  context,
                                  listen: false,
                                ).textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 25,
                            getTitlesWidget: (value, meta) {
                              final seconds = _mapChartScaleToSeconds(
                                value,
                              ).toInt();
                              return Text(
                                "${seconds}s",
                                style: TextStyle(
                                  color: CozyTheme.of(context).accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: CozyTheme.of(
                            context,
                            listen: false,
                          ).textSecondary.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((e) {
                        final mastery =
                            double.tryParse(
                              e.value['proficiency']?.toString() ?? '0',
                            ) ??
                            0;
                        final timeMs =
                            double.tryParse(
                              e.value['avg_time_ms']?.toString() ?? '0',
                            ) ??
                            0;
                        final timeSec = timeMs / 1000.0;

                        final timeValueForChart = _mapSecondsToChartScale(
                          timeSec,
                        );

                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: mastery,
                              color: CozyTheme.of(context).primary,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: timeValueForChart,
                              color: CozyTheme.of(context).accent,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                l10n.adminSuccessRatePercent,
                CozyTheme.of(context, listen: false).primary,
              ),
              const SizedBox(width: 32),
              _buildLegendItem(
                context,
                l10n.adminAvgTimeSec,
                CozyTheme.of(context, listen: false).accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            color: CozyTheme.of(context, listen: false).textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
