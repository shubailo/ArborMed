import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../widgets/cozy/cozy_dialog_sheet.dart';
import '../../analytics/providers/stats_provider.dart';
import '../../profile/providers/rank_provider.dart';
import '../../profile/widgets/daily_rounds_actions.dart';

class MissionControlView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onStartRounds;
  const MissionControlView(
      {super.key, required this.onBack, this.onStartRounds});

  @override
  Widget build(BuildContext context) {
    final rank = context.watch<RankProvider>();
    final stats = context.watch<StatsProvider>();
    final strings = AppLocalizations.of(context)!;
    final hu = Localizations.localeOf(context).languageCode == 'hu';
    final heading = Theme.of(context).textTheme.titleLarge;
    final attempts =
        stats.subjectMastery.fold(0, (sum, item) => sum + item.totalAnswered);
    final correct =
        stats.subjectMastery.fold(0, (sum, item) => sum + item.correctAnswered);
    return CozyDialogSheet(
      onTapOutside: onBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(hu ? rank.currentRank.labelHu : rank.currentRank.label,
              style: heading),
          Text('${strings.xp}: ${rank.xp}'),
          Text(strings.roundsStrikes(rank.malpracticeStrikes)),
          const Divider(height: 32),
          Text(strings.roundsTitle, style: heading),
          DailyRoundsActions(onPractice: onStartRounds),
          const Divider(height: 32),
          if (stats.summaryFailed)
            TextButton(
                onPressed: stats.fetchSummary,
                child: Text(strings.roundsSummaryRetry))
          else if (stats.isLoading)
            const LinearProgressIndicator()
          else if (attempts > 0)
            Text(strings.roundsSubjectStats(
                attempts, (100 * correct / attempts).round()))
          else
            Text(strings.roundsNoResponses),
          const SizedBox(height: 12),
          TextButton(onPressed: onBack, child: Text(strings.close)),
        ]),
      ),
    );
  }
}
