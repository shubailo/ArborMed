import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'connection/connection.dart' as conn;

part 'database.g.dart';

// --- Tables ---

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get topicId => integer().nullable()();
  TextColumn get questionText => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get options =>
      text().nullable()(); // Store as JSON string or comma-separated
  TextColumn get correctAnswer => text().nullable()();
  TextColumn get explanation => text().nullable()();
  IntColumn get bloomLevel => integer().nullable()();
  IntColumn get difficulty => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastFetched => dateTime().nullable()();
}

class TopicProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable()();
  TextColumn get topicSlug => text().nullable()();

  IntColumn get currentBloomLevel => integer().withDefault(const Constant(1))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveWrong => integer().withDefault(const Constant(0))();
  IntColumn get totalAnswered => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswered => integer().withDefault(const Constant(0))();
  IntColumn get masteryScore => integer().withDefault(const Constant(0))();
  IntColumn get unlockedBloomLevel =>
      integer().withDefault(const Constant(1))();
  IntColumn get questionsMastered => integer().withDefault(const Constant(0))();
  IntColumn get levelCorrectCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, topicSlug}
      ];
}

class QuestionProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable()();
  IntColumn get questionId => integer().nullable()();

  IntColumn get box => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();
  BoolColumn get mastered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastAnsweredAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, questionId}
      ];
}

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get slotType => text().nullable()();
  IntColumn get price => integer().nullable()();
  TextColumn get assetPath => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get theme => text().nullable()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
}

class Furniture extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().unique()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get nameHu => text().nullable()();
  TextColumn get assetPath => text().nullable()();
  TextColumn get type => text().nullable()();
  IntColumn get price => integer().withDefault(const Constant(0))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(true))();
  BoolColumn get isPlaced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
}

class StudentProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get displayName => text().withDefault(const Constant('Student'))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get coins => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
}

class UserItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get userId => integer().nullable()();
  IntColumn get itemId => integer().nullable()();
  BoolColumn get isPlaced => boolean().withDefault(const Constant(false))();
  IntColumn get roomId => integer().nullable()();
  TextColumn get slot => text().nullable()();
  IntColumn get xPos => integer().withDefault(const Constant(0))();
  IntColumn get yPos => integer().withDefault(const Constant(0))();
}

// --- New Tables for ECG Feature ---

class EcgCases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()(); // CaseType enum as string
  TextColumn get difficulty => text()(); // Difficulty enum as string
  TextColumn get assetPath => text()();
  TextColumn get correctDiagnoses => text()(); // JSON encoded list of strings
}

class EcgDiagnoses extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// --- Database Connection ---

@DriftDatabase(tables: [
  Questions,
  TopicProgress,
  QuestionProgress,
  Items,
  UserItems,
  EcgCases,
  EcgDiagnoses,
  Furniture,
  StudentProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(conn.openConnection());
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.deleteTable('sync_actions');
          await m.alterTable(TableMigration(topicProgress));
          await m.alterTable(TableMigration(questionProgress));
          await m.alterTable(TableMigration(userItems));
        }
        if (from < 3) {
          await m.addColumn(topicProgress, topicProgress.levelCorrectCount);
        }
        if (from < 4) {
          await m.createTable(ecgCases);
          await m.createTable(ecgDiagnoses);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> clearUserData() async {
    await batch((batch) {
      batch.deleteWhere(topicProgress, (row) => const Constant(true));
      batch.deleteWhere(questionProgress, (row) => const Constant(true));
      batch.deleteWhere(userItems, (row) => const Constant(true));
    });
    debugPrint("✅ Local database user data cleared.");
  }
}
