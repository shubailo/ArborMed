import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

String adminTimestamp(BuildContext context, DateTime? timestamp) {
  if (timestamp == null) return AppLocalizations.of(context)!.adminNoRecordedActivity;
  final local = timestamp.toLocal();
  final labels = MaterialLocalizations.of(context);
  final time = labels.formatTimeOfDay(TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
  return '${labels.formatCompactDate(local)} $time';
}
