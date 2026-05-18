import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analytics/providers/stats_provider.dart';
import '../../../theme/cozy_theme.dart';

class ECGReportCard extends StatelessWidget {
  final Map<String, dynamic>? feedbackReport;
  final ECGCase? currentCase;
  final Set<String> interactedSections;
  final VoidCallback onNextCase;

  const ECGReportCard({
    super.key,
    required this.feedbackReport,
    required this.currentCase,
    required this.interactedSections,
    required this.onNextCase,
  });

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    if (currentCase == null) return const SizedBox.shrink();

    final feedback = feedbackReport ?? {};
    final isCorrect = feedback['isCorrect'] == true;
    final score = int.tryParse(feedback['score']?.toString() ?? '1') ?? 1;
    final time = int.tryParse(feedback['time']?.toString() ?? '0') ?? 0;
    final correctDxId =
        int.tryParse(feedback['correctDiagnosisId']?.toString() ?? '0') ?? 0;
    final primaryCorrect = feedback['primary_dx_correct'] == true;
    final Map<String, dynamic> detailed = _ensureMap(feedback['detailed']);

    final stats = Provider.of<StatsProvider>(context, listen: false);
    // ⚡ Bolt: Pre-compute diagnoses into a Hash Map for O(1) lookups during build.
    // This eliminates O(N*M) stuttering when finding secondary diagnoses inside the Wrap.
    final diagnosesMap = {for (var d in stats.ecgDiagnoses) d.id: d};

    final diagnosis = diagnosesMap[correctDxId] ??
        ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: '');

    final palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Case Review",
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Score Header
          Center(
            child: Column(
              children: [
                Icon(
                  isCorrect ? Icons.emoji_events : Icons.assignment_late,
                  size: 80,
                  color: isCorrect ? palette.warning : palette.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  isCorrect ? "Excellent Interpretation!" : "Keep Learning",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Time spent: ${time}s",
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      color: i < score
                          ? palette.warning
                          : palette.textSecondary.withValues(alpha: 0.2),
                      size: 32,
                    ),
                  ),
                ),
                if (interactedSections.length < 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Score capped: Interpretation steps skipped.",
                      style: TextStyle(
                        color: palette.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Main Diagnosis Result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryCorrect
                  ? palette.success.withValues(alpha: 0.1)
                  : palette.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryCorrect
                    ? palette.success.withValues(alpha: 0.3)
                    : palette.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  primaryCorrect
                      ? "Correct Primary Diagnosis"
                      : "Incorrect Primary Diagnosis",
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryCorrect ? palette.success : palette.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${diagnosis.code} - ${diagnosis.nameEn}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!primaryCorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "You suggested a different diagnosis.",
                      style: TextStyle(color: palette.error, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Detailed Comparison Table
          Text(
            "Step-by-Step Analysis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: palette.textSecondary.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Interpretation Step",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Your Input",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Expert Findings",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Comparison Rows
                ...detailed.entries.map((e) {
                  final data = e.value;
                  if (data is! Map) return const SizedBox.shrink();

                  final isMatch = data['isCorrect'] == true;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                data['title']?.toString() ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                data['user']?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isMatch
                                      ? palette.success
                                      : palette.error,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                data['standard']?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Secondary Diagnoses Comparison
          if (currentCase!.secondaryDiagnosesIds.isNotEmpty) ...[
            Text(
              "Secondary Findings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gold Standard Secondary Diagnoses:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: currentCase!.secondaryDiagnosesIds.map((id) {
                      final d = diagnosesMap[id] ??
                          ECGDiagnosis(
                            id: id,
                            code: '?',
                            nameEn: 'Unknown',
                            nameHu: '',
                          );
                      return Chip(
                        label: Text(d.code),
                        backgroundColor: palette.paperWhite,
                        side: BorderSide(
                          color: palette.textSecondary.withValues(alpha: 0.1),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Management (If correct)
          if (isCorrect &&
              currentCase?.findings != null &&
              currentCase!.findings['management'] != null) ...[
            Builder(
              builder: (context) {
                final management = currentCase!.findings['management'];
                if (management is! Map) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Clinical Management",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: palette.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Urgency: ${management['urgency'] ?? 'Routine'}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            management['notes']?.toString() ??
                                "No management notes provided.",
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ],

          ElevatedButton(
            onPressed: onNextCase,
            style: ElevatedButton.styleFrom(
              backgroundColor: CozyTheme.of(context).primary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "CLOSE & START NEXT CASE",
              style: TextStyle(
                color: palette.textInverse,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
