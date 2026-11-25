import 'package:flutter/material.dart';
import 'quiz_session_screen.dart';

class QuizScreen extends StatelessWidget {
  final String topicSlug;
  final String topicName;
  const QuizScreen({super.key, required this.topicSlug, required this.topicName});

  @override
  Widget build(BuildContext context) =>
      QuizSessionScreen(systemSlug: topicSlug, systemName: topicName);
}
