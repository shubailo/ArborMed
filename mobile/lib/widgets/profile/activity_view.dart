import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/stats_provider.dart';
import 'package:provider/provider.dart';
import '../analytics/activity_chart.dart';

enum ActivityTimeframe { summary, day, week, month, year }

class ActivityView extends StatefulWidget {
  const ActivityView({Key? key}) : super(key: key);

  @override
  _ActivityViewState createState() => _ActivityViewState();
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
      int days = _timeframe == ActivityTimeframe.month ? 30 : 7;
      if (direction < 0) {
        _anchorDate = _anchorDate.subtract(Duration(days: days));
      } else {
        _anchorDate = _anchorDate.add(Duration(days: days));
        if (_anchorDate.isAfter(DateTime.now())) _anchorDate = DateTime.now();
      }
    });

    Provider.of<StatsProvider>(context, listen: false).fetchActivity(
      timeframe: _timeframe == ActivityTimeframe.summary ? 'week' : _timeframe.name, 
      anchorDate: _anchorDate
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopTabBar(),
        Expanded(
          child: Consumer<StatsProvider>(
            builder: (context, stats, _) {
              final totalQuestions = stats.activity.fold(0, (sum, item) => sum + item.count);
              final dateStr = DateFormat('EEE, MMM d, yyyy').format(_anchorDate).toUpperCase();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8CAA8C)),
                        const SizedBox(width: 10),
                        Text(dateStr, style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDateNav(),
                    const SizedBox(height: 10),
                    ActivityChart(data: stats.activity),
                    const SizedBox(height: 20),
                    _buildSummaryStatistic("TOTAL QUESTIONS ANSWERED", totalQuestions.toString()),
                    _buildSummaryStatistic("CORRECT ANSWERS", stats.activity.fold(0, (sum, item) => sum + item.correctCount).toString()),
                    _buildSummaryStatistic("MASTERY XP EARNED", (totalQuestions * 5).toString()),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
        setState(() {
          _timeframe = tab;
          _anchorDate = DateTime.now();
        });
        Provider.of<StatsProvider>(context, listen: false).fetchActivity(
          timeframe: tab.name == 'summary' ? 'week' : tab.name, 
          anchorDate: DateTime.now()
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8CAA8C).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF8CAA8C) : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          tab.name.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive ? const Color(0xFF8CAA8C) : const Color(0xFFB0BEC5),
          ),
        ),
      ),
    );
  }

  Widget _buildDateNav() {
    if (_timeframe == ActivityTimeframe.summary) return const SizedBox.shrink();
    
    final df = DateFormat('MMM d');
    final startStr = df.format(_anchorDate.subtract(Duration(days: _timeframe == ActivityTimeframe.month ? 30 : 7)));
    final endStr = df.format(_anchorDate);
    final label = "$startStr - $endStr";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF8D6E63)),
          onPressed: () => _navigateDate(-1),
        ),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        IconButton(
          icon: Icon(
            Icons.chevron_right, 
            color: _anchorDate.difference(DateTime.now()).inDays.abs() < 1 ? Colors.grey : const Color(0xFF8D6E63)
          ),
          onPressed: _anchorDate.difference(DateTime.now()).inDays.abs() < 1 ? null : () => _navigateDate(1),
        ),
      ],
    );
  }

  Widget _buildSummaryStatistic(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5))),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF5D4037))),
        ],
      ),
    );
  }
}
