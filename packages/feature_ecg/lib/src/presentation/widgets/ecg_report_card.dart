import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class ECGReportCard extends StatelessWidget {
  final ECGResult result;
  final ECGCase ecgCase;
  final List<ECGDiagnosis> allDiagnoses;

  const ECGReportCard({
    super.key,
    required this.result,
    required this.ecgCase,
    required this.allDiagnoses,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    
    // Get diagnosis names
    final selectedDiag = allDiagnoses.firstWhere(
      (d) => d.id == result.diagnosisId,
      orElse: () => const ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: 'Ismeretlen'),
    );
    
    final correctDiag = allDiagnoses.firstWhere(
      (d) => d.id == ecgCase.diagnosisId,
      orElse: () => const ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: 'Ismeretlen'),
    );

    final isDiagCorrect = result.diagnosisId == ecgCase.diagnosisId;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Icon(
            isDiagCorrect ? Icons.check_circle : Icons.error,
            color: isDiagCorrect ? Colors.green : Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isDiagCorrect ? 'CORRECT DIAGNOSIS' : 'INCORRECT DIAGNOSIS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDiagCorrect ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 32),

          // Comparison Table
          _buildComparisonRow(palette, 'Your Diagnosis', selectedDiag.nameEn, isDiagCorrect),
          _buildComparisonRow(palette, 'Correct Diagnosis', correctDiag.nameEn, true),
          
          const Divider(height: 32),

          // Findings Comparison (Simplified v1)
          _buildFindingsSummary(palette),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('BACK TO MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(CozyPalette palette, String label, String value, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? palette.textPrimary : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsSummary(CozyPalette palette) {
    // In v2, this would list all parameters (Rate, Rhythm, etc.) with Correct/Incorrect icons
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Feedback',
          style: TextStyle(fontWeight: FontWeight.bold, color: palette.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          ecgCase.findings['management']?['notes'] ?? 'Always clinical correlate ECG findings with patient presentation.',
          style: TextStyle(color: palette.textSecondary, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}
