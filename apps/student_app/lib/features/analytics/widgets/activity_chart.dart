import 'package:arbor_med/generated/l10n/app_localizations.dart';
import '../models/activity_timeframe.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:arbor_med/features/analytics/providers/stats_provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/paper_texture.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/utils/extensions/list_extensions.dart';

class ActivityChart extends StatefulWidget {
  final List<ActivityData> data;
  final ActivityTimeframe timeframe; // Added timeframe

  const ActivityChart({super.key, required this.data, required this.timeframe});

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int touchedIndex = -1;
  AppLocalizations get strings =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));

  @override
  void didUpdateWidget(ActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeframe != widget.timeframe ||
        oldWidget.data.safeGet(touchedIndex)?.date !=
            widget.data.safeGet(touchedIndex)?.date) {
      touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: CozyTheme.of(context).paperCream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
            child: Text(strings.activityEmpty,
                style: TextStyle(color: CozyTheme.of(context).textSecondary))),
      );
    }

    if (widget.timeframe == ActivityTimeframe.month) {
      return _buildHeatmap();
    }

    // Default: Bar Chart (Week/Day/Summary)
    return _buildBarChart();
  }

  Widget _buildHeatmap() {
    // 1. Determine max count for intensity normalization
    int maxCount = 1;
    for (var d in widget.data) {
      if (d.count > maxCount) maxCount = d.count;
    }

    final locale = Localizations.localeOf(context).toString();
    final material = MaterialLocalizations.of(context);
    final firstWeekday = material.firstDayOfWeekIndex;
    final leading = (widget.data.first.calendarDay.weekday - firstWeekday) % 7;
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CozyTheme.of(context).paperCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: CozyTheme.of(context).textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.activityMonthIntensity.toUpperCase(),
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.of(context).textSecondary,
                      letterSpacing: 1.2)),
              Row(
                children: [
                  Text(strings.activityLess,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: CozyTheme.of(context).textSecondary)),
                  const SizedBox(width: 8),
                  _buildLegendDot(0.2),
                  const SizedBox(width: 2),
                  _buildLegendDot(0.5),
                  const SizedBox(width: 2),
                  _buildLegendDot(0.9),
                  const SizedBox(width: 8),
                  Text(strings.activityMore,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: CozyTheme.of(context).textSecondary)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
              children: List.generate(
                  7,
                  (index) => Expanded(
                      child: Center(
                          child: Text(material
                              .narrowWeekdays[(firstWeekday + index) % 7]))))),
          const SizedBox(height: 6),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: leading + widget.data.length,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final d = widget.data[index - leading];
              final day = d.calendarDay;
              final isFuture = day.isAfter(today);

              if (isFuture) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey
                        .withValues(alpha: 0.1), // Dim disabled color
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }

              double intensity = (d.count / maxCount).clamp(0.1, 1.0);
              if (d.count == 0) intensity = 0.05;

              return Tooltip(
                message:
                    '${DateFormat.MMMd(locale).format(day)}\n${strings.adminQuestionCount(d.count)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: d.count > 0
                        ? CozyTheme.of(context, listen: false)
                            .primary
                            .withValues(alpha: intensity)
                        : Colors.grey.withValues(
                            alpha: 0.2), // Darker empty state for past days
                    borderRadius: BorderRadius.circular(4),
                    border: d.count > 0
                        ? null
                        : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: CozyTheme.of(context, listen: false)
            .primary
            .withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBarChart() {
    double maxY = 10;
    for (var d in widget.data) {
      if (d.count > maxY) maxY = d.count.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CozyTheme.of(context, listen: false).paperCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: CozyTheme.of(context, listen: false)
                .textPrimary
                .withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: CozyTheme.of(context, listen: false)
                  .textPrimary
                  .withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PaperTexture(
          opacity: 0.03,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, right: 10),
            child: BarChart(
              key: ValueKey(widget.data.length),
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => CozyTheme.of(context, listen: false)
                        .surface
                        .withValues(alpha: 0.95),
                    tooltipBorder: BorderSide(
                        color: CozyTheme.of(context, listen: false)
                            .textPrimary
                            .withValues(alpha: 0.1)),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = widget.data.safeGet(group.x);
                      if (data == null) return null;
                      return BarTooltipItem(
                        '${strings.adminQuestionCount(data.count)}\n',
                        GoogleFonts.outfit(
                            color: CozyTheme.of(context, listen: false)
                                .textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text:
                                strings.activityCorrectCount(data.correctCount),
                            style: TextStyle(
                                color: CozyTheme.of(context, listen: false)
                                    .primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapDownEvent && response?.spot != null) {
                      final index = response!.spot!.touchedBarGroupIndex;
                      if (index >= 0 && index < widget.data.length) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          touchedIndex = index;
                        });
                      }
                    } else if (event is FlPointerExitEvent) {
                      setState(() {
                        touchedIndex = -1;
                      });
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return const SizedBox();
                        }

                        // Use the day label from backend
                        final activity = widget.data[index];
                        final locale =
                            Localizations.localeOf(context).toString();
                        final label = widget.timeframe == ActivityTimeframe.day
                            ? activity.dayLabel ??
                                DateFormat.Hm(locale)
                                    .format(activity.date.toLocal())
                            : DateFormat.E(locale).format(activity.calendarDay);

                        // Special formatting for Hourly View
                        if (widget.timeframe == ActivityTimeframe.day) {
                          // label is like "HH:00" from backend
                          // Only show every 4th hour to prevent crowding if many bars
                          if (index % 4 != 0 &&
                              index != widget.data.length - 1) {
                            return const SizedBox();
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: touchedIndex == index
                                  ? CozyTheme.of(context, listen: false).primary
                                  : CozyTheme.of(context, listen: false)
                                      .textSecondary
                                      .withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: touchedIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (maxY / 4).clamp(1, double.infinity).toDouble(),
                      getTitlesWidget: (value, meta) {
                        String text;
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          text = value.toInt().toString();
                        }
                        return Text(
                          text,
                          style: TextStyle(
                              color: CozyTheme.of(context, listen: false)
                                  .textSecondary
                                  .withValues(alpha: 0.5),
                              fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      (maxY / 4).clamp(1, double.infinity).toDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: CozyTheme.of(context, listen: false)
                        .textPrimary
                        .withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.data.asMap().entries.map((e) {
                  final index = e.key;
                  final d = e.value;
                  final isTouched = index == touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: d.count.toDouble(),
                        width: widget.timeframe == ActivityTimeframe.day
                            ? 8
                            : 16, // Thinner bars for hourly
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        color: CozyTheme.of(context, listen: false).primary,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: CozyTheme.of(context, listen: false)
                              .textPrimary
                              .withValues(alpha: 0.03),
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(
                              0,
                              d.correctCount.clamp(0, d.count).toDouble(),
                              CozyTheme.of(context, listen: false).primary),
                          BarChartRodStackItem(
                              d.correctCount.clamp(0, d.count).toDouble(),
                              d.count.toDouble(),
                              Colors.red.withValues(alpha: 0.6)),
                        ],
                      ),
                    ],
                    showingTooltipIndicators: isTouched ? [0] : [],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ),
      ),
    );
  }
}
