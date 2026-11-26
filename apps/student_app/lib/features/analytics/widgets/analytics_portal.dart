import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/widgets/cozy/cozy_panel.dart';
import 'mastery_heatmap.dart';
import 'package:arbor_med/widgets/cozy/cozy_dialog_sheet.dart';
import 'package:arbor_med/theme/cozy_theme.dart';

import '../../profile/widgets/activity_view.dart';

enum AnalyticsMainTab { mastery, activity }

class AnalyticsPortal extends StatelessWidget {
  final Function(String name, String slug)? onSectionSelected;

  const AnalyticsPortal({super.key, this.onSectionSelected});

  @override
  Widget build(BuildContext context) {
    final revision =
        context.select<StatsProvider, int>((p) => p.sessionRevision);
    return _PortalBody(
        key: ValueKey(revision), onSectionSelected: onSectionSelected);
  }
}

class _PortalBody extends StatefulWidget {
  final Function(String name, String slug)? onSectionSelected;
  const _PortalBody({super.key, this.onSectionSelected});
  @override
  State<_PortalBody> createState() => _AnalyticsPortalState();
}

class _AnalyticsPortalState extends State<_PortalBody> {
  AnalyticsMainTab _mainTab = AnalyticsMainTab.mastery;
  String? _selectedSubjectTitle;
  String? _selectedSubjectSlug;
  bool _isGoingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stats = Provider.of<StatsProvider>(context, listen: false);
      stats.fetchSummary();
    });
  }

  void _onSubjectSelected(String title, String slug) {
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
              AppLocalizations.of(context)!.stats.toUpperCase(),
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ),

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
                key: ValueKey("${_mainTab}_$_selectedSubjectSlug"),
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

  Widget _buildBody() {
    final palette = CozyTheme.of(context);
    if (_mainTab == AnalyticsMainTab.mastery && _selectedSubjectSlug != null) {
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
        return const ActivityView();
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
        final strings = AppLocalizations.of(context)!;
        if (stats.summaryFailed) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(strings.masteryLoadFailed),
            TextButton(
                onPressed: stats.fetchSummary, child: Text(strings.retry)),
          ]));
        }
        if (stats.subjectMastery.isEmpty) {
          return Center(child: Text(strings.masteryEmpty));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Text(strings.subjectMastery,
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

  Widget _buildMasteryGrid(List<SubjectMastery> mastery) {
    final coreSubjects =
        mastery.where((subject) => subject.slug != 'ecg').toList();
    final ecgSubject = mastery.where((subject) => subject.slug == 'ecg');
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
      gridItems.add(_buildMasteryTile(ecgSubject.first));
    }
    return Column(children: gridItems);
  }

  Widget _buildMasteryTile(SubjectMastery item) {
    final palette = CozyTheme.of(context);
    final name = Localizations.localeOf(context).languageCode == 'hu'
        ? item.subjectHu ?? item.subjectEn
        : item.subjectEn;
    return CozyPanel(
      onTap: () => _onSubjectSelected(name, item.slug),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name.toUpperCase(),
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
                  AppLocalizations.of(context)!.analyticsTab,
                  _mainTab == AnalyticsMainTab.mastery,
                  () => setState(() => _mainTab = AnalyticsMainTab.mastery))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildBottomButton(
                  AppLocalizations.of(context)!.activityTab,
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
