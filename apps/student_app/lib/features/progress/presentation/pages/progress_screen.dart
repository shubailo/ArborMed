import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/progress_providers.dart';
import '../../domain/entities/progress.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Progress',
          style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF93))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load progress'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(courseProgressProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (progress) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Track your mastery across topics and Bloom levels.',
              style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (progress.topics.isEmpty)
               const Center(child: Text('Start studying to see your progress ladder fill up.'))
            else
               ...progress.topics.map((topic) => TopicProgressCard(topic: topic)),
          ],
        ),
      ),
    );
  }
}

class TopicProgressCard extends StatelessWidget {
  final TopicProgress topic;

  const TopicProgressCard({super.key, required this.topic});

  String _getBadgeText(String badge) {
    switch (badge) {
      case 'FOUNDATION': return 'Foundations in place';
      case 'APPLICATION': return 'You can apply this topic';
      case 'ADVANCED': return 'You analyze and evaluate confidently';
      case 'EXPERT': return 'You have mastered even the highest levels';
      default: return 'No badge yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1EFE7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topic.topicName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${topic.overallMastery}% Mastery',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getBadgeText(topic.masteryBadge),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4CAF93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          BloomLadderWidget(bloomLevels: topic.bloomLevels),
        ],
      ),
    );
  }
}

class BloomLadderWidget extends StatelessWidget {
  final List<BloomLevelState> bloomLevels;

  const BloomLadderWidget({super.key, required this.bloomLevels});

  static const List<String> _levelNames = [
    'Remember', 'Understand', 'Apply', 'Analyze', 'Evaluate', 'Create'
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final state = bloomLevels.length > index ? bloomLevels[index] : null;
        final achieved = state?.achieved ?? false;
        
        return Expanded(
          child: Tooltip(
            message: _levelNames[index],
            child: Column(
              children: [
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: achieved ? const Color(0xFF4CAF93) : const Color(0xFFF1EFE7),
                    borderRadius: BorderRadius.circular(12),
                    border: achieved 
                      ? null 
                      : Border.all(color: const Color(0xFFCEC5BD), width: 1),
                    boxShadow: achieved 
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4CAF93).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ] 
                      : null,
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForLevel(index + 1),
                      color: achieved ? Colors.white : const Color(0xFFCEC5BD),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: achieved ? const Color(0xFF4CAF93) : const Color(0xFFCEC5BD),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  IconData _getIconForLevel(int level) {
    switch (level) {
      case 1: return Icons.visibility_outlined;
      case 2: return Icons.lightbulb_outline;
      case 3: return Icons.play_arrow_outlined;
      case 4: return Icons.analytics_outlined;
      case 5: return Icons.gavel_outlined;
      case 6: return Icons.create_outlined;
      default: return Icons.help_outline;
    }
  }
}
