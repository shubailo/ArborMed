import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';

class TrueFalseEditor extends StatelessWidget {
  final int? correctIndex;
  final ValueChanged<int> onIndexChanged;

  const TrueFalseEditor({
    super.key,
    required this.correctIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text(AppLocalizations.of(context)!.adminTrue),
          labelStyle: TextStyle(
              color: correctIndex == 0
                  ? CozyTheme.of(context).textInverse
                  : CozyTheme.of(context).primary,
              fontWeight: FontWeight.bold),
          selected: correctIndex == 0,
          selectedColor: CozyTheme.of(context).primary,
          backgroundColor: CozyTheme.of(context).paperWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: CozyTheme.of(context).primary)),
          onSelected: (val) => onIndexChanged(0),
        ),
        const SizedBox(width: 24),
        ChoiceChip(
          label: Text(AppLocalizations.of(context)!.adminFalse),
          labelStyle: TextStyle(
              color: correctIndex == 1
                  ? CozyTheme.of(context).textInverse
                  : CozyTheme.of(context).accent,
              fontWeight: FontWeight.bold),
          selected: correctIndex == 1,
          selectedColor: CozyTheme.of(context).accent,
          backgroundColor: CozyTheme.of(context).paperWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: CozyTheme.of(context).accent)),
          onSelected: (val) => onIndexChanged(1),
        ),
      ],
    );
  }
}
