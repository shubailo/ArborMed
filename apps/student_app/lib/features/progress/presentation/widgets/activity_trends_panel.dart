import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import '../providers/progress_providers.dart';
import 'activity_trends_chart.dart';
import 'package:student_app/features/study/presentation/widgets/mistake_review_intro_panel.dart';

class ActivityTrendsPanel extends ConsumerStatefulWidget {
  const ActivityTrendsPanel({super.key});

  @override
  ConsumerState<ActivityTrendsPanel> createState() =>
      _ActivityTrendsPanelState();
}

class _ActivityTrendsPanelState extends ConsumerState<ActivityTrendsPanel> {
  String _selectedRange = '7d';

  @override
  Widget build(BuildContext context) {
    final trendsAsync = ref.watch(activityTrendsProvider(_selectedRange));

    return Container(
      padding: const EdgeInsets.all(CozyTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.ivoryCream, width: 2),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity Trends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmBrown,
                ),
              ),
              _buildRangeToggle(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: trendsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.sageGreen),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (trends) => ActivityTrendsChart(trends: trends),
            ),
          ),
          const SizedBox(height: 24),
          trendsAsync.maybeWhen(
            data: (trends) {
              if (trends.overallAccuracy < 0.7 && trends.days.isNotEmpty) {
                return _buildMistakeReviewCTA();
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ivoryCream,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            title: '7D',
            isSelected: _selectedRange == '7d',
            onTap: () => setState(() => _selectedRange = '7d'),
          ),
          _ToggleOption(
            title: '30D',
            isSelected: _selectedRange == '30d',
            onTap: () => setState(() => _selectedRange = '30d'),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeReviewCTA() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softClay.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softClay.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softClay,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_edu, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need a refresher?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warmBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review your recent mistakes to improve your accuracy.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.warmBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const MistakeReviewIntroPanel(),
              );
            },
            child: const Text(
              'Review',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppTheme.sageGreen
                : AppTheme.warmBrown.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
