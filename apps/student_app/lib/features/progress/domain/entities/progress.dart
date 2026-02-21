import 'package:equatable/equatable.dart';

class BloomLevelState extends Equatable {
  final int bloomLevel;
  final int masteryScore;
  final bool achieved;

  const BloomLevelState({
    required this.bloomLevel,
    required this.masteryScore,
    required this.achieved,
  });

  @override
  List<Object?> get props => [bloomLevel, masteryScore, achieved];
}

class TopicProgress extends Equatable {
  final String topicId;
  final String topicName;
  final int overallMastery;
  final List<BloomLevelState> bloomLevels;
  final String masteryBadge;

  const TopicProgress({
    required this.topicId,
    required this.topicName,
    required this.overallMastery,
    required this.bloomLevels,
    required this.masteryBadge,
  });

  @override
  List<Object?> get props => [topicId, topicName, overallMastery, bloomLevels, masteryBadge];
}

class CourseProgress extends Equatable {
  final String courseId;
  final String userId;
  final List<TopicProgress> topics;

  const CourseProgress({
    required this.courseId,
    required this.userId,
    required this.topics,
  });

  @override
  List<Object?> get props => [courseId, userId, topics];
}
