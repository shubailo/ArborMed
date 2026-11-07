import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../matching_pair_controller_group.dart';

class MatchingEditor extends StatelessWidget {
  final List<MatchingPairControllerGroup> matchingGroups;
  final bool isEn;
  final VoidCallback onAddPair;
  final void Function(int index) onRemovePair;

  const MatchingEditor({
    super.key,
    required this.matchingGroups,
    required this.isEn,
    required this.onAddPair,
    required this.onRemovePair,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.adminMatchingPairs,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...matchingGroups.asMap().entries.map((entry) {
          final idx = entry.key;
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: isEn ? group.leftEn : group.leftHu,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      AppLocalizations.of(context)!.adminLeftLabel(idx + 1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.link, color: CozyTheme.of(context).primary),
                ),
                Expanded(
                  child: TextField(
                    controller: isEn ? group.rightEn : group.rightHu,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      AppLocalizations.of(context)!.adminRightLabel(idx + 1),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: CozyTheme.of(context).error),
                  onPressed: () => onRemovePair(idx),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAddPair,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.adminAddPair),
        ),
      ],
    );
  }
}

