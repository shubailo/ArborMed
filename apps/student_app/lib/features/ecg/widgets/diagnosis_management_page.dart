import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analytics/providers/stats_provider.dart';
import '../../../theme/cozy_theme.dart';
import '../providers/ecg_wizard_state.dart';

class DiagnosisManagementPage extends StatelessWidget {
  final ECGCase ecgCase;
  final int? selectedDiagnosisId;
  final List<int> selectedSecondaryDiagnoses;
  final String urgency;
  final TextEditingController managementNotesController;
  final bool triedSubmit;

  final ValueChanged<int> onDiagnosisSelected;
  final ValueChanged<int> onSecondaryDiagnosisAdded;
  final ValueChanged<int> onSecondaryDiagnosisRemoved;
  final ValueChanged<String> onUrgencyChanged;

  const DiagnosisManagementPage({
    super.key,
    required this.ecgCase,
    required this.selectedDiagnosisId,
    required this.selectedSecondaryDiagnoses,
    required this.urgency,
    required this.managementNotesController,
    required this.triedSubmit,
    required this.onDiagnosisSelected,
    required this.onSecondaryDiagnosisAdded,
    required this.onSecondaryDiagnosisRemoved,
    required this.onUrgencyChanged,
  });

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final palette = CozyTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: palette.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Expanded(
          child: Divider(
            indent: 12,
            height: 24,
            color: palette.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  String _translateDropdownOption(String label, String value, bool isHu) {
    if (!isHu) return value;
    switch (value) {
      case 'Routine':
        return 'Rutin';
      case 'Urgent':
        return 'Sürgős';
      case 'Emergency':
        return 'Azonnali / Életveszélyes';
      default:
        return value;
    }
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    return InputDecorator(
      decoration: CozyTheme.inputDecoration(context, label).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(
            isHu ? "$label kiválasztása..." : "Select $label...",
            style: TextStyle(
              fontSize: 14,
              color: CozyTheme.of(context).textSecondary,
            ),
          ),
          items: items
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    _translateDropdownOption(label, r, isHu),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(
          context,
          isHu ? "Végső diagnózis" : "Final Diagnosis",
          Icons.check_circle_outline,
        ),
        const SizedBox(height: 16),
        _buildDiagnosisSearch(context),
        if (ecgCase.secondaryDiagnosesIds.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSecondaryDiagnosisSearch(context),
        ],
        const SizedBox(height: 32),

        if (ecgCase.findings['management'] != null) ...[
          _buildSectionHeader(
            context,
            isHu ? "8. Kezelés és teendők" : "8. Management",
            Icons.medical_services,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            context,
            isHu ? "Sürgősségi szint" : "Urgency Level",
            urgency,
            ECGWizardState.urgencyOpts,
            (v) => onUrgencyChanged(v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: managementNotesController,
            maxLines: 3,
            decoration: CozyTheme.inputDecoration(
              context,
              isHu ? "Klinikai teendők / megjegyzések" : "Management Notes",
            ).copyWith(
              hintText: isHu
                  ? "Következő lépések, teendők leírása..."
                  : "Describe next steps / management...",
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: palette.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHu
                      ? "Beküldés előtt kérjük, ellenőrizze az értelmezést."
                      : "Double check your interpretation before submitting.",
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisSearch(BuildContext context) {
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        return Autocomplete<ECGDiagnosis>(
          displayStringForOption: (d) =>
              "${d.code} - ${isHu && d.nameHu.isNotEmpty ? d.nameHu : d.nameEn}",
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<ECGDiagnosis>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return stats.ecgDiagnoses.where(
              (d) =>
                  d.nameEn.toLowerCase().contains(query) ||
                  d.nameHu.toLowerCase().contains(query) ||
                  d.code.toLowerCase().contains(query),
            );
          },
          onSelected: (ECGDiagnosis selection) {
            onDiagnosisSelected(selection.id);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: CozyTheme.inputDecoration(
                context,
                isHu ? "Elsődleges diagnózis" : "Primary Diagnosis",
              ).copyWith(
                prefixIcon: Icon(
                  Icons.search,
                  color: CozyTheme.of(context).textSecondary,
                ),
                fillColor: CozyTheme.of(context).primary.withValues(alpha: 0.05),
                filled: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSecondaryDiagnosisSearch(BuildContext context) {
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHu ? "Másodlagos diagnózisok" : "Secondary Diagnoses",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CozyTheme.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Autocomplete<ECGDiagnosis>(
              displayStringForOption: (d) =>
                  "${d.code} - ${isHu && d.nameHu.isNotEmpty ? d.nameHu : d.nameEn}",
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<ECGDiagnosis>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return stats.ecgDiagnoses.where(
                  (d) =>
                      d.id != selectedDiagnosisId &&
                      !selectedSecondaryDiagnoses.contains(d.id) &&
                      (d.nameEn.toLowerCase().contains(query) ||
                          d.nameHu.toLowerCase().contains(query) ||
                          d.code.toLowerCase().contains(query)),
                );
              },
              onSelected: (ECGDiagnosis selection) {
                onSecondaryDiagnosisAdded(selection.id);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: CozyTheme.inputDecoration(
                    context,
                    isHu ? "Másodlagos diagnózis hozzáadása" : "Add Secondary Diagnosis",
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.add_circle_outline,
                      color: CozyTheme.of(context).textSecondary,
                    ),
                  ),
                );
              },
            ),
            if (selectedSecondaryDiagnoses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedSecondaryDiagnoses.map((id) {
                  final d = stats.ecgDiagnoses.firstWhere(
                    (e) => e.id == id,
                    orElse: () => ECGDiagnosis(
                      id: id,
                      code: '?',
                      nameEn: 'Unknown',
                      nameHu: '',
                    ),
                  );
                  return Chip(
                    label: Text(
                      isHu && d.nameHu.isNotEmpty ? "${d.code} (${d.nameHu})" : d.code,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onSecondaryDiagnosisRemoved(id),
                    backgroundColor: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: CozyTheme.of(context).primary.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}
