import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class QuizCard extends StatelessWidget {
  final String title;
  final String description;
  final int questionsCount;
  final int durationMinutes;
  final VoidCallback onTap;

  const QuizCard({
    super.key,
    required this.title,
    required this.description,
    required this.questionsCount,
    required this.durationMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArborColors.textPrimary)),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(color: ArborColors.textSecondary)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildChip(Icons.help_outline, '$questionsCount Qs'),
                  const SizedBox(width: 10),
                  _buildChip(Icons.timer_outlined, '$durationMinutes mins'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ArborColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: ArborColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: ArborColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
