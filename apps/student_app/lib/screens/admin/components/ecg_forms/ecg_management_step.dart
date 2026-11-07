import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../features/ecg/providers/ecg_wizard_state.dart';
import 'ecg_form_dropdown.dart';

class EcgManagementStep extends StatelessWidget {
  final bool includeManagement;
  final String urgency;
  final TextEditingController managementNotesController;
  final ValueChanged<bool> onIncludeManagementChanged;
  final ValueChanged<String> onUrgencyChanged;

  const EcgManagementStep({
    super.key,
    required this.includeManagement,
    required this.urgency,
    required this.managementNotesController,
    required this.onIncludeManagementChanged,
    required this.onUrgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: includeManagement
            ? Colors.orange.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: includeManagement
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.adminEcgIncludeManagement),
            subtitle: Text(l10n.adminEcgIntermediateAdvancedOnly),
            value: includeManagement,
            onChanged: onIncludeManagementChanged,
            activeThumbColor: Colors.orange,
          ),
          if (includeManagement) ...[
            const SizedBox(height: 16),
            EcgFormDropdown(
              keyName: "management.urgency",
              label: l10n.adminEcgUrgencyLevel,
              value: urgency,
              items: ECGWizardState.urgencyOpts,
              icon: Icons.notification_important,
              onChanged: onUrgencyChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: managementNotesController,
              maxLines: 3,
              decoration: CozyTheme.inputDecoration(
                context,
                l10n.adminEcgNotesNextSteps,
              ).copyWith(
                prefixIcon: const Icon(Icons.note_add, color: Colors.grey),
                helperText: l10n.adminEcgManagementHint,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

