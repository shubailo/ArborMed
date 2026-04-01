import '../models/ecg_case.dart';
import '../models/ecg_diagnosis.dart';

abstract class ECGContract {
  /// Fetches all available ECG cases for practice.
  Future<List<ECGCase>> fetchECGCases();

  /// Fetches all available ECG diagnoses for selection.
  Future<List<ECGDiagnosis>> fetchDiagnoses();

  /// Submits the result of an ECG practice session.
  Future<void> submitResult(ECGResult result);
}

class ECGResult {
  final int caseId;
  final int diagnosisId;
  final Map<String, dynamic> userFindings;
  final Duration duration;
  final DateTime timestamp;

  const ECGResult({
    required this.caseId,
    required this.diagnosisId,
    required this.userFindings,
    required this.duration,
    required this.timestamp,
  });
}
