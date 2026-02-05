import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../services/stats_provider.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_card.dart';
import '../analytics/activity_chart.dart';
import 'package:mobile/screens/game/quiz_session_screen.dart';

enum ActivityTimeframe { day, week, month }

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  ActivityTimeframe _timeframe = ActivityTimeframe.week;
  DateTime _anchorDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatsProvider>(context, listen: false).fetchActivity(timeframe: 'week');
    });
  }

  void _navigateDate(int direction) {
    setState(() {
      if (_timeframe == ActivityTimeframe.day) {
        if (direction < 0) {
          _anchorDate = _anchorDate.subtract(const Duration(days: 1));
        } else {
          _anchorDate = _anchorDate.add(const Duration(days: 1));
        }
      } else if (_timeframe == ActivityTimeframe.week) {
        if (direction < 0) {
          _anchorDate = _anchorDate.subtract(const Duration(days: 7));
        } else {
          _anchorDate = _anchorDate.add(const Duration(days: 7));
        }
      } else if (_timeframe == ActivityTimeframe.month) {
        if (direction < 0) {
          final targetMonth = _anchorDate.month - 1;
          final targetYear = _anchorDate.year;
          final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          final clampedDay = _anchorDate.day.clamp(1, daysInTargetMonth);
          _anchorDate = DateTime(targetYear, targetMonth, clampedDay);
        } else {
          final targetMonth = _anchorDate.month + 1;
          final targetYear = _anchorDate.year;
          final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          final clampedDay = _anchorDate.day.clamp(1, daysInTargetMonth);
          _anchorDate = DateTime(targetYear, targetMonth, clampedDay);
        }
      }

      if (_anchorDate.isAfter(DateTime.now())) _anchorDate = DateTime.now();
    });

    Provider.of<StatsProvider>(context, listen: false).fetchActivity(
      timeframe: _timeframe.name,
      anchorDate: _anchorDate
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CozyTheme.of(context).background,
      child: Column(
        children: [
          _buildTopTabBar(),
          Expanded(
            child: Consumer<StatsProvider>(
              builder: (context, stats, _) {
                final todayData = stats.activity.isEmpty 
                  ? null 
                  : stats.activity.firstWhere(
                      (d) => d.date.day == DateTime.now().day && d.date.month == DateTime.now().month, 
                      orElse: () => stats.activity.last
                    );
                    
                final totalQuestions = stats.activity.fold(0, (sum, item) => sum + item.count);
                final totalMistakes = stats.activity.fold(0, (sum, item) => sum + (item.count - item.correctCount));

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDailyPrescription(todayData?.count ?? 0),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("ACTIVITY TREND", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textSecondary, letterSpacing: 1.2)),
                          _buildDateSelector(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ActivityChart(data: stats.activity, timeframe: _timeframe),
                      const SizedBox(height: 24),
                      if (totalMistakes > 0 && (_timeframe == ActivityTimeframe.day || _timeframe == ActivityTimeframe.week)) 
                        _buildReviewAction(totalMistakes),
                      const SizedBox(height: 24),
                      Text("STATISTICS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textSecondary, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildStatGrid(totalQuestions, stats),
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

    return CozyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.medical_services_outlined, 
                color: isComplete ? CozyTheme.of(context).primary : CozyTheme.of(context).accent, 
                size: 20
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? "GOAL ACHIEVED!" : "DAILY PRESCRIPTION",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, color: CozyTheme.of(context).textPrimary),
                    ),
                    Text(
                      isComplete ? "Daily dose complete." : "Need ${goal - todayCount} more today.",
                      style: GoogleFonts.inter(fontSize: 11, color: CozyTheme.of(context).textSecondary),
                    ),
                  ],
                ),
              ),
              Text("$todayCount/$goal", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: CozyTheme.of(context).textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          // Progressive Market Segmented Chart with Pulse
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              const int segments = goal;
              final double gap = 2.0;
              final double segmentWidth = (totalWidth - (segments - 1) * gap) / segments;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(segments, (index) {
                  final bool isFilled = index < todayCount;
                  final bool isCurrent = index == todayCount - 1 && !isComplete;

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 400 + (index * 15)),
                    curve: Curves.elasticOut,
                    height: isCurrent ? 10 : 8,
                    width: segmentWidth,
                    decoration: BoxDecoration(
                      color: isFilled 
                          ? (isComplete ? CozyTheme.of(context).primary : Color.lerp(CozyTheme.of(context).accent, CozyTheme.of(context).primary, index / segments))
                          : CozyTheme.of(context).textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isCurrent 
                          ? [BoxShadow(color: CozyTheme.of(context).accent.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)] 
                          : isComplete && isFilled
                              ? [BoxShadow(color: CozyTheme.of(context).primary.withValues(alpha: 0.2), blurRadius: 2)]
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
      return DateFormat('MMMM').format(_anchorDate);
    } else {
      // Week
      if (_timeframe == ActivityTimeframe.week) {
         final start = _anchorDate.subtract(const Duration(days: 6));
         return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(_anchorDate)}';
      }
      return DateFormat('MMM d').format(_anchorDate);
    }
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.chevron_left, size: 20, color: CozyTheme.of(context).textSecondary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _navigateDate(-1);
          },
        ),
        Text(
          _getDateLabel(),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: CozyTheme.of(context).textPrimary),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.chevron_right, 
            size: 20, 
            color: _anchorDate.difference(DateTime.now()).inDays.abs() < 1 ? CozyTheme.of(context).textSecondary.withValues(alpha: 0.2) : CozyTheme.of(context).textSecondary
          ),
          onPressed: _anchorDate.difference(DateTime.now()).inDays.abs() < 1 ? null : () {
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
        border: Border.all(color: CozyTheme.of(context).accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: CozyTheme.of(context).accent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MISTAKE REVIEW", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary)),
                Text("Review $mistakeCount failed questions.", style: GoogleFonts.inter(fontSize: 12, color: CozyTheme.of(context).textSecondary)),
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
              HapticFeedback.mediumImpact();
              final stats = Provider.of<StatsProvider>(context, listen: false);
              final mistakeIds = await stats.fetchMistakeIds(timeframe: _timeframe.name, anchorDate: _anchorDate);
              
              if (mistakeIds.isNotEmpty && mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizSessionScreen(questionIds: mistakeIds, systemName: "Mistake Review", systemSlug: "review")));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No mistakes found to review in this period!")));
              }
            },
            child: Text("START", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(int total, StatsProvider stats) {
    final correct = stats.activity.fold(0, (sum, item) => sum + item.correctCount);
    final days = stats.activity.where((d) => d.count > 0).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard("QUESTIONS", total.toString(), Icons.quiz)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("CORRECT", correct.toString(), Icons.check_circle_outline)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("CONSISTENCY", "$days Days", Icons.calendar_month)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CozyTheme.of(context).accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: CozyTheme.of(context).textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label, 
                  style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textSecondary, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: CozyTheme.of(context).textPrimary)),
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
        children: ActivityTimeframe.values.map((tab) => _buildTimeframeButton(tab)).toList(),
      ),
    );
  }

  Widget _buildTimeframeButton(ActivityTimeframe tab) {
    bool isActive = _timeframe == tab;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _timeframe = tab;
          _anchorDate = DateTime.now();
        });
        Provider.of<StatsProvider>(context, listen: false).fetchActivity(
          timeframe: tab.name, 
          anchorDate: DateTime.now()
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? CozyTheme.of(context).primary.withValues(alpha: 0.1) : CozyTheme.of(context).paperWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? CozyTheme.of(context).primary : CozyTheme.of(context).textPrimary.withValues(alpha: 0.1)),
          boxShadow: isActive ? [BoxShadow(color: CozyTheme.of(context).primary.withValues(alpha: 0.1), blurRadius: 4)] : [],
        ),
        child: Text(
          tab.name.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isActive ? CozyTheme.of(context).primary : CozyTheme.of(context).textSecondary,
          ),
        ),
      ),
    );
  }
}
