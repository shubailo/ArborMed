import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/cozy_theme.dart';
import '../../services/stats_provider.dart';
import '../cozy/cozy_tile.dart';

class MasteryHeatmap extends StatefulWidget {
  final String subjectSlug;
  final Function(String name, String slug)? onStartQuiz;

  const MasteryHeatmap({
    super.key,
    required this.subjectSlug,
    this.onStartQuiz,
  });

  @override
  State<MasteryHeatmap> createState() => _MasteryHeatmapState();
}

class _MasteryHeatmapState extends State<MasteryHeatmap> {
  String? _expandedSlug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false)
          .fetchSubjectDetail(widget.subjectSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final List<Map<String, dynamic>> rawData =
            stats.sectionMastery[widget.subjectSlug] ?? [];

        if (rawData.isEmpty) {
          final palette = CozyTheme.of(context);
          return Center(
              child: Text("Loading Clinical Data...",
                  style: TextStyle(color: palette.textSecondary)));
        }

        final List<Map<String, dynamic>> sortedData = List.from(rawData);
        if (sortedData.length > 12) {
          sortedData.removeRange(12, sortedData.length);
        }

        sortedData.sort((a, b) {
          int attemptsA = _parseAttempts(a['attempts']);
          int attemptsB = _parseAttempts(b['attempts']);
          if (attemptsA > 0 && attemptsB == 0) return -1;
          if (attemptsA == 0 && attemptsB > 0) return 1;

          double profA = _parseProficiency(a['proficiency']);
          double profB = _parseProficiency(b['proficiency']);
          return profA.compareTo(profB);
        });

        return Column(
          children: [
            _buildAlertNote(sortedData),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.1,
                ),
                itemCount: sortedData.length,
                itemBuilder: (context, index) {
                  return _buildClinicalCard(sortedData[index]);
                },
              ),
            ),
            if (_expandedSlug != null)
              _buildExpandedFooter(
                  sortedData.firstWhere((d) => d['slug'] == _expandedSlug)),
          ],
        );
      },
    );
  }

  int _parseAttempts(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _parseProficiency(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildAlertNote(List<Map<String, dynamic>> data) {
    final used = data.where((d) => _parseAttempts(d['attempts']) > 0).toList();
    if (used.isEmpty) return const SizedBox.shrink();
    final critical =
        used.where((d) => _parseProficiency(d['proficiency']) < 40).toList();
    if (critical.isEmpty) return const SizedBox.shrink();

    final palette = CozyTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: palette.error.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.report_problem_rounded, color: palette.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "DIAGNOSTIC ALERT: ${critical.length} sectors need clinical review.",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: palette.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalCard(Map<String, dynamic> data) {
    bool isSelected = _expandedSlug == data['slug'];
    int attempts = _parseAttempts(data['attempts']);
    double proficiency = _parseProficiency(data['proficiency']);
    bool isUsed = attempts > 0;

    Color masteryColor = _getColorForProficiency(proficiency);
    bool needsRevision = isUsed && proficiency < 50;

    final palette = CozyTheme.of(context);
    return CozyTile(
      onTap: () {
        setState(() {
          _expandedSlug = isSelected ? null : data['slug'];
        });
      },
      hoverBorderColor: masteryColor,
      backgroundColor: isSelected
          ? masteryColor.withValues(alpha: 0.04)
          : palette.paperWhite,
      border: BorderSide(
        color: isUsed
            ? (isSelected ? masteryColor : masteryColor.withValues(alpha: 0.5))
            : palette.textPrimary.withValues(alpha: 0.1),
        width: isSelected ? 3 : 2,
      ),
      padding: const EdgeInsets.fromLTRB(
          10, 6, 10, 6), // COMPACT PADDING to prevent mobile overflow
      child: LayoutBuilder(builder: (context, constraints) {
        // Adjust font sizes based on available height (very tight in 2.1 ratio on small phones)
        double containerHeight = constraints.maxHeight;
        double labelSize = (containerHeight * 0.16).clamp(7.0, 9.0);
        double percentSize = (containerHeight * 0.32).clamp(12.0, 16.0);
        double iconSize = (containerHeight * 0.25).clamp(10.0, 14.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Topic Label (Fitted to width)
            Text(
              data['section']?.toUpperCase() ?? "???",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary.withValues(alpha: 0.8),
                letterSpacing: 0.1,
              ),
            ),

            // 2. Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${proficiency.toInt()}%",
                    style: TextStyle(
                      fontSize: percentSize,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (needsRevision)
                  Icon(Icons.warning_amber_rounded,
                      color: palette.warning, size: iconSize)
                else
                  Icon(Icons.insights_rounded,
                      color: palette.textSecondary.withValues(alpha: 0.2),
                      size: iconSize),
              ],
            ),

            // 3. Progress Bar (Thin but visible)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (proficiency / 100).clamp(0.0, 1.0),
                backgroundColor: palette.textPrimary.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUsed
                      ? masteryColor
                      : palette.textPrimary.withValues(alpha: 0.1),
                ),
                minHeight: 3,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildExpandedFooter(Map<String, dynamic> data) {
    int attempts = _parseAttempts(data['attempts']);
    int sessions = int.tryParse(data['sessions_count']?.toString() ?? '0') ?? 0;
    double proficiency = _parseProficiency(data['proficiency']);
    int bloomLevel = (data['bloom_level'] != null)
        ? int.parse(data['bloom_level'].toString())
        : 1;

    final palette = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _getColorForProficiency(proficiency).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['section'].toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary)),
              Text("BLOOM LVL $bloomLevel",
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: palette.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("SESSIONS", "$sessions"),
              _buildStatItem("ANSWERS", "$attempts"),
              _buildStatItem("MASTERY", "${proficiency.toInt()}%"),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (widget.onStartQuiz != null) {
                widget.onStartQuiz!(data['section'], data['slug']);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.textInverse,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("LAUNCH CLINICAL SESSION",
                style: TextStyle(
                    color: palette.textInverse,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final palette = CozyTheme.of(context);
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary)),
        Text(label,
            style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: palette.textSecondary)),
      ],
    );
  }

  Color _getColorForProficiency(double prof) {
    final palette = CozyTheme.of(context);
    if (prof < 40) return palette.error;
    if (prof < 70) return palette.warning;
    return palette.primary;
  }
}
