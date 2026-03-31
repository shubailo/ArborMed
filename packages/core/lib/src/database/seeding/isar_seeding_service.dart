import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:isar/isar.dart';

import 'package:arbormed_core/arbormed_core.dart';
import 'package:arbormed_core/src/database/collections/question_collection.dart';

class IsarSeedingService {
  final Logger _logger;
  final DatabaseService _dbService;

  IsarSeedingService({Logger? logger, required DatabaseService dbService})
      : _logger = logger ?? Logger(),
        _dbService = dbService;

  /// Loads fallback legacy data into Isar if empty.
  Future<void> seedDatabaseIfNeeded() async {
    final isar = _dbService.isar;
    if (isar == null) {
      _logger.w('Isar not initialized, skipping seed.');
      return;
    }

    final count = await isar.questionCollections.count();
    if (count > 0) {
      _logger.i('Database already seeded ($count questions). Skipping.');
      return;
    }

    _logger.i('Seeding Isar database from legacy mock data...');

    // Mock initial legacy data for the migration.
    final mockQuestions = [
      QuestionCollection()
        ..remoteId = 101
        ..topicSlug = "anatomy"
        ..textEn = "What is the largest organ in the human body?"
        ..textHu = "Melyik a legnagyobb szerv az emberi testben?"
        ..optionsEn = ["Heart", "Skin", "Liver", "Brain"]
        ..optionsHu = ["Szív", "Bőr", "Máj", "Agy"]
        ..correctAnswerIndex = 1
        ..bloomLevel = 1
        ..type = 'single_choice',
      QuestionCollection()
        ..remoteId = 102
        ..topicSlug = "cardiology"
        ..textEn = "Which node is the natural pacemaker of the heart?"
        ..textHu = "Melyik csomó a szív természetes pacemakere?"
        ..optionsEn = ["AV node", "SA node", "Bundle of His", "Purkinje fibers"]
        ..optionsHu = ["AV csomó", "SA csomó", "His-köteg", "Purkinje rostok"]
        ..correctAnswerIndex = 1
        ..bloomLevel = 2
        ..type = 'single_choice',
    ];

    try {
      await isar.writeTxn(() async {
        await isar.questionCollections.putAll(mockQuestions);
      });
      _logger.i('Successfully seeded ${mockQuestions.length} questions into Isar.');
    } catch (e) {
      _logger.e('Failed to seed Isar database: $e');
    }
  }
}
