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

  String _stepTitle(String title, bool isHu) {
    if (!isHu) return title;
    switch (title) {
      case 'Rhythm':
        return 'Ritmus';
      case 'Sinus Rhythm':
        return 'Sinus ritmus';
      case 'Conduction Ratio':
        return 'Átvezetési arány';
      case 'Heart Rate':
        return 'Szívfrekvencia';
      case 'PR Interval':
        return 'PR intervallum';
      case 'QRS Duration':
        return 'QRS idő';
      case 'QT Interval':
        return 'QT intervallum';
      case 'Axis':
        return 'Tengelyállás';
      case 'P Wave Morphology':
        return 'P hullám morfológia';
      case 'Atrial Enlargement':
        return 'Pitvari hipertrófia';
      case 'Ventricular Hypertrophy':
        return 'Kamrai hipertrófia';
      case 'Bundle Branch Block':
        return 'Szárblokk';
      case 'Q Waves':
        return 'Q hullámok';
      case 'ST Elevation / Depression':
        return 'ST eleváció / depresszió';
      case 'T Waves':
        return 'T hullámok';
      default:
        return title;
    }
  }

  String _formatVal(String? val, bool isHu) {
    if (val == null || !isHu) return val ?? 'N/A';
    switch (val.toLowerCase().trim()) {
      case 'yes':
        return 'Igen';
      case 'no':
        return 'Nem';
      case 'normal':
        return 'Normál';
      case 'none':
        return 'Nincs';
      case 'regular':
        return 'Reguláris';
      case 'irregular':
        return 'Irreguláris';
      case 'irregularly irregular':
        return 'Teljesen irreguláris';
      case 'prolonged':
        return 'Megnyúlt';
      case 'short':
        return 'Rövid';
      case 'routine':
        return 'Rutin';
      case 'urgent':
        return 'Sürgős';
      case 'emergency':
        return 'Azonnali / Életveszélyes';
      default:
        return val;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentCase == null) return const SizedBox.shrink();

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final feedback = feedbackReport ?? {};
    final isCorrect = feedback['isCorrect'] == true;
    final score = int.tryParse(feedback['score']?.toString() ?? '1') ?? 1;
    final time = int.tryParse(feedback['time']?.toString() ?? '0') ?? 0;
    final correctDxId =
        int.tryParse(feedback['correctDiagnosisId']?.toString() ?? '0') ?? 0;
    final primaryCorrect = feedback['primary_dx_correct'] == true;
    final Map<String, dynamic> detailed = _ensureMap(feedback['detailed']);

    final stats = Provider.of<StatsProvider>(context, listen: false);
    final diagnosis = stats.ecgDiagnoses.firstWhere(
      (d) => d.id == correctDxId,
      orElse: () =>
          ECGDiagnosis(id: 0, code: '?', nameEn: 'Unknown', nameHu: ''),
    );

    final palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isHu ? "Eset Értékelése" : "Case Review",
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
                  isCorrect
                      ? (isHu ? "Kiváló Elemzés!" : "Excellent Interpretation!")
                      : (isHu ? "Gyakorolj tovább!" : "Keep Learning"),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHu ? "Eltöltött idő: $time mp" : "Time spent: ${time}s",
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
                      isHu
                          ? "Korlátozott pontszám: lépések lettek átugorva."
                          : "Score capped: Interpretation steps skipped.",
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
                      ? (isHu ? "Helyes elsődleges diagnózis" : "Correct Primary Diagnosis")
                      : (isHu ? "Helytelen elsődleges diagnózis" : "Incorrect Primary Diagnosis"),
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryCorrect ? palette.success : palette.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${diagnosis.code} - ${isHu && diagnosis.nameHu.isNotEmpty ? diagnosis.nameHu : diagnosis.nameEn}",
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
                      isHu ? "Más diagnózist javasoltál." : "You suggested a different diagnosis.",
                      style: TextStyle(color: palette.error, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Detailed Comparison Table
          Text(
            isHu ? "Lépésről lépésre elemzés" : "Step-by-Step Analysis",
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
                          isHu ? "Értelmezési lépés" : "Interpretation Step",
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
                          isHu ? "A te válaszod" : "Your Input",
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
                          isHu ? "Szakértői lelet" : "Expert Findings",
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
                  final rawTitle = data['title']?.toString() ?? 'Unknown';
                  final rawUser = data['user']?.toString() ?? 'N/A';
                  final rawStandard = data['standard']?.toString() ?? 'N/A';

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
                                _stepTitle(rawTitle, isHu),
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
                                _formatVal(rawUser, isHu),
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
                                _formatVal(rawStandard, isHu),
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
              isHu ? "Másodlagos leletek" : "Secondary Findings",
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
                  Text(
                    isHu
                        ? "Referencia másodlagos diagnózisok:"
                        : "Gold Standard Secondary Diagnoses:",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: currentCase!.secondaryDiagnosesIds.map((id) {
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
                        ),
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

                final rawUrgency = management['urgency']?.toString() ?? 'Routine';
                final urgencyDisplay = _formatVal(rawUrgency, isHu);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHu ? "Klinikai teendők" : "Clinical Management",
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
                                isHu
                                    ? "Sürgősség: $urgencyDisplay"
                                    : "Urgency: $rawUrgency",
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
                                (isHu
                                    ? "Nincsenek megadva klinikai megjegyzések."
                                    : "No management notes provided."),
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
              isHu ? "BEZÁRÁS ÉS KÖVETKEZŐ ESET" : "CLOSE & START NEXT CASE",
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
