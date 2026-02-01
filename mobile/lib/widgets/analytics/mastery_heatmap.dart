import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      Provider.of<StatsProvider>(context, listen: false).fetchSubjectDetail(widget.subjectSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final List<Map<String, dynamic>> rawData = stats.sectionMastery[widget.subjectSlug] ?? [];
        
        if (rawData.isEmpty) {
          return const Center(child: Text("Loading Clinical Data...", style: TextStyle(color: Color(0xFF8D6E63))));
        }

        final List<Map<String, dynamic>> sortedData = List.from(rawData);
        if (sortedData.length > 12) sortedData.removeRange(12, sortedData.length);

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
              _buildExpandedFooter(sortedData.firstWhere((d) => d['slug'] == _expandedSlug)),
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
    final critical = used.where((d) => _parseProficiency(d['proficiency']) < 40).toList();
    if (critical.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.report_problem_rounded, color: Colors.red.shade800, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "DIAGNOSTIC ALERT: ${critical.length} sectors need clinical review.",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900),
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

    return CozyTile(
      onTap: () {
        setState(() {
          _expandedSlug = isSelected ? null : data['slug'];
        });
      },
      hoverBorderColor: masteryColor,
      backgroundColor: isSelected ? masteryColor.withValues(alpha: 0.04) : Colors.white,
      border: BorderSide(
        color: isUsed ? (isSelected ? masteryColor : masteryColor.withValues(alpha: 0.5)) : Colors.grey.shade200,
        width: isSelected ? 3 : 2,
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6), // COMPACT PADDING to prevent mobile overflow
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                  color: const Color(0xFF5D4037).withValues(alpha: 0.8),
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
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  if (needsRevision)
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: iconSize)
                  else
                    Icon(Icons.insights_rounded, color: Colors.grey.shade200, size: iconSize),
                ],
              ),
              
              // 3. Progress Bar (Thin but visible)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (proficiency / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF5F5F5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUsed ? masteryColor : Colors.grey.shade100,
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildExpandedFooter(Map<String, dynamic> data) {
    int attempts = _parseAttempts(data['attempts']);
    int sessions = int.tryParse(data['sessions_count']?.toString() ?? '0') ?? 0;
    double proficiency = _parseProficiency(data['proficiency']);
    int bloomLevel = (data['bloom_level'] != null) ? int.parse(data['bloom_level'].toString()) : 1;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getColorForProficiency(proficiency).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['section'].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
              Text("BLOOM LVL $bloomLevel", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF536D88))),
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
              backgroundColor: const Color(0xFF8CAA8C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("LAUNCH CLINICAL SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
        Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey)),
      ],
    );
  }

  Color _getColorForProficiency(double prof) {
    if (prof < 40) return Colors.red.shade400;
    if (prof < 70) return Colors.orange.shade400;
    return const Color(0xFF8CAA8C);
  }
}
