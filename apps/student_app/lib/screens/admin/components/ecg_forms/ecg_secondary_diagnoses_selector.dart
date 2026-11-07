import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../services/admin_question_provider.dart';
import 'package:arbor_med/features/analytics/models/ecg_diagnosis.dart';
import '../../../../generated/l10n/app_localizations.dart';

class EcgSecondaryDiagnosesSelector extends StatelessWidget {
  final List<int> secondaryDiagnosesIds;
  final int? selectedDiagnosisId;
  final ValueChanged<int> onAddDiagnosis;
  final ValueChanged<int> onRemoveDiagnosis;

  const EcgSecondaryDiagnosesSelector({
    super.key,
    required this.secondaryDiagnosesIds,
    required this.selectedDiagnosisId,
    required this.onAddDiagnosis,
    required this.onRemoveDiagnosis,
  });

  void _showDiagnosisSelector(BuildContext context, AdminQuestionProvider stats) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.adminEcgAddSecondaryDiagnosis,
                style: CozyTheme.of(context).dialogTitle,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: stats.ecgDiagnoses
                      .where((d) =>
                          d.id != selectedDiagnosisId &&
                          !secondaryDiagnosesIds.contains(d.id))
                      .map((d) {
                    return ListTile(
                      dense: true,
                      trailing: Icon(Icons.add, color: CozyTheme.of(context).primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        "${d.code} - ${d.nameEn}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        d.nameHu.isNotEmpty ? d.nameHu : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        onAddDiagnosis(d.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminQuestionProvider>(builder: (ctx, stats, _) {
      return InkWell(
        onTap: () => _showDiagnosisSelector(context, stats),
        child: InputDecorator(
          decoration: CozyTheme.inputDecoration(
            context,
            AppLocalizations.of(context)!.adminEcgSecondaryDiagnoses,
          ).copyWith(
            prefixIcon: const Icon(Icons.playlist_add_check, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: secondaryDiagnosesIds.isEmpty
              ? Text(
                  AppLocalizations.of(context)!.adminEcgNoneTapToAdd,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: secondaryDiagnosesIds.map((id) {
                    final d = stats.ecgDiagnoses.firstWhere(
                      (e) => e.id == id,
                      orElse: () => ECGDiagnosis(
                        id: id,
                        code: '?',
                        nameEn: 'Unknown',
                        nameHu: '',
                      ),
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CozyTheme.of(context).primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            d.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CozyTheme.of(context).primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => onRemoveDiagnosis(id),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: CozyTheme.of(context).primary,
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      );
    });
  }
}

