import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../utils/extensions/list_extensions.dart';

class ProficiencyRadar extends StatefulWidget {
  final String subjectSlug;

  const ProficiencyRadar({super.key, required this.subjectSlug});

  @override
  State<ProficiencyRadar> createState() => _ProficiencyRadarState();
}

class _ProficiencyRadarState extends State<ProficiencyRadar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchSubjectDetail(widget.subjectSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final sectionData = stats.sectionMastery[widget.subjectSlug] ?? [];
        
        // Define the 6 corners
        // We prioritize real sections, then fill with placeholders from the user's mockup
        final List<String> defaultCorners = ['Anatomy', 'Physiology', 'Pathology', 'Clinical', 'Pharma', 'Radiology'];
        final List<String> actualCorners = [];
        final List<double> values = [];

        // 1. Add real sections
        for (var i = 0; i < sectionData.length && i < 6; i++) {
          actualCorners.add(sectionData[i]['section'] ?? "Section ${i+1}");
          final proficiencyValue = sectionData[i]['proficiency'];
          double mastery = 0.0;
          if (proficiencyValue is num) {
            mastery = proficiencyValue.toDouble();
          } else if (proficiencyValue is String) {
            mastery = double.tryParse(proficiencyValue) ?? 0.0;
          }
          values.add(mastery);
        }

        // 2. Fill remaining with default corners
        while (actualCorners.length < 6) {
          int index = actualCorners.length;
          actualCorners.add(defaultCorners[index]);
          values.add(0); // Placeholder data
        }

        final palette = CozyTheme.of(context);
        return Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: RadarChart(
                  key: ValueKey(actualCorners.length),
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    dataSets: [
                      RadarDataSet(
                        fillColor: palette.primary.withValues(alpha: 0.4),
                        borderColor: palette.primary,
                        entryRadius: 4,
                        dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData: BorderSide(color: palette.textPrimary.withValues(alpha: 0.1), width: 1),
                    titlePositionPercentageOffset: 0.15,
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                        text: actualCorners.safeGet(index) ?? '',
                        angle: angle,
                      );
                    },
                    tickCount: 4,
                    ticksTextStyle: const TextStyle(color: Colors.transparent),
                    gridBorderData: BorderSide(color: palette.textSecondary.withValues(alpha: 0.2), width: 1),
                  ),
                ),
              ),
            ),
            
            // Stats Breakdown List (as in image)
            Container(
              height: 220,
              padding: const EdgeInsets.only(bottom: 20),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                   _buildStatRow(context, "Knowledge Level", _getKnowledgeLevel(values), Icons.auto_awesome_rounded),
                   _buildStatRow(context, "Mastery Velocity", "12 pts / day", Icons.speed_rounded),
                   _buildStatRow(context, "Focus Recommendation", _getFocusRecommendation(actualCorners, values), Icons.lightbulb_outline_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getKnowledgeLevel(List<double> values) {
    double avg = values.fold(0.0, (sum, v) => sum + v) / values.length;
    if (avg > 80) return "Expert (Mastery)";
    if (avg > 50) return "Intermediate (Bloom 3)";
    return "Beginner (Bloom 1-2)";
  }

  String _getFocusRecommendation(List<String> corners, List<double> values) {
    int minIdx = 0;
    double minVal = 101;
    for (int i = 0; i < values.length; i++) {
        if (values[i] < minVal) {
            minVal = values[i];
            minIdx = i;
        }
    }
    return "Focus on ${corners[minIdx]}";
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon) {
    final palette = CozyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: palette.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: palette.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: palette.textSecondary, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
