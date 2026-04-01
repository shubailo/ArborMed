import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class ECGDiagnosisStep extends StatelessWidget {
  final List<ECGDiagnosis> diagnoses;
  final int? selectedDiagnosisId;
  final List<int> secondaryDiagnosisIds;
  final Function(int) onPrimarySelect;
  final Function(int) onSecondaryToggle;

  const ECGDiagnosisStep({
    super.key,
    required this.diagnoses,
    required this.selectedDiagnosisId,
    required this.secondaryDiagnosisIds,
    required this.onPrimarySelect,
    required this.onSecondaryToggle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    // Filter search logic could be added here
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(palette, 'FINAL DIAGNOSIS'),
          const SizedBox(height: 24),

          _buildLabel(palette, 'Primary Diagnosis (Required)'),
          const SizedBox(height: 12),
          _buildDiagnosisList(palette, isPrimary: true),

          const SizedBox(height: 32),

          _buildLabel(palette, 'Secondary Findings (Optional)'),
          const SizedBox(height: 12),
          _buildDiagnosisList(palette, isPrimary: false),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(CozyPalette palette, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(CozyPalette palette, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textSecondary,
      ),
    );
  }

  Widget _buildDiagnosisList(CozyPalette palette, {required bool isPrimary}) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: diagnoses.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: palette.textSecondary.withValues(alpha: 0.05),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final d = diagnoses[index];
          final isSelected = isPrimary 
              ? selectedDiagnosisId == d.id 
              : secondaryDiagnosisIds.contains(d.id);
          
          return ListTile(
            dense: true,
            title: Text(
              d.nameEn,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? palette.primary : palette.textPrimary,
              ),
            ),
            subtitle: Text(d.code, style: const TextStyle(fontSize: 10)),
            trailing: isSelected 
                ? Icon(Icons.check_circle, color: palette.primary, size: 20)
                : null,
            onTap: () => isPrimary ? onPrimarySelect(d.id) : onSecondaryToggle(d.id),
          );
        },
      ),
    );
  }
}
