import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/stats_provider.dart';
import 'package:provider/provider.dart';
import '../cozy/cozy_tile.dart';
import 'activity_chart.dart';
import 'mastery_heatmap.dart';
import '../cozy/cozy_dialog_sheet.dart';

import '../profile/activity_view.dart';

enum AnalyticsMainTab { mastery, activity }

class AnalyticsPortal extends StatefulWidget {
  final Function(String name, String slug)? onSectionSelected;

  const AnalyticsPortal({super.key, this.onSectionSelected});

  @override
  createState() => _AnalyticsPortalState();
}

class _AnalyticsPortalState extends State<AnalyticsPortal> {
  AnalyticsMainTab _mainTab = AnalyticsMainTab.mastery;
  ActivityTimeframe _timeframe = ActivityTimeframe.week;
  String? _selectedSubjectTitle;
  String? _selectedSubjectSlug;
  bool _isGoingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      stats.fetchSummary();
      stats.fetchActivity();
    });
  }

  void _onSubjectSelected(String title, String slug) {
    Provider.of<StatsProvider>(context, listen: false).fetchSubjectDetail(slug);
    setState(() {
      _isGoingBack = false;
      _selectedSubjectTitle = title;
      _selectedSubjectSlug = slug;
    });
  }

  void _onBack() {
    setState(() {
      _isGoingBack = true;
      _selectedSubjectTitle = null;
      _selectedSubjectSlug = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CozyDialogSheet(
      onTapOutside: () => Navigator.pop(context),
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "FOCUS STATS",
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5D4037),
                letterSpacing: 2,
              ),
            ),
          ),

          // Top Tab Bar (Only visible in Activity mode or as generic filter)
          if (_mainTab == AnalyticsMainTab.activity) _buildTopTabBar(),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.fastOutSlowIn,
              switchOutCurve: Curves.easeInQuad,
              transitionBuilder: (child, animation) {
                final beginScale = _isGoingBack ? 1.08 : 0.92;
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: beginScale, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey("${_mainTab}_${_timeframe}_$_selectedSubjectSlug"),
                // color: const Color(0xFFFFFDF5), // Removed, let transparent flow so sheet color shows? Actually sheet has color.
                // But AnimatedSwitcher might need a container with color to prevent blending artifacts if fading?
                // Sheet color is 0xFFFFFDF5.
                color: const Color(0xFFFFFDF5),
                child: _buildBody(),
              ),
            ),
          ),
          
          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTopTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ActivityTimeframe.values.map((tab) => _buildTimeframeButton(tab)).toList(),
      ),
    );
  }

  Widget _buildTimeframeButton(ActivityTimeframe tab) {
    bool isActive = _timeframe == tab;
    return GestureDetector(
      onTap: () {
        final stats = Provider.of<StatsProvider>(context, listen: false);
        setState(() {
          _isGoingBack = false;
          _timeframe = tab;
        });
        stats.fetchActivity(timeframe: tab.name, anchorDate: DateTime.now());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD7CCC8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8D6E63)),
        ),
        child: Text(
          tab.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedSubjectSlug != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _onBack,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF8D6E63)),
                ),
                const SizedBox(width: 12),
                Text(_selectedSubjectTitle!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
              ],
            ),
            Expanded(
              child: MasteryHeatmap(
                subjectSlug: _selectedSubjectSlug!,
                onStartQuiz: widget.onSectionSelected,
              ),
            ),
          ],
        ),
      );
    }

    switch (_mainTab) {
      case AnalyticsMainTab.mastery:
        return _buildMasteryTab();
      case AnalyticsMainTab.activity:
        return _buildActivityTab();
    }
  }

  Widget _buildMasteryTab() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.subjectMastery.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const Text("Subject Mastery", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8CAA8C))),
            const SizedBox(height: 12),
            _buildMasteryGrid(stats.subjectMastery),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final totalQuestions = stats.activity.fold(0, (sum, item) => sum + item.count);
        final dateStr = DateFormat('EEE, MMM d, yyyy').format(DateTime.now()).toUpperCase();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 10),
                  Text(dateStr, style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              // Date navigation handled by ActivityChart/ActivityView
              const SizedBox(height: 10),
              ActivityChart(data: stats.activity, timeframe: _timeframe),
              const SizedBox(height: 20),
              Row(
                children: [
                   Expanded(child: _buildSummaryStatistic("TOTAL", totalQuestions.toString(), Icons.quiz)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildSummaryStatistic("CORRECT", stats.activity.fold(0, (sum, item) => sum + item.correctCount).toString(), Icons.check_circle_outline)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildSummaryStatistic("STREAK", "${stats.activity.where((d) => d.count > 0).length} Days", Icons.calendar_month)),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatistic(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5D4037).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF8D6E63)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label, 
                  style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF8D6E63), letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF5D4037))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryGrid(List<SubjectMastery> mastery) {
    // Map 'unknown' or 'none' to 'Pathophysiology'
    mastery = mastery.map((m) {
      if (m.slug == 'unknown' || m.slug == 'none' || m.subjectEn.toLowerCase() == 'unknown') {
        return SubjectMastery(
          subjectEn: "Pathophysiology", 
          slug: "pathophysiology", 
          totalAnswered: m.totalAnswered, 
          correctAnswered: m.correctAnswered, 
          masteryPercent: m.masteryPercent
        );
      }
      return m;
    }).toList();

    final placeholderNames = ["Pathophysiology", "Pathology", "Microbiology", "Pharmacology"];
    final coreSubjects = mastery.where((m) => m.slug != 'ecg').toList();
    final ecgSubject = mastery.where((m) => m.slug == 'ecg').toList();

    while (coreSubjects.length < 4) {
      coreSubjects.add(SubjectMastery(
        subjectEn: placeholderNames[coreSubjects.length], 
        slug: placeholderNames[coreSubjects.length].toLowerCase(), 
        totalAnswered: 0, correctAnswered: 0, masteryPercent: 0
      ));
    }

    List<Widget> gridItems = [];
    for (var i = 0; i < coreSubjects.length; i += 2) {
      gridItems.add(Row(children: [
        Expanded(child: _buildMasteryTile(coreSubjects[i])),
        const SizedBox(width: 12),
        if (i + 1 < coreSubjects.length) Expanded(child: _buildMasteryTile(coreSubjects[i + 1]))
        else const Expanded(child: SizedBox()),
      ]));
      gridItems.add(const SizedBox(height: 12));
    }

    if (ecgSubject.isNotEmpty) {
      gridItems.add(_buildMasteryTile(ecgSubject[0]));
    } else {
      gridItems.add(_buildMasteryTile(SubjectMastery(subjectEn: "ECG", slug: "ecg", totalAnswered: 0, correctAnswered: 0, masteryPercent: 0)));
    }
    return Column(children: gridItems);
  }

  Widget _buildMasteryTile(SubjectMastery item) {
    return CozyTile(
      onTap: () => _onSubjectSelected(item.subjectEn, item.slug),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(item.subjectEn.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${item.masteryPercent}%", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
              const Icon(Icons.insights_rounded, color: Color(0xFFB0BEC5), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.masteryPercent / 100,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF536D88)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(child: _buildBottomButton("Analytics", _mainTab == AnalyticsMainTab.mastery, () => setState(() => _mainTab = AnalyticsMainTab.mastery))),
          const SizedBox(width: 12),
          Expanded(child: _buildBottomButton("Activity", _mainTab == AnalyticsMainTab.activity, () => setState(() => _mainTab = AnalyticsMainTab.activity))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, bool active, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF8CAA8C) : Colors.white,
        foregroundColor: active ? Colors.white : const Color(0xFF8CAA8C),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF8CAA8C))),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
  // Date navigation is now handled within ActivityView widget
}
