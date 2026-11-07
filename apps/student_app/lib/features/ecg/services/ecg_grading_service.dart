import 'package:arbor_med/features/analytics/models/ecg_case.dart';

/// Immutable representation of user input for an ECG interpretation session.
class EcgSubmission {
  final String rhythmRegularity;
  final bool isSinus;
  final String conductionRatio;
  final String rate;
  final String prCategory;
  final String qrsCategory;
  final String qtCategory;
  final String avBlock;
  final String saBlock;
  final String axis;
  final String pWaveMorph;
  final String atrialEnlargement;
  final String hypertrophy;
  final String bbb;
  final String qWaves;
  final String ischemia;
  final String tWave;
  final int? selectedDiagnosisId;
  final List<int> selectedSecondaryDiagnoses;
  final String urgency;
  final String managementNotes;

  const EcgSubmission({
    this.rhythmRegularity = '',
    this.isSinus = false,
    this.conductionRatio = '',
    this.rate = '',
    this.prCategory = '',
    this.qrsCategory = '',
    this.qtCategory = '',
    this.avBlock = '',
    this.saBlock = '',
    this.axis = '',
    this.pWaveMorph = '',
    this.atrialEnlargement = '',
    this.hypertrophy = '',
    this.bbb = '',
    this.qWaves = '',
    this.ischemia = '',
    this.tWave = '',
    this.selectedDiagnosisId,
    this.selectedSecondaryDiagnoses = const [],
    this.urgency = 'Routine',
    this.managementNotes = '',
  });
}

/// Evaluated feedback result for an ECG session.
class EcgGradingResult {
  final int score;
  final int timeInSeconds;
  final bool isCorrect;
  final bool isPrimaryCorrect;
  final bool isSecondaryCorrect;
  final int? correctDiagnosisId;
  final Map<String, Map<String, dynamic>> detailedReport;

  const EcgGradingResult({
    required this.score,
    required this.timeInSeconds,
    required this.isCorrect,
    required this.isPrimaryCorrect,
    required this.isSecondaryCorrect,
    required this.correctDiagnosisId,
    required this.detailedReport,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'time': timeInSeconds,
      'isCorrect': isCorrect,
      'correctDiagnosisId': correctDiagnosisId,
      'secondaryDxCorrect': isSecondaryCorrect,
      'detailed': detailedReport,
      'primary_dx_correct': isPrimaryCorrect,
    };
  }
}

/// Pure grading service for evaluating ECG interpretation accuracy.
class EcgGradingService {
  const EcgGradingService._();

  /// Evaluates an [EcgSubmission] against canonical [ecgCase] findings.
  static EcgGradingResult grade({
    required EcgSubmission submission,
    required ECGCase ecgCase,
    required Duration duration,
    required Set<String> interactedSections,
    Map<String, dynamic>? fallbackMasterFindings,
  }) {
    final Map<String, dynamic> caseFindings = _ensureMap(ecgCase.findings);
    final Map<String, dynamic> standard = caseFindings.isNotEmpty
        ? caseFindings
        : _ensureMap(fallbackMasterFindings);

    final bool isDxCorrect = submission.selectedDiagnosisId == ecgCase.diagnosisId;

    bool secondaryDxCorrect = true;
    if (ecgCase.secondaryDiagnosesIds.isNotEmpty) {
      final expectedSet = ecgCase.secondaryDiagnosesIds.toSet();
      final selectedSet = submission.selectedSecondaryDiagnoses.toSet();
      secondaryDxCorrect =
          expectedSet.difference(selectedSet).isEmpty &&
          selectedSet.difference(expectedSet).isEmpty;
    }

    final int interpretationCount = interactedSections.length;
    final bool isLazy = interpretationCount < 4;

    int score = 1;
    if (isDxCorrect) {
      if (duration.inSeconds < 60) {
        score = 5;
      } else if (duration.inSeconds < 120) {
        score = 4;
      } else if (duration.inSeconds < 300) {
        score = 3;
      } else {
        score = 2;
      }

      if (isLazy && score > 2) {
        score = 2;
      }
      if (interpretationCount == 0 && score > 1) {
        score = 1;
      }
    }

    final reportData = <String, Map<String, dynamic>>{};

    void addReportItem(
      String key,
      String title,
      dynamic userVal,
      dynamic standardVal,
    ) {
      bool correct = false;
      if (key == 'rate') {
        final u = int.tryParse(userVal?.toString() ?? '');
        final s = int.tryParse(standardVal?.toString() ?? '');
        final target = int.tryParse(_getNested(standard, 'rate', 'target')?.toString() ?? '');
        final minRate = int.tryParse(_getNested(standard, 'rate', 'min')?.toString() ?? '');
        final maxRate = int.tryParse(_getNested(standard, 'rate', 'max')?.toString() ?? '');

        if (u != null) {
          if (target != null && (u - target).abs() <= 5) {
            correct = true;
          } else if (minRate != null && maxRate != null && u >= (minRate - 5) && u <= (maxRate + 5)) {
            correct = true;
          } else if (s != null && (u - s).abs() <= 5) {
            correct = true;
          }
        }
      } else {
        final uStr = (userVal?.toString() ?? '').toLowerCase().trim();
        final sStr = (standardVal?.toString() ?? '').toLowerCase().trim();
        if (uStr.isNotEmpty && sStr.isNotEmpty) {
          correct = (uStr == sStr) ||
              (uStr.contains(sStr) && sStr.length > 3) ||
              (sStr.contains(uStr) && uStr.length > 3);
        }
      }

      reportData[key] = {
        'title': title,
        'user': userVal?.toString() ?? 'N/A',
        'standard': standardVal?.toString() ?? 'Normal',
        'isCorrect': correct,
      };
    }

    addReportItem(
      'rhythm',
      'Rhythm',
      submission.rhythmRegularity,
      _getNested(standard, 'rhythm', 'regularity') ?? 'Regular',
    );
    addReportItem(
      'sinus',
      'Sinus Rhythm',
      submission.isSinus ? 'Yes' : 'No',
      (_getNested(standard, 'rhythm', 'sinus') == false) ? 'No' : 'Yes',
    );
    addReportItem(
      'conduction',
      'Conduction Ratio',
      submission.conductionRatio,
      _getNested(standard, 'rhythm', 'conduction_ratio') ??
          _getNested(standard, 'rhythm', 'p_qrs_relation') ??
          '1:1',
    );
    addReportItem(
      'rate',
      'Heart Rate',
      submission.rate,
      _getNested(standard, 'rate', 'target')?.toString() ??
          _getNested(standard, 'rate', 'max')?.toString() ??
          '75',
    );

    addReportItem(
      'pr',
      'PR Interval',
      submission.prCategory,
      _getNested(standard, 'conduction', 'pr_category') ??
          _mapMsToCategory(
            _getNested(standard, 'conduction', 'pr_interval'),
            120,
            200,
          ),
    );
    addReportItem(
      'qrs',
      'QRS Duration',
      submission.qrsCategory,
      _getNested(standard, 'conduction', 'qrs_category') ??
          _mapMsToCategory(
            _getNested(standard, 'conduction', 'qrs_duration'),
            0,
            120,
            isQrs: true,
          ),
    );
    addReportItem(
      'qt',
      'QT Interval',
      submission.qtCategory,
      _getNested(standard, 'conduction', 'qt_category') ??
          _mapMsToCategory(
            _getNested(standard, 'conduction', 'qt_interval'),
            0,
            440,
          ),
    );

    addReportItem(
      'av_block',
      'AV Block',
      submission.avBlock,
      _getNested(standard, 'conduction', 'av_block') ?? 'None',
    );
    addReportItem(
      'sa_block',
      'SA Block',
      submission.saBlock,
      _getNested(standard, 'conduction', 'sa_block') ??
          _getNested(standard, 'rhythm', 'sa_block') ??
          'None',
    );
    addReportItem(
      'axis',
      'Heart Axis',
      submission.axis,
      _getNested(standard, 'axis', 'quadrant') ??
          (standard['axis'] is String ? standard['axis'] : 'Normal'),
    );
    addReportItem(
      'pmorph',
      'P-Wave',
      submission.pWaveMorph,
      _getNested(standard, 'p_wave', 'morphology') ?? 'Normal',
    );
    addReportItem(
      'atrial',
      'Atrial Enl.',
      submission.atrialEnlargement,
      _getNested(standard, 'p_wave', 'atrial_enlargement') ??
          _getNested(standard, 'p_wave', 'enlargement') ??
          'None',
    );
    addReportItem(
      'hypertrophy',
      'Hypertrophy',
      submission.hypertrophy,
      _getNested(standard, 'qrs_morph', 'hypertrophy') ??
          _getNested(standard, 'qrs', 'hypertrophy') ??
          'None',
    );
    addReportItem(
      'bbb',
      'Bundle Branch',
      submission.bbb,
      _getNested(standard, 'qrs_morph', 'bbb') ??
          _getNested(standard, 'qrs', 'bbb') ??
          'None',
    );
    addReportItem(
      'qwaves',
      'Pathological Q-Waves',
      submission.qWaves,
      _getNested(standard, 'qrs_morph', 'q_waves') ??
          _getNested(standard, 'qrs', 'q_waves') ??
          'None',
    );
    addReportItem(
      'st',
      'ST Segment',
      submission.ischemia,
      _getNested(standard, 'st_t', 'ischemia') ?? 'None',
    );
    addReportItem(
      'twave',
      'T-Wave',
      submission.tWave,
      _getNested(standard, 'st_t', 't_wave') ?? 'Normal',
    );
    addReportItem(
      'urgency',
      'Clinical Urgency',
      submission.urgency,
      _getNested(standard, 'management', 'urgency') ?? 'Routine',
    );

    return EcgGradingResult(
      score: score,
      timeInSeconds: duration.inSeconds,
      isCorrect: isDxCorrect && secondaryDxCorrect,
      isPrimaryCorrect: isDxCorrect,
      isSecondaryCorrect: secondaryDxCorrect,
      correctDiagnosisId: ecgCase.diagnosisId,
      detailedReport: reportData,
    );
  }

  static dynamic _getNested(dynamic map, String section, String key) {
    if (map is! Map) return null;
    final s = map[section];
    if (s is Map) return s[key];
    return null;
  }

  static String _mapMsToCategory(
    dynamic val,
    int min,
    int max, {
    bool isQrs = false,
  }) {
    if (val == null) return 'Normal';
    final n = int.tryParse(val.toString()) ?? 0;
    if (n == 0) return 'Normal';
    if (n > max) return 'Prolonged';
    if (min > 0 && n < min) return 'Short';
    return 'Normal';
  }

  static Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}

