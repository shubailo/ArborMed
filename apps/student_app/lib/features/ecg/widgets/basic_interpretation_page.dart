import 'package:flutter/material.dart';
import '../../../theme/cozy_theme.dart';
import '../providers/ecg_wizard_state.dart';

class BasicInterpretationPage extends StatelessWidget {
  final String rhythmRegularity;
  final bool isSinus;
  final String conductionRatio;
  final TextEditingController rateController;
  final String prCategory;
  final String qrsCategory;
  final String qtCategory;
  final String avBlock;
  final String saBlock;
  final bool triedSubmit;

  final ValueChanged<String> onRhythmRegularityChanged;
  final ValueChanged<bool> onIsSinusChanged;
  final ValueChanged<String> onConductionRatioChanged;
  final ValueChanged<String> onPrCategoryChanged;
  final ValueChanged<String> onQrsCategoryChanged;
  final ValueChanged<String> onQtCategoryChanged;
  final ValueChanged<String> onAvBlockChanged;
  final ValueChanged<String> onSaBlockChanged;
  final ValueChanged<String> onInteracted;

  const BasicInterpretationPage({
    super.key,
    required this.rhythmRegularity,
    required this.isSinus,
    required this.conductionRatio,
    required this.rateController,
    required this.prCategory,
    required this.qrsCategory,
    required this.qtCategory,
    required this.avBlock,
    required this.saBlock,
    required this.triedSubmit,
    required this.onRhythmRegularityChanged,
    required this.onIsSinusChanged,
    required this.onConductionRatioChanged,
    required this.onPrCategoryChanged,
    required this.onQrsCategoryChanged,
    required this.onQtCategoryChanged,
    required this.onAvBlockChanged,
    required this.onSaBlockChanged,
    required this.onInteracted,
  });

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
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

  Widget _buildDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    final palette = CozyTheme.of(context);
    bool hasError = triedSubmit && value.isEmpty;

    return InputDecorator(
      decoration: CozyTheme.inputDecoration(context, label).copyWith(
        labelStyle: TextStyle(color: hasError ? palette.error : null),
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.error, width: 2),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(
            "Select $label...",
            style: TextStyle(
              fontSize: 14,
              color: hasError
                  ? palette.error.withValues(alpha: 0.5)
                  : palette.textSecondary,
            ),
          ),
          items: items
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(context, "1. Rhythm", Icons.show_chart),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                "Regularity",
                rhythmRegularity,
                ECGWizardState.regularityOpts,
                (v) {
                  onRhythmRegularityChanged(v);
                  onInteracted("rhythm");
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CheckboxListTile(
                title: const Text(
                  "Sinus Rhythm?",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "P before QRS",
                  style: TextStyle(fontSize: 11, color: palette.textSecondary),
                ),
                value: isSinus,
                onChanged: (v) {
                  if (v != null) {
                    onIsSinusChanged(v);
                    onInteracted("rhythm");
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          context,
          "Conduction (e.g. 1:1)",
          conductionRatio,
          ECGWizardState.conductionOpts,
          (v) {
            onConductionRatioChanged(v);
            onInteracted("rhythm");
          },
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(context, "2. Rate", Icons.timer),
        const SizedBox(height: 16),
        TextFormField(
          controller: rateController,
          keyboardType: TextInputType.number,
          decoration: CozyTheme.inputDecoration(
            context,
            "Heart Rate (BPM)",
          ).copyWith(prefixIcon: const Icon(Icons.favorite_border)),
          onChanged: (_) => onInteracted("rate"),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(context, "3. Conduction", Icons.speed),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(context, "PR Interval", prCategory,
                  ECGWizardState.intervalOpts, (v) {
                onPrCategoryChanged(v);
                onInteracted("conduction");
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(context, "QRS Width", qrsCategory,
                  ECGWizardState.intervalOpts, (v) {
                onQrsCategoryChanged(v);
                onInteracted("conduction");
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown(context, "QT Interval", qtCategory,
                  ECGWizardState.intervalOpts, (v) {
                onQtCategoryChanged(v);
                onInteracted("conduction");
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (prCategory == 'Prolonged') ...[
          _buildDropdown(context, "AV Block", avBlock, ECGWizardState.avBlocks,
              (v) {
            onAvBlockChanged(v);
            onInteracted("conduction");
          }),
          const SizedBox(height: 12),
        ],
        _buildDropdown(context, "SA Block", saBlock, ECGWizardState.saBlocks,
            (v) {
          onSaBlockChanged(v);
          onInteracted("conduction");
        }),
      ],
    );
  }
}
