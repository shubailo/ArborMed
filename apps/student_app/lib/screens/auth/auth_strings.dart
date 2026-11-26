import 'package:flutter/widgets.dart';
import '../../generated/l10n/app_localizations.dart';

extension AuthStrings on BuildContext {
  AppLocalizations get authStrings =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
