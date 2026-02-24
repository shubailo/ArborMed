import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quest_provider.dart';
import '../../models/quest.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_button.dart';

class QuestsPanel extends StatelessWidget {
  const QuestsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CozyTheme.of(context).primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, size: 28),
                const SizedBox(width: 12),
                Text(
                  "Daily Quests",
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CozyTheme.of(context).textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),

            // Quest List
            Expanded(
              child: Consumer<QuestProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.quests.isEmpty) {
                    return Center(
                      child: Text(
                        "No quests available right now.\nCheck back later!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: CozyTheme.of(context).textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: provider.quests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final quest = provider.quests[index];
                      return _QuestCard(quest: quest);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final LearningQuest quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final isCompleted = quest.status == QuestStatus.completed;
    final isClaimed = quest.status == QuestStatus.claimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClaimed ? theme.background : theme.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted && !isClaimed
              ? theme.accent
              : theme.textSecondary.withOpacity(0.2),
          width: isCompleted && !isClaimed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isClaimed ? theme.textSecondary : theme.textPrimary,
                        decoration: isClaimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.description,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                CozyButton(
                  label: "Claim",
                  icon: Icons.check,
                  variant: CozyButtonVariant.primary,
                  isSmall: true,
                  onPressed: () async {
                    final reward = await context.read<QuestProvider>().claimQuest(quest.id);
                    if (context.mounted && reward > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You earned $reward tokens! 🩺"),
                          backgroundColor: theme.primary,
                        ),
                      );
                    }
                  },
                )
              else if (isClaimed)
                Icon(Icons.check_circle, color: theme.success)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${quest.rewardTokens}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text("🩺", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          if (!isClaimed) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: quest.progress,
                backgroundColor: theme.background,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${quest.currentCount} / ${quest.targetCount}",
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
