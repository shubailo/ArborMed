import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/stats_provider.dart';
import 'package:provider/provider.dart';
import '../cozy/cozy_panel.dart';
import 'activity_chart.dart';
import 'mastery_heatmap.dart';
import '../cozy/cozy_dialog_sheet.dart';
import '../../theme/cozy_theme.dart';

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
    final palette = CozyTheme.of(context);
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
                color: palette.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ),

          // Top Tab Bar
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
                    scale: Tween<double>(begin: beginScale, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key:
                    ValueKey("${_mainTab}_${_timeframe}_$_selectedSubjectSlug"),
                color: palette.paperCream,
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
        children: ActivityTimeframe.values
            .map((tab) => _buildTimeframeButton(tab))
            .toList(),
      ),
    );
  }

  Widget _buildTimeframeButton(ActivityTimeframe tab) {
    final palette = CozyTheme.of(context);
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
          color: isActive
              ? palette.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive
                  ? palette.primary
                  : palette.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Text(
          tab.name.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive ? palette.primary : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final palette = CozyTheme.of(context);
    if (_selectedSubjectSlug != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _onBack,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: palette.textSecondary),
                ),
                const SizedBox(width: 12),
                Text(_selectedSubjectTitle!,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary)),
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
    final palette = CozyTheme.of(context);
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.subjectMastery.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: palette.primary));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Text("Subject Mastery",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: palette.primary)),
            const SizedBox(height: 12),
            _buildMasteryGrid(stats.subjectMastery),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildActivityTab() {
    final palette = CozyTheme.of(context);
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        final totalQuestions =
            stats.activity.fold(0, (sum, item) => sum + item.count);
        final dateStr =
            DateFormat('EEE, MMM d, yyyy').format(DateTime.now()).toUpperCase();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: palette.secondary),
                  const SizedBox(width: 10),
                  Text(dateStr,
                      style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              ActivityChart(data: stats.activity, timeframe: _timeframe),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryStatistic(
                          "TOTAL", totalQuestions.toString(), Icons.quiz)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildSummaryStatistic(
                          "CORRECT",
                          stats.activity
                              .fold(0, (sum, item) => sum + item.correctCount)
                              .toString(),
                          Icons.check_circle_outline)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildSummaryStatistic(
                          "STREAK",
                          "${stats.activity.where((d) => d.count > 0).length} Days",
                          Icons.calendar_month)),
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
    final palette = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: palette.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: palette.textSecondary,
                      letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryGrid(List<SubjectMastery> mastery) {
    mastery = mastery.map((m) {
      if (m.slug == 'unknown' ||
          m.slug == 'none' ||
          m.subjectEn.toLowerCase() == 'unknown') {
        return SubjectMastery(
            subjectEn: "Pathophysiology",
            slug: "pathophysiology",
            totalAnswered: m.totalAnswered,
            correctAnswered: m.correctAnswered,
            masteryPercent: m.masteryPercent);
      }
      return m;
    }).toList();

    final placeholderNames = [
      "Pathophysiology",
      "Pathology",
      "Microbiology",
      "Pharmacology"
    ];
    final coreSubjects = mastery.where((m) => m.slug != 'ecg').toList();
    final ecgSubject = mastery.where((m) => m.slug == 'ecg').toList();

    while (coreSubjects.length < 4) {
      coreSubjects.add(SubjectMastery(
          subjectEn: placeholderNames[coreSubjects.length],
          slug: placeholderNames[coreSubjects.length].toLowerCase(),
          totalAnswered: 0,
          correctAnswered: 0,
          masteryPercent: 0));
    }

    List<Widget> gridItems = [];
    for (var i = 0; i < coreSubjects.length; i += 2) {
      gridItems.add(Row(children: [
        Expanded(child: _buildMasteryTile(coreSubjects[i])),
        const SizedBox(width: 12),
        if (i + 1 < coreSubjects.length)
          Expanded(child: _buildMasteryTile(coreSubjects[i + 1]))
        else
          const Expanded(child: SizedBox()),
      ]));
      gridItems.add(const SizedBox(height: 12));
    }

    if (ecgSubject.isNotEmpty) {
      gridItems.add(_buildMasteryTile(ecgSubject[0]));
    } else {
      gridItems.add(_buildMasteryTile(SubjectMastery(
          subjectEn: "ECG",
          slug: "ecg",
          totalAnswered: 0,
          correctAnswered: 0,
          masteryPercent: 0)));
    }
    return Column(children: gridItems);
  }

  Widget _buildMasteryTile(SubjectMastery item) {
    final palette = CozyTheme.of(context);
    return CozyPanel(
      onTap: () => _onSubjectSelected(item.subjectEn, item.slug),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.subjectEn.toUpperCase(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${item.masteryPercent}%",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary)),
              Icon(Icons.insights_rounded,
                  color: palette.textSecondary.withValues(alpha: 0.3),
                  size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.masteryPercent / 100,
              backgroundColor: palette.textPrimary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(palette.secondary),
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
          Expanded(
              child: _buildBottomButton(
                  "Analytics",
                  _mainTab == AnalyticsMainTab.mastery,
                  () => setState(() => _mainTab = AnalyticsMainTab.mastery))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildBottomButton(
                  "Activity",
                  _mainTab == AnalyticsMainTab.activity,
                  () => setState(() => _mainTab = AnalyticsMainTab.activity))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, bool active, VoidCallback onTap) {
    final palette = CozyTheme.of(context);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? palette.primary : palette.paperWhite,
        foregroundColor: active ? palette.textInverse : palette.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: palette.primary)),
      ),
      child: Text(label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
