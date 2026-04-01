import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _studentService = GetIt.I<StudentContract>() as ChangeNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = GetIt.I<StudentContract>();
      student.fetchSummary();
      student.fetchActivity('week');
      student.fetchReadiness();
      student.fetchSmartReview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      body: ListenableBuilder(
        listenable: _studentService,
        builder: (context, _) {
          final student = GetIt.I<StudentContract>();
          
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, student),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildEnterRoomCard(context),
                    _buildMistakeReviewCard(context, student),
                    const SizedBox(height: 24),
                    _buildReadinessSection(context, student),
                    const SizedBox(height: 32),
                    _buildSmartReviewSection(context, student),
                    const SizedBox(height: 32),
                    _buildMasterySection(context, student),
                    const SizedBox(height: 32),
                    _buildActivitySection(context, student),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, StudentContract student) {
    final theme = CozyTheme.of(context);
    
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: theme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Medical Dashboard', style: TextStyle(color: theme.paperWhite)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -20,
                bottom: -20,
                child: const Icon(Icons.analytics_rounded, size: 150, color: Colors.white10),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStatChip(context, Icons.bolt, 'Level ${student.getLevel()}'),
                        const SizedBox(width: 8),
                        _buildStatChip(context, Icons.currency_bitcoin, '${student.getCoins()} coins'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_pin, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEnterRoomCard(BuildContext context) {
    final theme = CozyTheme.of(context);
    return GestureDetector(
      onTap: () => context.push('/room'),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.primary, theme.primaryLight],
          ),
          boxShadow: theme.shadowMedium,
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -10,
              top: -10,
              child: Icon(Icons.meeting_room_rounded, size: 100, color: Colors.white24),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Study Room', style: theme.headingLarge.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Enter your workspace and focus.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakeReviewCard(BuildContext context, StudentContract student) {
    return FutureBuilder<int>(
      future: student.getMistakeCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        
        final theme = CozyTheme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review $count Mistakes', style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: theme.accent)),
                      Text('Strengthen your weak areas now.', style: theme.bodySmall.copyWith(color: theme.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final ids = await student.getIncorrectQuestionIds();
                    if (context.mounted) {
                      context.push('/quiz/review', extra: ids);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadinessSection(BuildContext context, StudentContract student) {
    final readiness = student.readinessScore;
    final theme = CozyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.shadowSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exam Readiness', style: theme.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Based on your last 100 questions and retention data.',
                  style: theme.bodyMedium.copyWith(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: (readiness?.overall ?? 0) / 100,
                  strokeWidth: 10,
                  backgroundColor: theme.background,
                  color: (readiness?.overall ?? 0) > 70 ? theme.primary : theme.accent,
                ),
              ),
              Text(
                '${readiness?.overall ?? 0}%',
                style: theme.headingLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartReviewSection(BuildContext context, StudentContract student) {
    final reviews = student.smartReview;
    final theme = CozyTheme.of(context);

    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Recommendations', style: theme.headingLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = reviews[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.paperWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: theme.shadowSmall,
                  border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.topic, style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1),
                    const SizedBox(height: 8),
                    Text('${(item.retention * 100).toInt()}% retention', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/quiz/${item.slug}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.background,
                          foregroundColor: theme.primary,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Review Now'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasterySection(BuildContext context, StudentContract student) {
    final mastery = student.subjectMastery;
    final theme = CozyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject Mastery', style: theme.headingLarge),
        const SizedBox(height: 16),
        if (mastery.isEmpty)
           const Center(child: Padding(
             padding: EdgeInsets.all(32.0),
             child: CircularProgressIndicator(),
           ))
        else
          ...mastery.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildMasteryBar(context, item),
          )),
      ],
    );
  }

  Widget _buildMasteryBar(BuildContext context, SubjectMastery item) {
    final theme = CozyTheme.of(context);
    final percentage = item.masteryPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(item.subjectEn, style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text('$percentage% mastery', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/quiz/${item.subjectEn.toLowerCase()}'),
              icon: Icon(Icons.play_circle_outline, color: theme.primary),
              tooltip: 'Practice ${item.subjectEn}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: item.masteryPercent / 100.0,
            minHeight: 12,
            backgroundColor: theme.background,
            color: theme.primary, // Use theme primary instead of missing color field
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, StudentContract student) {
    final activity = student.activityData;
    final theme = CozyTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Pulse', style: theme.headingLarge),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: activity.isEmpty 
              ? const Center(child: Text('No activity recorded this week.'))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: activity.map((day) => _buildActivityBar(context, day)).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(BuildContext context, ActivityData day) {
    final theme = CozyTheme.of(context);
    final height = (day.count * 10).clamp(10, 100).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 8),
        Text(day.dayLabel?.substring(0, 1) ?? '?', style: TextStyle(fontSize: 12, color: theme.textSecondary)),
      ],
    );
  }
}
