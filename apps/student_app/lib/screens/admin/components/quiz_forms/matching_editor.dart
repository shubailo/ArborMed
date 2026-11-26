import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../matching_pair_controller_group.dart';

class MatchingEditor extends StatelessWidget {
  final List<MatchingPairControllerGroup> matchingGroups;
  final bool isEn;
  final VoidCallback onAddPair;
  final ValueChanged<MatchingPairControllerGroup> onRemovePair;
  final VoidCallback onTextChanged;
  final String? conflictingKey;
  final bool repairKey;
  final ValueChanged<bool> onRepairKeyChanged;

  const MatchingEditor({
    super.key,
    required this.matchingGroups,
    required this.isEn,
    required this.onAddPair,
    required this.onRemovePair,
    required this.onTextChanged,
    this.conflictingKey,
    required this.repairKey,
    required this.onRepairKeyChanged,
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
        if (conflictingKey != null)
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.adminMatchingRepairKey),
            subtitle: Text(conflictingKey!),
            value: repairKey,
            onChanged: (value) => onRepairKeyChanged(value == true),
          ),
        const SizedBox(height: 12),
        ...matchingGroups.asMap().entries.map((entry) {
          final idx = entry.key;
          final group = entry.value;
          return Padding(
            key: ObjectKey(group),
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (_) => onTextChanged(),
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
                    onChanged: (_) => onTextChanged(),
                    controller: isEn ? group.rightEn : group.rightHu,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      AppLocalizations.of(context)!.adminRightLabel(idx + 1),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: CozyTheme.of(context).error),
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: () => onRemovePair(group),
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
