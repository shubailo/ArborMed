import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/ecg_diagnosis.dart';

void main() {
  group('ECGDiagnosis.fromJson', () {
    test('parses valid full JSON correctly', () {
      final json = {
        'id': 100,
        'code': 'NSR',
        'name_en': 'Normal Sinus Rhythm',
        'name_hu': 'Normál szinusz ritmus',
        'standard_findings_json': {'rate': '60-100'}
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.id, 100);
      expect(diagnosis.code, 'NSR');
      expect(diagnosis.nameEn, 'Normal Sinus Rhythm');
      expect(diagnosis.nameHu, 'Normál szinusz ritmus');
      expect(diagnosis.standardFindings, {'rate': '60-100'});
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 101,
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.id, 101);
      expect(diagnosis.code, '?');
      expect(diagnosis.nameEn, 'Unknown');
      expect(diagnosis.nameHu, '');
      expect(diagnosis.standardFindings, null);
    });

    test('safely parses ID from string', () {
      final json = {
        'id': '200',
        'code': 'AFIB',
        'name_en': 'Atrial Fibrillation',
        'name_hu': 'Pitvarfibrilláció'
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.id, 200);
    });

    test('handles invalid ID format gracefully', () {
      final json = {
        'id': 'invalid_id',
        'code': 'TEST',
        'name_en': 'Test Diagnosis',
        'name_hu': 'Teszt'
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.id, 0);
    });

    test('parses standard_findings_json as JSON string', () {
      final json = {
        'id': 300,
        'code': 'VT',
        'name_en': 'Ventricular Tachycardia',
        'name_hu': 'Kamrai tachycardia',
        'standard_findings_json': '{"rate": ">100", "regular": true}'
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.standardFindings, {'rate': '>100', 'regular': true});
    });

    test('handles null standard_findings_json', () {
      final json = {
        'id': 400,
        'code': 'TEST',
        'name_en': 'Test',
        'name_hu': 'Teszt',
        'standard_findings_json': null
      };

      final diagnosis = ECGDiagnosis.fromJson(json);

      expect(diagnosis.standardFindings, null);
    });
  });
}
