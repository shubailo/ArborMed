import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import '../database.dart';

class DriftSeedingService {
  final AppDatabase _db;
  final Logger _logger;

  DriftSeedingService({required AppDatabase db, Logger? logger})
      : _db = db,
        _logger = logger ?? Logger();

  Future<void> seedDatabaseIfNeeded() async {
    final count = await _db.select(_db.questions).get();
    if (count.isEmpty) {
      _logger.i('Seeding database with initial data...');
      await _seedQuestions();
      await _seedEcgData();
      _logger.i('Database seeding completed.');
    } else {
      _logger.i('Database already contains data, skipping seeding.');
    }
  }

  Future<void> _seedQuestions() async {
    // Basic mock questions for now, standard practice in this repo
    final questions = [
      QuestionsCompanion.insert(
        questionText: const Value('What is the first step in basic life support?'),
        correctAnswer: const Value('Safety assessment'),
        options: const Value('["Safety assessment", "Checking pulse", "Starting compressions", "Calling 911"]'),
        type: const Value('multiple_choice'),
        difficulty: const Value(1),
        bloomLevel: const Value(1),
        topicId: const Value(1),
      ),
      QuestionsCompanion.insert(
        questionText: const Value('Which of the following is a sign of tension pneumothorax?'),
        correctAnswer: const Value('Tracheal deviation'),
        options: const Value('["Tracheal deviation", "Hypertension", "Bradycardia", "Equal breath sounds"]'),
        type: const Value('multiple_choice'),
        difficulty: const Value(2),
        bloomLevel: const Value(2),
        topicId: const Value(1),
      ),
    ];

    await _db.batch((batch) {
      batch.insertAll(_db.questions, questions);
    });
  }

  Future<void> _seedEcgData() async {
    // Seed ECG Diagnoses
    final diagnoses = [
      EcgDiagnosesCompanion.insert(
        id: 'NSR',
        name: 'Normal Sinus Rhythm',
        description: const Value('Normal heart rhythm started in the sinus node.'),
      ),
      EcgDiagnosesCompanion.insert(
        id: 'AFIB',
        name: 'Atrial Fibrillation',
        description: const Value('Irregular, often rapid heart rate.'),
      ),
    ];

    await _db.batch((batch) {
      batch.insertAll(_db.ecgDiagnoses, diagnoses);
    });

    // Seed ECG Cases
    final cases = [
      EcgCasesCompanion.insert(
        title: 'Case 1 - Routine Checkup',
        type: 'rhythm_strip',
        difficulty: 'easy',
        assetPath: 'assets/ecg/case1.png',
        correctDiagnoses: '["NSR"]',
      ),
    ];

    await _db.batch((batch) {
      batch.insertAll(_db.ecgCases, cases);
    });
  }
}
