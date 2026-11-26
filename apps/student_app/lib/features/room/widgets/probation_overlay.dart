import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../profile/providers/rank_provider.dart';
import '../../profile/widgets/daily_rounds_actions.dart';

class ProbationOverlay extends StatelessWidget {
  final VoidCallback onStartRounds;
  const ProbationOverlay({super.key, required this.onStartRounds});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final strikes =
        context.select((RankProvider rank) => rank.malpracticeStrikes);
    return Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
            child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.gavel_rounded,
                    size: 42, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(strings.roundsProbation,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(strings.roundsStrikes(strikes)),
                const SizedBox(height: 16),
                DailyRoundsActions(onPractice: onStartRounds),
              ]),
            ),
          ),
        )));
  }
}
