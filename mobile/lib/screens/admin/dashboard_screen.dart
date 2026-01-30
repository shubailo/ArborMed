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
        title: "",
        showHeader: false,
        activeRoute: '/admin/dashboard',
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Consumer<StatsProvider>(
          builder: (context, stats, child) {
            if (stats.isLoading && stats.questionStats.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final attemptsList = stats.questionStats.where((q) => q.totalAttempts > 0).toList();
            final totalAttempts = stats.questionStats.fold<int>(0, (sum, q) => sum + q.totalAttempts);
            final avgCorrect = attemptsList.isEmpty 
              ? 0.0 
              : attemptsList.fold<int>(0, (sum, q) => sum + q.correctPercentage) / attemptsList.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Row - Compacted for 5 items
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildKpiCard("Total Attempts", totalAttempts.toString(), Icons.analytics_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard("Avg. Correct", "${avgCorrect.toStringAsFixed(1)}%", Icons.check_circle_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard("Questions", stats.questionStats.length.toString(), Icons.help_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: "Avg. user time: ${stats.userStats['avg_session_mins']} mins",
                        child: _buildKpiCard("Users", stats.userStats['total_users'].toString(), Icons.people_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard("Avg. Bloom", "L${stats.userStats['avg_bloom']?.toStringAsFixed(1) ?? '1.0'}", Icons.auto_graph_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  "Difficulty Matrix",
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CozyTheme.shadowSmall,
                    ),
                    child: _buildDifficultyMatrix(stats.questionStats),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Container(
      height: 90, // Slightly shorter
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CozyTheme.shadowSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CozyTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CozyTheme.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title, 
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
