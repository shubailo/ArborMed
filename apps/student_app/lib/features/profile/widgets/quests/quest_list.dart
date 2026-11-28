import 'dart:async';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arbor_med/features/profile/providers/quest_provider.dart';
import 'package:arbor_med/features/profile/models/quest.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';

class QuestList extends StatelessWidget {
  const QuestList({super.key});

  @override
  Widget build(BuildContext context) {
    final session =
        context.select<QuestProvider, int>((p) => p.sessionRevision);
    return _DailyList(key: ValueKey(session));
  }
}

class _DailyList extends StatefulWidget {
  const _DailyList({super.key});
  @override
  State<_DailyList> createState() => _DailyListState();
}

class _DailyListState extends State<_DailyList> with WidgetsBindingObserver {
  Timer? _midnight;
  DateTime? _nextDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _refresh() {
    _midnight?.cancel();
    final now = DateTime.now().toUtc();
    _nextDay = DateTime.utc(now.year, now.month, now.day + 1);
    _midnight = Timer(_nextDay!.difference(now), _refresh);
    context.read<QuestProvider>().fetchQuests();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _nextDay != null &&
        !DateTime.now().toUtc().isBefore(_nextDay!)) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Consumer<QuestProvider>(
      builder: (context, provider, _) {
        final quests = provider.quests;
        if (provider.isLoading && quests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (quests.isEmpty && !provider.refreshFailed) {
          return Center(child: Text(strings.questEmpty));
        }
        final showError = provider.refreshFailed;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: quests.length + (showError ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (showError && index == 0) {
              return Column(children: [
                Text(strings.questRefreshFailed),
                TextButton(onPressed: _refresh, child: Text(strings.retry))
              ]);
            }
            final quest = quests[index - (showError ? 1 : 0)];
            return _QuestCard(key: ValueKey(quest.id), quest: quest);
          },
        );
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  final LearningQuest quest;

  const _QuestCard({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    final strings = AppLocalizations.of(context)!;
    final claiming = context.select<QuestProvider, bool>((p) => p.isClaiming);
    final hu = Localizations.localeOf(context).languageCode == 'hu';
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
              : theme.textSecondary.withValues(alpha: 0.2),
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
                      hu ? quest.titleHu ?? quest.title : quest.title,
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isClaimed ? theme.textSecondary : theme.textPrimary,
                        decoration:
                            isClaimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hu
                          ? quest.descriptionHu ?? quest.description
                          : quest.description,
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
                  label: strings.questClaim,
                  enabled: !claiming,
                  icon: Icons.check,
                  variant: CozyButtonVariant.primary,
                  isSmall: true,
                  onPressed: () async {
                    if (!context.mounted) return;
                    final provider = context.read<QuestProvider>();
                    if (!provider.quests.any((current) => identical(current, quest))) return;
                    try {
                      final reward = await provider.claimQuest(quest.id);
                      if (context.mounted && reward > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(strings.questAward(reward)),
                            backgroundColor: theme.primary));
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.questClaimFailed)));
                      await provider.fetchQuests();
                    }
                  },
                )
              else if (isClaimed)
                Icon(Icons.check_circle, color: theme.success)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
