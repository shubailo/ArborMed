import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import 'components/admin_csv_helper.dart';
import 'components/admin_notification_dialog.dart';
import 'components/question_editor_dialog.dart';
import '../../utils/extensions/list_extensions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int? _currentSubjectId;
  String _selectedType = '';
  List<Map<String, dynamic>> _tabs = [];
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final provider = Provider.of<StatsProvider>(context, listen: false);
    
    // Fetch aggregated stats for the specific subject
    provider.fetchQuestionStats(topicId: _currentSubjectId);
    provider.fetchWallOfPain();
    
    if (_tabs.isEmpty) {
      provider.fetchTopics().then((_) {
        if (mounted) _buildDynamicTabs();
      });
    }

    final activeSlug = _getActiveSubjectSlug();
    if (activeSlug != null) {
      provider.fetchSubjectDetail(activeSlug);
    } else {
      // Global View: Fetch summary of all subjects
      provider.fetchAdminSummary();
    }
  }

  void _buildDynamicTabs() {
    final provider = Provider.of<StatsProvider>(context, listen: false);
    final subjects = ['Pathophysiology', 'Pathology', 'Microbiology', 'Pharmacology'];
    
    setState(() {
      _tabs = [
        {'label': 'All', 'type': '', 'topicId': null, 'slug': null},
        ...subjects.map((name) {
          final t = provider.topics.firstWhere(
            (topic) => (topic['name_en']?.toString() == name) || (topic['name']?.toString() == name), 
            orElse: () => {'id': null, 'slug': null}
          );
          return {
            'label': name,
            'type': '',
            'topicId': t['id'],
            'slug': t['slug'],
          };
        }),
        {'label': 'ECG', 'type': 'ecg', 'topicId': null, 'slug': 'ecg'},
        {'label': 'Case', 'type': 'case_study', 'topicId': null, 'slug': 'case-studies'},
      ];
      if (_isInit && _tabs.isNotEmpty) {
        // Default to "All" (index 0)
        _currentSubjectId = _tabs[0]['topicId'];
        _selectedType = _tabs[0]['type'] ?? '';
        _isInit = false;
        // removed _refresh() here to avoid duplicate call
      }
    });
  }

  String? _getActiveSubjectSlug() {
     if (_tabs.isEmpty) return null;
     final tab = _tabs.firstWhere(
       (t) => t['topicId'] == _currentSubjectId && t['type'] == _selectedType,
       orElse: () => _tabs[0],
     );
     return tab['slug'];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, child) {
        // Only show full screen loader if we have NO data at all
        if (_tabs.isEmpty || (stats.isLoading && stats.questionStats.isEmpty && stats.adminSummary.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: CozyTheme.of(context).background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              return RepaintBoundary(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stats.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
                        ),
                      _buildHeader(stats),
                      const SizedBox(height: 24),
                      if (isMobile) ...[
                        _buildKpiRow(stats, isMobile),
                        const SizedBox(height: 16),
                        _buildQuickActions(stats),
                        const SizedBox(height: 24),
                      ] else
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: _buildKpiRow(stats, isMobile)),
                              const SizedBox(width: 24),
                              Expanded(flex: 1, child: _buildQuickActions(stats)),
                            ],
                          ),
                        ),
                      SizedBox(height: isMobile ? 16 : 32),
                      RepaintBoundary(child: _buildTopicProficiency(stats)),

                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(StatsProvider stats) {
    final activeTab = _tabs.firstWhere(
      (t) => t['topicId'] == _currentSubjectId && t['type'] == _selectedType,
      orElse: () => _tabs[0],
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<int>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (index) {
                setState(() {
                  _selectedType = _tabs[index]['type']!;
                  _currentSubjectId = _tabs[index]['topicId'];
                });
                _refresh();
              },
              itemBuilder: (context) => _tabs.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value['label'], style: GoogleFonts.quicksand(color: CozyTheme.of(context, listen: false).textPrimary)),
                );
              }).toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activeTab['label'],
                    style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.bold, color: CozyTheme.of(context, listen: false).textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, size: 28, color: CozyTheme.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text("Autumn Semester 2026",
              style: GoogleFonts.quicksand(fontSize: 16, color: CozyTheme.of(context, listen: false).textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(),
      ],
    );
  }



  Widget _buildKpiRow(StatsProvider stats, bool isMobile) {
    final attemptsList = stats.questionStats.where((q) => q.totalAttempts > 0).toList();
    final avgCorrect = attemptsList.isEmpty 
      ? 0.0 
      : attemptsList.fold<int>(0, (sum, q) => sum + q.correctPercentage) / attemptsList.length;

    // Live Trends from backend
    final String userTrend = "+${stats.userStats['new_users_24h'] ?? 0}";
    final double classAvgTrendVal = double.tryParse(stats.userStats['class_avg_trend']?.toString() ?? '0') ?? 0;
    final String classTrend = "${classAvgTrendVal >= 0 ? '+' : ''}${classAvgTrendVal.toStringAsFixed(1)}%";
    final double bloomTrendVal = double.tryParse(stats.userStats['bloom_trend']?.toString() ?? '0') ?? 0;
    final String bloomTrend = "${bloomTrendVal >= 0 ? '+' : ''}${bloomTrendVal.toStringAsFixed(1)}";

    final kpiCards = [
      _buildKpiCard("TOTAL USERS", stats.userStats['total_users'].toString(), Icons.people_outline, stats.userStats['total_users'].toString(), "Registered students", userTrend, true),
      _buildKpiCard("CLASS AVG", "${avgCorrect.toStringAsFixed(1)}%", Icons.timeline_rounded, "${avgCorrect.toStringAsFixed(1)}%", "Overall correctness", classTrend, classAvgTrendVal >= 0),
      _buildKpiCard("AVG BLOOM LEVEL", "L${stats.userStats['avg_bloom']?.toStringAsFixed(1) ?? '1.0'}", Icons.auto_graph_outlined, "L${stats.userStats['avg_bloom']?.toStringAsFixed(1) ?? '1.0'}", "Pedagogical depth", bloomTrend, bloomTrendVal >= 0),
    ];

    if (isMobile) {
      return Column(
        children: [
          kpiCards[0],
          const SizedBox(height: 12),
          kpiCards[1],
          const SizedBox(height: 12),
          kpiCards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: kpiCards[0]),
        const SizedBox(width: 20),
        Expanded(child: kpiCards[1]),
        const SizedBox(width: 20),
        Expanded(child: kpiCards[2]),
      ],
    );
  }

  Widget _buildKpiCard(String title, String displayValue, IconData icon, String value, String subtitle, String trend, bool? isPositive) {
    final palette = CozyTheme.of(context);
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, anim, child) => Transform.translate(
        offset: Offset(0, 20 * (1.0 - anim)),
        child: Opacity(
          opacity: anim,
          child: child,
        ),
      ),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: palette.paperWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            ...palette.shadowSmall,
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Texture
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.03,
                child: Icon(icon, size: 120, color: palette.textPrimary),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with Gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [palette.primary, palette.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: GoogleFonts.quicksand(fontSize: 10, color: palette.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 2),
                        Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                        Text(subtitle, style: GoogleFonts.quicksand(fontSize: 11, color: palette.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Trend Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive == null 
                    ? palette.background 
                    : (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPositive != null) ...[
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 12, color: isPositive ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                    ],
                    Text(trend, style: TextStyle(
                      color: isPositive == null ? palette.textSecondary : (isPositive ? Colors.green : Colors.red),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicProficiency(StatsProvider stats) {
    final slug = _getActiveSubjectSlug();
    final data = (slug == null) ? stats.adminSummary : (stats.sectionMastery[slug] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CozyTheme.of(context).paperWhite, borderRadius: BorderRadius.circular(24), boxShadow: CozyTheme.of(context).shadowSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Topic Proficiency", style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: CozyTheme.of(context).background, borderRadius: BorderRadius.circular(8)),
                child: Text("DETAILS", style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.bold, color: CozyTheme.of(context).accent)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 400, // BIGGER as requested
            child: data.isEmpty 
              ? const Center(child: Text("No data available for this subject"))
              : BarChart(
                  key: ValueKey(data.length),
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => CozyTheme.of(context, listen: false).paperWhite,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = data.safeGet(groupIndex);
                          if (item == null) return null;
                          final label = rodIndex == 0 ? 'Success Rate' : 'Avg Time';
                          // Mapping back from 0-100 scale: value * 1.2 = seconds (since 100 * 1.2 = 120)
                          final value = rodIndex == 0 ? '${rod.toY.toInt()}%' : '${(rod.toY * 1.2).toStringAsFixed(1)}s';
                          return BarTooltipItem(
                            "$label\n$value",
                            TextStyle(color: CozyTheme.of(context, listen: false).textPrimary, fontWeight: FontWeight.bold),
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
                            if (index < 0 || index >= data.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 14.0, right: 10),
                              child: Transform.rotate(
                                angle: -0.6, // Tilted for readability
                                child: Text(
                                  data[index]['section']?.toString() ?? '...',
                                  style: TextStyle(color: CozyTheme.of(context, listen: false).textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
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
                          getTitlesWidget: (value, meta) => Text("${value.toInt()}%", style: TextStyle(color: CozyTheme.of(context, listen: false).textSecondary, fontSize: 10)),
                        )
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 25,
                          getTitlesWidget: (value, meta) {
                             // 0 -> 0s, 25 -> 30s, 50 -> 60s, 75 -> 90s, 100 -> 120s
                             final seconds = (value * 1.2).toInt();
                             return Text("${seconds}s", style: TextStyle(color: CozyTheme.of(context).accent, fontSize: 10, fontWeight: FontWeight.bold));
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: false, 
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(color: CozyTheme.of(context, listen: false).textSecondary.withValues(alpha: 0.1), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((e) {
                      final mastery = double.tryParse(e.value['proficiency']?.toString() ?? '0') ?? 0;
                      final timeMs = double.tryParse(e.value['avg_time_ms']?.toString() ?? '0') ?? 0;
                      final timeSec = timeMs / 1000.0;
                      
                      // Mapping 120 seconds to 100 on the scale
                      final timeValueForChart = (timeSec / 1.2).clamp(0, 100).toDouble();
                      
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
              _buildLegendItem("Success Rate (%)", CozyTheme.of(context, listen: false).primary),
              const SizedBox(width: 32),
              _buildLegendItem("Avg Time Spent (sec)", CozyTheme.of(context, listen: false).accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.quicksand(fontSize: 13, color: CozyTheme.of(context, listen: false).textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickActions(StatsProvider stats) {
    final palette = CozyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -10, bottom: -10,
            child: Icon(Icons.bolt_rounded, size: 80, color: palette.accent.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildActionGrid(stats),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(StatsProvider stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionBtn("Add Que", Icons.add_circle_outline, () {
              showDialog(
                context: context,
                builder: (context) => QuestionEditorDialog(
                  question: null,
                  topics: Provider.of<StatsProvider>(context, listen: false).topics,
                  onSaved: () {
                    _refresh();
                  },
                ),
              );
            })),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn("Import", Icons.description_outlined, () {
              AdminCsvHelper.downloadQuestions(stats.adminQuestions);
            })),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionBtn("Report", Icons.file_download_outlined, () {
              AdminCsvHelper.downloadUserStats(stats.questionStats);
            })),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn("Notification", Icons.email_outlined, () {
              showDialog(context: context, builder: (c) => const AdminNotificationDialog());
            })),
          ],
        ),
      ],
    );
  }








  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    final palette = CozyTheme.of(context, listen: false);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.textSecondary.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: palette.textPrimary, size: 18),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary)),
          ],
        ),
      ),
    );
  }
}
