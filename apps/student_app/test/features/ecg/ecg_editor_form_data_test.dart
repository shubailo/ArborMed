import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/features/ecg/models/ecg_editor_form_data.dart';

void main() {
  group('ECGEditorFormData', () {
    test('default constructor creates valid baseline data', () {
      const data = ECGEditorFormData();
      expect(data.history, '');
      expect(data.rhythmRegularity, 'Regular');
      expect(data.isSinus, true);
      expect(data.rate, 60);
      expect(data.includeManagement, false);
      expect(data.toFindingsJson(), isA<Map<String, dynamic>>());
    });

    test('fromFindings parses full findings JSON correctly', () {
      final json = {
        'history': '65yo male with chest pain',
        'rhythm': {
          'regularity': 'Irregular',
          'sinus': false,
          'p_qrs_relation': 'Variable',
        },
        'rate': {'target': 120, 'min': 100, 'max': 140},
        'conduction': {
          'pr_category': 'Prolonged',
          'qrs_category': 'Normal',
          'qt_category': 'Prolonged',
          'av_block': 'First Degree',
          'sa_block': 'None',
        },
        'axis': {'quadrant': 'Left'},
        'p_wave': {'morphology': 'Inverted', 'atrial_enlargement': 'Left'},
        'qrs_morph': {
          'hypertrophy': 'LVH',
          'bbb': 'LBBB',
          'q_waves': 'Inferior',
        },
        'st_t': {'ischemia': 'STEMI', 't_wave': 'Inverted'},
        'management': {'urgency': 'Emergency', 'notes': 'Activate cath lab'},
      };

      final data = ECGEditorFormData.fromFindings(json);
      expect(data.history, '65yo male with chest pain');
      expect(data.rhythmRegularity, 'Irregular');
      expect(data.isSinus, false);
      expect(data.conductionRatio, 'Variable');
      expect(data.rate, 120);
      expect(data.prCategory, 'Prolonged');
      expect(data.avBlock, 'First Degree');
      expect(data.axis, 'Left');
      expect(data.hypertrophy, 'LVH');
      expect(data.ischemia, 'STEMI');
      expect(data.includeManagement, true);
      expect(data.urgency, 'Emergency');
      expect(data.managementNotes, 'Activate cath lab');
    });

    test('toFindingsJson serializes correctly and roundtrips', () {
      const original = ECGEditorFormData(
        history: 'Test patient',
        rate: 85,
        axis: 'Right',
        includeManagement: true,
        urgency: 'Urgent',
        managementNotes: 'Refer to cardiology',
      );

      final json = original.toFindingsJson();
      final roundtripped = ECGEditorFormData.fromFindings(json);

      expect(roundtripped.history, original.history);
      expect(roundtripped.rate, original.rate);
      expect(roundtripped.axis, original.axis);
      expect(roundtripped.includeManagement, true);
      expect(roundtripped.urgency, 'Urgent');
      expect(roundtripped.managementNotes, 'Refer to cardiology');
    });

    test('mapMsToCategory maps intervals accurately', () {
      expect(ECGEditorFormData.mapMsToCategory(100, 120, 200), 'Shortened');
      expect(ECGEditorFormData.mapMsToCategory(160, 120, 200), 'Normal');
      expect(ECGEditorFormData.mapMsToCategory(220, 120, 200), 'Prolonged');
      expect(ECGEditorFormData.mapMsToCategory(null, 120, 200), 'Normal');
    });
  });
}

