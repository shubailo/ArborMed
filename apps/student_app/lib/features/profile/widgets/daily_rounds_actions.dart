import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../providers/rank_provider.dart';

class DailyRoundsActions extends StatelessWidget {
  const DailyRoundsActions({super.key, this.onPractice});
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    final rank = context.watch<RankProvider>();
    final strings = AppLocalizations.of(context)!;
    final progress = rank.roundsProgress;
    final goal = rank.roundsGoal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (rank.hasDoneRoundsToday)
        Text(strings.roundsConfirmed)
      else ...[
        Text(strings.roundsRequirement(goal)),
        if (progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress / goal),
          Text(strings.roundsProgressCount(progress, goal)),
        ],
        if (onPractice != null)
          FilledButton.icon(
              onPressed: onPractice,
              icon: const Icon(Icons.school_outlined),
              label: Text(strings.roundsPractice)),
        if (progress == null || progress >= goal)
          OutlinedButton(
              onPressed: rank.isSyncing ? null : rank.syncCompletedRounds,
              child: Text(strings.roundsConfirm)),
      ],
      if (!rank.statusFailed &&
          !rank.hasDoneRoundsToday &&
          progress != null &&
          progress < goal)
        TextButton(
            onPressed: rank.fetchStatus, child: Text(strings.roundsRefresh)),
      if (rank.statusFailed)
        TextButton.icon(
            onPressed: rank.fetchStatus,
            icon: const Icon(Icons.refresh),
            label: Text(strings.roundsRetry)),
    ]);
  }
}
