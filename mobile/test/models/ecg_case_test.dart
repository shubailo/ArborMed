import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/ecg_case.dart';

void main() {
  group('ECGCase.fromJson', () {
    test('parses valid full JSON correctly', () {
      final json = {
        'id': 123,
        'diagnosis_id': 10,
        'image_url': 'http://example.com/ecg.jpg',
        'difficulty': 'intermediate',
        'findings_json': {'rate': 75},
        'diagnosis_code': 'AFIB',
        'diagnosis_name': 'Atrial Fibrillation',
        'secondary_diagnoses_ids': [1, 2, 3]
      };

      final ecgCase = ECGCase.fromJson(json);

      expect(ecgCase.id, 123);
      expect(ecgCase.diagnosisId, 10);
      expect(ecgCase.imageUrl, 'http://example.com/ecg.jpg');
      expect(ecgCase.difficulty, 'intermediate');
      expect(ecgCase.findings, {'rate': 75});
      expect(ecgCase.diagnosisCode, 'AFIB');
      expect(ecgCase.diagnosisName, 'Atrial Fibrillation');
      expect(ecgCase.secondaryDiagnosesIds, [1, 2, 3]);
    });

    test('handles null/missing optional fields', () {
      final json = {
        'id': 123,
        'diagnosis_id': 10,
        // image_url missing
        // findings_json missing
        // secondary_diagnoses_ids missing
      };

      final ecgCase = ECGCase.fromJson(json);

      expect(ecgCase.id, 123);
      expect(ecgCase.diagnosisId, 10);
      expect(ecgCase.imageUrl, ''); // Default empty
      expect(ecgCase.difficulty, 'beginner'); // Default
      expect(ecgCase.findings, {}); // Default empty
      expect(ecgCase.diagnosisCode, null);
      expect(ecgCase.secondaryDiagnosesIds, isEmpty);
    });

    test('safely parses string types for numeric fields (API inconsistency)', () {
      final json = {
        'id': '123', // String
        'diagnosis_id': '456', // String
        'secondary_diagnoses_ids': ['1', '2'] // List of strings
      };

      final ecgCase = ECGCase.fromJson(json);

      expect(ecgCase.id, 123);
      expect(ecgCase.diagnosisId, 456);
      expect(ecgCase.secondaryDiagnosesIds, [1, 2]);
    });

    test('handles malformed numbers gracefully', () {
      final json = {
        'id': 'invalid',
        'diagnosis_id': null,
      };

      final ecgCase = ECGCase.fromJson(json);

      expect(ecgCase.id, 0); // safeInt fallback
      expect(ecgCase.diagnosisId, 0);
    });
  });
}
