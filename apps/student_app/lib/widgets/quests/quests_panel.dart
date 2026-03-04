import 'package:flutter/material.dart';
import 'quest_list.dart';
import '../../theme/cozy_theme.dart';

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
              color: Colors.black.withValues(alpha: 0.1),
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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),

            // Quest List
            const Expanded(child: QuestList()),
          ],
        ),
      ),
    );
  }
}
