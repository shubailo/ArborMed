import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/features/analytics/models/ecg_case.dart';
import 'package:arbor_med/features/ecg/services/ecg_grading_service.dart';

void main() {
  group('EcgGradingService', () {
    final dummyCase = ECGCase(
      id: 1,
      diagnosisId: 10,
      imageUrl: '/uploads/ecg/case_1.png',
      difficulty: 'beginner',
      findings: {
        'rhythm': {'regularity': 'Regular', 'sinus': true, 'p_qrs_relation': '1:1'},
        'rate': {'target': 75, 'min': 70, 'max': 80},
        'conduction': {
          'pr_interval': 160,
          'pr_category': 'Normal',
          'qrs_duration': 90,
          'qrs_category': 'Normal',
          'qt_interval': 400,
          'qt_category': 'Normal',
          'av_block': 'None',
          'sa_block': 'None',
        },
        'axis': {'quadrant': 'Normal'},
        'p_wave': {'morphology': 'Normal', 'atrial_enlargement': 'None'},
        'qrs_morph': {'hypertrophy': 'None', 'bbb': 'None', 'q_waves': 'None'},
        'st_t': {'ischemia': 'None', 't_wave': 'Normal'},
        'management': {'urgency': 'Routine'},
      },
      secondaryDiagnosesIds: [20],
    );

    test('grades perfect submission correctly with 5 stars under 60 seconds', () {
      const submission = EcgSubmission(
        rhythmRegularity: 'Regular',
        isSinus: true,
        conductionRatio: '1:1',
        rate: '75',
        prCategory: 'Normal',
        qrsCategory: 'Normal',
        qtCategory: 'Normal',
        avBlock: 'None',
        saBlock: 'None',
        axis: 'Normal',
        pWaveMorph: 'Normal',
        atrialEnlargement: 'None',
        hypertrophy: 'None',
        bbb: 'None',
        qWaves: 'None',
        ischemia: 'None',
        tWave: 'Normal',
        selectedDiagnosisId: 10,
        selectedSecondaryDiagnoses: [20],
        urgency: 'Routine',
      );

      final interacted = {'rhythm', 'rate', 'conduction', 'axis', 'pwave'};

      final result = EcgGradingService.grade(
        submission: submission,
        ecgCase: dummyCase,
        duration: const Duration(seconds: 45),
        interactedSections: interacted,
      );

      expect(result.score, 5);
      expect(result.isCorrect, isTrue);
      expect(result.isPrimaryCorrect, isTrue);
      expect(result.isSecondaryCorrect, isTrue);
      expect(result.detailedReport['rate']?['isCorrect'], isTrue);
      expect(result.detailedReport['rhythm']?['isCorrect'], isTrue);
      expect(result.detailedReport['axis']?['isCorrect'], isTrue);
    });

    test('distinct rhythm and conduction categories never match by substring', () {
      for (final (expectedRhythm, givenRhythm, expectedBlock, givenBlock) in [
        ('Regular', 'Irregular', '2nd Degree Type I', '2nd Degree Type II'),
        ('Irregular', 'Regular', '2nd Degree Type II', '2nd Degree Type I'),
      ]) {
        final result = EcgGradingService.grade(
          submission: EcgSubmission(rhythmRegularity: givenRhythm, avBlock: givenBlock),
          ecgCase: ECGCase(
            id: 1, diagnosisId: 10, imageUrl: '', difficulty: 'beginner',
            findings: {
              'rhythm': {'regularity': expectedRhythm},
              'conduction': {'av_block': expectedBlock},
            },
          ),
          duration: Duration.zero,
          interactedSections: {},
        );
        expect(result.detailedReport['rhythm']!['isCorrect'], isFalse);
        expect(result.detailedReport['av_block']!['isCorrect'], isFalse);
      }
    });

    test('penalizes skipping steps even with correct diagnosis', () {
      const submission = EcgSubmission(
        selectedDiagnosisId: 10,
        selectedSecondaryDiagnoses: [20],
      );

      final result = EcgGradingService.grade(
        submission: submission,
        ecgCase: dummyCase,
        duration: const Duration(seconds: 15),
        interactedSections: {}, // Zero interacted sections
      );

      expect(result.score, 1);
      expect(result.isCorrect, isTrue);
    });

    test('marks incorrect diagnosis as 1 star participation', () {
      const submission = EcgSubmission(
        selectedDiagnosisId: 999, // Wrong diagnosis
      );

      final result = EcgGradingService.grade(
        submission: submission,
        ecgCase: dummyCase,
        duration: const Duration(seconds: 45),
        interactedSections: {'rhythm', 'rate', 'conduction'},
      );

      expect(result.score, 1);
      expect(result.isCorrect, isFalse);
      expect(result.isPrimaryCorrect, isFalse);
    });

    test('rate tolerance allows target +/- 5 bpm', () {
      const submission = EcgSubmission(
        rate: '79', // Target is 75, so 79 is within +/- 5
        selectedDiagnosisId: 10,
        selectedSecondaryDiagnoses: [20],
      );

      final result = EcgGradingService.grade(
        submission: submission,
        ecgCase: dummyCase,
        duration: const Duration(seconds: 50),
        interactedSections: {'rate'},
      );

      expect(result.detailedReport['rate']?['isCorrect'], isTrue);
    });
  });
}
