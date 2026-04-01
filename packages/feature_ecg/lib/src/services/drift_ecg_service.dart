import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class DriftECGService implements ECGContract {
  final AppDatabase _db;
  final Logger _logger;

  DriftECGService({required AppDatabase db, Logger? logger}) 
      : _db = db,
        _logger = logger ?? Logger();

  @override
  Future<List<ECGDiagnosis>> fetchDiagnoses() async {
    final diagnoses = await _db.select(_db.ecgDiagnoses).get();
    return diagnoses.map((d) => ECGDiagnosis(
      id: 0, // Numeric ID for legacy parity
      code: d.id, // Using string ID as code
      nameEn: d.name,
      nameHu: d.name,
      standardFindings: d.description != null 
          ? {'description': d.description}
          : null,
    )).toList();
  }

  @override
  Future<List<ECGCase>> fetchECGCases() async {
    final cases = await _db.select(_db.ecgCases).get();
    return cases.map((c) => ECGCase(
      id: c.id,
      imageUrl: c.assetPath,
      difficulty: c.difficulty,
      diagnosisId: 0, 
      findings: {},
      diagnosisCode: c.correctDiagnoses,
      diagnosisName: '',
      secondaryDiagnosesIds: [],
    )).toList();
  }

  @override
  Future<void> submitResult(ECGResult result) async {
    _logger.i('Submitting ECG Result: Case ${result.caseId}');
    // In a real app we'd save to a results table
  }
}
