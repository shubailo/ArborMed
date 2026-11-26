import 'package:flutter/material.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/cozy_panel.dart';
import '../../analytics/widgets/activity_chart.dart';
import 'quests/quest_list.dart';
import '../../quiz/screens/quiz_session_screen.dart';

import '../../analytics/models/activity_timeframe.dart';

export '../../analytics/models/activity_timeframe.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final session =
        context.select<StatsProvider, int>((stats) => stats.sessionRevision);
    return _PeriodView(key: ValueKey(session));
  }
}

class _PeriodView extends StatefulWidget {
  const _PeriodView({super.key});
  @override
  State<_PeriodView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_PeriodView> {
  late Future<List<ActivityData>> _period;
  void _load() {
    _period = context
        .read<StatsProvider>()
        .readActivityPeriod(_timeframe.name, _anchorDate);
    // A tab can be replaced before FutureBuilder attaches on the next frame.
    _period.ignore();
  }

  ActivityTimeframe _timeframe = ActivityTimeframe.week;
  DateTime _anchorDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _navigateDate(int direction) {
    setState(() {
      if (_timeframe == ActivityTimeframe.month) {
        final target =
            DateTime(_anchorDate.year, _anchorDate.month + direction);
        final lastDay = DateTime(target.year, target.month + 1, 0).day;
        _anchorDate = DateTime(
            target.year, target.month, _anchorDate.day.clamp(1, lastDay));
      } else {
        final step = _timeframe == ActivityTimeframe.week ? 7 : 1;
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month,
            _anchorDate.day + direction * step);
      }
      if (_anchorDate.isAfter(DateTime.now())) _anchorDate = DateTime.now();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CozyTheme.of(context).background,
      child: Column(
        children: [
          _buildTopTabBar(),
          Expanded(
            child: _timeframe == ActivityTimeframe.quests
                ? const QuestList()
                : FutureBuilder<List<ActivityData>>(
                    future: _period,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        final strings = AppLocalizations.of(context)!;
                        return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(strings.activityLoadFailed),
                              TextButton(
                                  onPressed: () => setState(_load),
                                  child: Text(strings.retry)),
                            ]));
                      }
                      final rows = snapshot.data ?? [];
                      final selectedDayProgress = rows
                          .where((row) =>
                              DateUtils.isSameDay(row.calendarDay, _anchorDate))
                          .fold(0, (sum, row) => sum + row.count);
                      final totalQuestions = rows.fold(
                        0,
                        (sum, item) => sum + item.count,
                      );
                      final totalMistakes = rows.fold(
                        0,
                        (sum, item) => sum + (item.count - item.correctCount),
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDailyPrescription(selectedDayProgress),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.activityTrend,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.of(context).textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                _buildDateSelector(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ActivityChart(
                              data: rows,
                              timeframe: _timeframe,
                            ),
                            const SizedBox(height: 24),
                            if (totalMistakes > 0)
                              _buildReviewAction(totalMistakes),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context)!.stats.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.of(context).textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatGrid(totalQuestions, rows),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPrescription(int todayCount) {
    const int goal = 50;
    bool isComplete = todayCount >= goal;

    return CozyPanel(
      variant: CozyPanelVariant.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete
                    ? Icons.check_circle
                    : Icons.medical_services_outlined,
                color: isComplete
                    ? CozyTheme.of(context).primary
                    : CozyTheme.of(context).accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete
                          ? AppLocalizations.of(context)!.goalAchieved
                          : AppLocalizations.of(context)!.dailyPrescription,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: CozyTheme.of(context).textPrimary,
                      ),
                    ),
                    Text(
                      isComplete
                          ? AppLocalizations.of(context)!.dailyDoseComplete
                          : AppLocalizations.of(
                              context,
                            )!
                              .needMoreToday(goal - todayCount),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CozyTheme.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "$todayCount/$goal",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: CozyTheme.of(context).textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progressive Market Segmented Chart with Pulse
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              const int segments = goal;
              final double gap = 2.0;
              final double segmentWidth =
                  (totalWidth - (segments - 1) * gap) / segments;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(segments, (index) {
                  final bool isFilled = index < todayCount;
                  final bool isCurrent = index == todayCount - 1 && !isComplete;

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 400 + (index * 15)),
                    curve: Curves.easeOutCubic,
                    height: isCurrent ? 10 : 8,
                    width: segmentWidth,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? (isComplete
                              ? CozyTheme.of(context).primary
                              : Color.lerp(
                                  CozyTheme.of(context).accent,
                                  CozyTheme.of(context).primary,
                                  index / segments,
                                ))
                          : CozyTheme.of(
                              context,
                            ).textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: CozyTheme.of(
                                  context,
                                ).accent.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : isComplete && isFilled
                              ? [
                                  BoxShadow(
                                    color: CozyTheme.of(
                                      context,
                                    ).primary.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                  ),
                                ]
                              : [],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getDateLabel() {
    if (_timeframe == ActivityTimeframe.month) {
      return DateFormat.yMMMM(Localizations.localeOf(context).toString())
          .format(_anchorDate);
    } else {
      // Week
      if (_timeframe == ActivityTimeframe.week) {
        final start =
            DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day - 6);
        return '${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(start)} - ${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(_anchorDate)}';
      }
      return DateFormat.MMMd(Localizations.localeOf(context).toString())
          .format(_anchorDate);
    }
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Previous Date',
          icon: Icon(
            Icons.chevron_left,
            size: 20,
            color: CozyTheme.of(context).textSecondary,
          ),
          onPressed: () {
            Provider.of<AudioProvider>(context, listen: false).playSfx('click');
            HapticFeedback.lightImpact();
            _navigateDate(-1);
          },
        ),
        Text(
          _getDateLabel(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: CozyTheme.of(context).textPrimary,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Next Date',
          icon: Icon(
            Icons.chevron_right,
            size: 20,
            color: _anchorDate.difference(DateTime.now()).inDays.abs() < 1
                ? CozyTheme.of(context).textSecondary.withValues(alpha: 0.2)
                : CozyTheme.of(context).textSecondary,
          ),
          onPressed: _anchorDate.difference(DateTime.now()).inDays.abs() < 1
              ? null
              : () {
                  Provider.of<AudioProvider>(
                    context,
                    listen: false,
                  ).playSfx('click');
                  HapticFeedback.lightImpact();
                  _navigateDate(1);
                },
        ),
      ],
    );
  }

  Widget _buildReviewAction(int mistakeCount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CozyTheme.of(context).accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CozyTheme.of(context).accent.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.history_edu_rounded,
            color: CozyTheme.of(context).accent,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mistakeReview,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: CozyTheme.of(context).textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.reviewMistakes(mistakeCount),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CozyTheme.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CozyTheme.of(context).primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 36),
            ),
            onPressed: () async {
              Provider.of<AudioProvider>(
                context,
                listen: false,
              ).playSfx('click');
              HapticFeedback.mediumImpact();
              final stats = Provider.of<StatsProvider>(context, listen: false);
              final timeframe = _timeframe;
              final anchor = _anchorDate;
              final owner = stats.authProvider.user?.id;
              List<int>? mistakeIds;
              try {
                mistakeIds = await stats.fetchMistakeIds(
                    timeframe: timeframe.name, anchorDate: anchor);
              } catch (_) {
                if (!mounted) return;
                if (owner != stats.authProvider.user?.id ||
                    timeframe != _timeframe ||
                    anchor != _anchorDate) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .mistakeReviewLoadFailed)),
                );
                return;
              }
              if (!mounted) return;
              if (mistakeIds == null ||
                  owner != stats.authProvider.user?.id ||
                  timeframe != _timeframe ||
                  anchor != _anchorDate) {
                return;
              }
              if (mistakeIds.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizSessionScreen(
                      questionIds: mistakeIds,
                      ownerId: owner,
                      systemName: "Mistake Review",
                      systemSlug: "review",
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.noMistakes),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.start,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(int total, List<ActivityData> rows) {
    final correct = rows.fold(
      0,
      (sum, item) => sum + item.correctCount,
    );
    final days =
        rows.where((d) => d.count > 0).map((d) => d.calendarDay).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.questions.toUpperCase(),
            total.toString(),
            Icons.quiz,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.quizCorrect.toUpperCase(),
            correct.toString(),
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.activityActiveDays,
            days.toString(),
            Icons.calendar_month,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CozyTheme.of(context).accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: CozyTheme.of(context).textSecondary,
            ),
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
                    color: CozyTheme.of(context).textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.of(context).textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ActivityTimeframe.values
            .map((tab) => _buildTimeframeButton(tab))
            .toList(),
      ),
    );
  }

  Widget _buildTimeframeButton(ActivityTimeframe tab) {
    bool isActive = _timeframe == tab;
    return GestureDetector(
      onTap: () {
        Provider.of<AudioProvider>(context, listen: false).playSfx('click');
        HapticFeedback.selectionClick();
        setState(() {
          _timeframe = tab;
          _anchorDate = DateTime.now();
          if (tab != ActivityTimeframe.quests) _load();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? CozyTheme.of(context).primary.withValues(alpha: 0.1)
              : CozyTheme.of(context).paperWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? CozyTheme.of(context).primary
                : CozyTheme.of(context).textPrimary.withValues(alpha: 0.1),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          _getTimeframeLabel(context, tab),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isActive
                ? CozyTheme.of(context).primary
                : CozyTheme.of(context).textSecondary,
          ),
        ),
      ),
    );
  }

  String _getTimeframeLabel(BuildContext context, ActivityTimeframe tab) {
    switch (tab) {
      case ActivityTimeframe.day:
        return AppLocalizations.of(context)!.day;
      case ActivityTimeframe.week:
        return AppLocalizations.of(context)!.week;
      case ActivityTimeframe.month:
        return AppLocalizations.of(context)!.month;
      case ActivityTimeframe.quests:
        return AppLocalizations.of(context)!.dailyQuests.toUpperCase();
    }
  }
}
