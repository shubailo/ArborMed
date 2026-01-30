import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_guard.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchQuestionStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: AdminScaffold(
        title: "Analytics Dashboard",
        activeRoute: '/admin/dashboard',
        child: Consumer<StatsProvider>(
          builder: (context, stats, child) {
            if (stats.isLoading && stats.questionStats.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalAttempts = stats.questionStats.fold<int>(0, (sum, q) => sum + q.totalAttempts);
            final avgCorrect = stats.questionStats.isEmpty 
              ? 0.0 
              : stats.questionStats.fold<int>(0, (sum, q) => sum + q.correctPercentage) / stats.questionStats.length;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // KPI Row
                  Row(
                    children: [
                      _buildKpiCard("Total Attempts", totalAttempts.toString(), Icons.analytics_rounded),
                      const SizedBox(width: 20),
                      _buildKpiCard("Avg. Correctness", "${avgCorrect.toStringAsFixed(1)}%", Icons.check_circle_rounded),
                      const SizedBox(width: 20),
                      _buildKpiCard("Questions", stats.questionStats.length.toString(), Icons.help_rounded),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Main Chart
                  const Text(
                    "Difficulty Matrix",
                    style: TextStyle(fontFamily: 'Quicksand', fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Compare how long students take vs. how often they get it right.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    height: 450,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CozyTheme.shadowSmall,
                    ),
                    child: _buildDifficultyMatrix(stats.questionStats),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: CozyTheme.shadowSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CozyTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: CozyTheme.primary),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyMatrix(List<QuestionStats> data) {
    if (data.isEmpty) return const Center(child: Text("No data yet. Start some quizzes!"));

    return ScatterChart(
      ScatterChartData(
        scatterSpots: data.map((q) {
          return ScatterSpot(
            q.avgTimeMs / 1000.0, // X: Seconds
            q.correctPercentage.toDouble(), // Y: %
            radius: 8,
            color: _getPointColor(q.correctPercentage),
          );
        }).toList(),
        minX: 0,
        maxX: 30, // Most questions answered within 30s
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 20, verticalInterval: 5),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("Avg. Time (Seconds)"),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text("Correctness (%)"),
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        scatterTouchData: ScatterTouchData(
          touchTooltipData: ScatterTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (ScatterSpot spot) {
              final q = data.firstWhere((element) => 
                (element.avgTimeMs / 1000.0) == spot.x && 
                element.correctPercentage.toDouble() == spot.y
              );
              return ScatterTooltipItem(
                '${q.questionText}\nTime: ${spot.x.toStringAsFixed(1)}s\nCorrect: ${spot.y.toInt()}%',
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getPointColor(int percentage) {
    if (percentage > 80) return Colors.greenAccent.shade700;
    if (percentage > 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
