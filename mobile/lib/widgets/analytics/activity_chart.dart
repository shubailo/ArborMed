import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/stats_provider.dart';
import 'package:intl/intl.dart';

class ActivityChart extends StatelessWidget {
  final List<ActivityData> data;

  const ActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Determine max Y for scaling
    double maxY = 25; // Matching the image's top label
    for (var d in data) {
      if (d.count > maxY) maxY = d.count.toDouble() + 5;
    }

    // Map data to bar groups
    final List<BarChartGroupData> chartData = data.asMap().entries.map((e) {
      return _makeGroup(e.key, e.value.count.toDouble(), e.value.correctCount.toDouble(), maxY);
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
      color: Colors.white, // Pure white background like in the image
      child: data.isEmpty 
        ? const Center(child: Text("No activity data available", style: TextStyle(color: Colors.grey)))
        : BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          
          // Y-Axis titles (Left labels in the image: 0, 6, 13, 19, 25)
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  );
                },
                reservedSize: 30,
                interval: maxY / 4, // 5 equal intervals to match image style
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  final date = data[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(date), // Time style labels as in bottom of image
                      style: const TextStyle(color: Colors.black, fontSize: 8),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          // Horizontal grid lines as in image
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Colors.black,
                strokeWidth: 1,
              );
            },
          ),

          borderData: FlBorderData(
            show: false,
          ),
          barGroups: chartData,
        ),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double total, double correct, double maxY) {
    double incorrect = total - correct;
    if (incorrect < 0) incorrect = 0;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          width: 12,
          borderRadius: BorderRadius.circular(2),
          color: Colors.transparent, // Color handled by stack items
          rodStackItems: [
            BarChartRodStackItem(0, correct, const Color(0xFF8CAA8C)), // Green for Correct
            BarChartRodStackItem(correct, total, const Color(0xFFE57373)), // Red for Incorrect
          ],
        ),
      ],
    );
  }
}
