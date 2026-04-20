import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';

class RelationAnalysisEditor extends StatelessWidget {
  final int? correctIndex;
  final ValueChanged<int> onIndexChanged;

  const RelationAnalysisEditor({
    super.key,
    required this.correctIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool s1 = false;
    bool s2 = false;
    bool link = false;
    int idx = correctIndex ?? 0;
    
    if ([0, 1, 2].contains(idx)) s1 = true;
    if ([0, 1, 3].contains(idx)) s2 = true;
    if (idx == 0) link = true;

    int calculateIndex(bool s1, bool s2, bool link) {
      if (s1 && s2) return link ? 0 : 1;
      if (s1 && !s2) return 2;
      if (!s1 && s2) return 3;
      return 4;
    }

    return Column(
      children: [
        Text(AppLocalizations.of(context)!.adminSetCorrectLogic,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildRAOption(context, !s1, s1, AppLocalizations.of(context)!.adminStatement1True,
            (val) => onIndexChanged(calculateIndex(val, s2, link))),
        const SizedBox(height: 12),
        _buildRAOption(context, !s2, s2, AppLocalizations.of(context)!.adminStatement2True,
            (val) => onIndexChanged(calculateIndex(s1, val, link))),
        const SizedBox(height: 12),
        Opacity(
          opacity: (s1 && s2) ? 1.0 : 0.5,
          child: _buildRAOption(
              context, !link, link, AppLocalizations.of(context)!.adminConnectionExists, (val) {
            if (s1 && s2) onIndexChanged(calculateIndex(s1, s2, val));
          }, isLink: true),
        ),
      ],
    );
  }

  Widget _buildRAOption(
      BuildContext context, bool toggle, bool active, String label, Function(bool) onChanged,
      {bool isLink = false}) {
    return InkWell(
      onTap: () => onChanged(!active),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: active
                  ? CozyTheme.of(context).primary
                  : CozyTheme.of(context).textSecondary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: active
              ? CozyTheme.of(context).primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(children: [
          Icon(
              isLink
                  ? (active ? Icons.link : Icons.link_off)
                  : (active ? Icons.check_box : Icons.check_box_outline_blank),
              color: active
                  ? (isLink
                      ? CozyTheme.of(context).secondary
                      : CozyTheme.of(context).primary)
                  : CozyTheme.of(context).textSecondary),
          const SizedBox(width: 12),
          Text(label),
        ]),
      ),
    );
  }
}
