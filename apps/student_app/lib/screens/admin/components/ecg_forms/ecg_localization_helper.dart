import 'package:flutter/material.dart';
import '../../../../generated/l10n/app_localizations.dart';

class EcgLocalizationHelper {
  static String getLocalizedOption(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value.toLowerCase()) {
      case 'regular':
        return l10n.adminEcgRegular;
      case 'irregular':
        return l10n.adminEcgIrregular;
      case 'irregularly irregular':
        return l10n.adminEcgIrregularlyIrregular;
      case 'normal':
        return l10n.adminEcgNormal;
      case 'prolonged':
        return l10n.adminEcgProlonged;
      case 'short':
        return l10n.adminEcgShort;
      case 'none':
        return l10n.adminEcgNone;
      case 'beginner':
        return l10n.adminEcgDifficultyBeginner;
      case 'intermediate':
        return l10n.adminEcgDifficultyIntermediate;
      case 'advanced':
        return l10n.adminEcgDifficultyAdvanced;
      // Conduction Ratio
      case '1:1':
        return '1:1';
      case '2:1':
        return '2:1';
      case '3:1':
        return '3:1';
      case 'variable':
        return "${l10n.adminEcgRatio} (Var)";
      case 'dissociated':
        return 'AV-disszociáció';
      // Blocks
      case '1st degree':
        return 'I. fokú';
      case '2nd degree type i':
        return 'II. fokú Mobitz I (Wenckebach)';
      case '2nd degree type ii':
        return 'II. fokú Mobitz II';
      case '3rd degree':
        return 'III. fokú (teljes)';
      // Axes
      case 'left deviation':
        return 'Bal deviancia';
      case 'right deviation':
        return 'Jobb deviancia';
      case 'extreme left deviation':
        return 'Extrém bal dev.';
      case 'extreme right deviation':
        return 'Extrém jobb dev.';
      // Urgency
      case 'routine':
        return 'Rutin';
      case 'urgent':
        return 'Sürgős';
      case 'emergent':
        return 'Életveszélyes';
      default:
        return value;
    }
  }
}

