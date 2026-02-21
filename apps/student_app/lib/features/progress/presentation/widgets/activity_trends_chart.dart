import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:student_app/core/theme/app_theme.dart';
import '../../domain/entities/progress.dart';

class ActivityTrendsChart extends StatelessWidget {
  final ActivityTrends trends;

  const ActivityTrendsChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.days.isEmpty) {
      return const Center(
        child: Text(
          'No activity data available yet.',
          style: TextStyle(color: AppTheme.softClay),
        ),
      );
    }

    double maxQuestions = 10;
    for (var day in trends.days) {
      if (day.questionCount > maxQuestions) {
        maxQuestions = day.questionCount.toDouble();
      }
    }
    maxQuestions = maxQuestions * 1.2;

    return Stack(
      children: [
        // Background Bar Chart (Volume / Question Count)
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxQuestions,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxQuestions) {
                      return const SizedBox();
                    }
                    // Show a few labels for question count
                    if (value % (maxQuestions / 2).round() == 0) {
                      return Text(
                        '${value.toInt()} Qs',
                        style: TextStyle(
                          color: AppTheme.softClay.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: trends.days.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.questionCount.toDouble(),
                    color: AppTheme.softClay.withValues(alpha: 0.15),
                    width: trends.days.length == 7 ? 20 : 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        // Foreground Line Chart (Accuracy %)
        LineChart(
          LineChartData(
            minY: 0,
            maxY: 1.0, // 100%
            minX: -0.5,
            maxX: trends.days.length.toDouble() - 0.5,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= trends.days.length) {
                      return const SizedBox();
                    }
                    // For 30 days, skip some labels to avoid crowding
                    if (trends.days.length > 7 &&
                        index % 5 != 0 &&
                        index != trends.days.length - 1) {
                      return const SizedBox();
                    }
                    final dateStr = trends.days[index].date;
                    final parts = dateStr.split('-');
                    final label = parts.length >= 3
                        ? '${parts[1]}/${parts[2]}'
                        : dateStr;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.softClay,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == 1.0 || value == 0.5) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.softClay,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.softClay.withValues(alpha: 0.1),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: trends.days.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.correctRate);
                }).toList(),
                isCurved: true,
                color: AppTheme.sageGreen,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: trends.days.length == 7 ? 4 : 2,
                      color: AppTheme.sageGreen,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
