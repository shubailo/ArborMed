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
  TextColumn get options => text().nullable()(); // Store as JSON string or comma-separated
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
  IntColumn get unlockedBloomLevel => integer().withDefault(const Constant(1))();
  IntColumn get questionsMastered => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt => dateTime().nullable()();
  
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

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
  IntColumn get consecutiveCorrect => integer().withDefault(const Constant(0))();
  BoolColumn get mastered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastAnsweredAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

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

class UserItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get userId => integer().nullable()();
  IntColumn get itemId => integer().nullable()();
  BoolColumn get isPlaced => boolean().withDefault(const Constant(false))();
  IntColumn get roomId => integer().nullable()();
  TextColumn get slot => text().nullable()();
  IntColumn get xPos => integer().nullable()();
  IntColumn get yPos => integer().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
}

class SyncActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text().nullable()(); // 'BUY', 'EQUIP', 'UNEQUIP', 'QUIZ_RESULT'
  TextColumn get payload => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

// --- Database Connection ---

@DriftDatabase(tables: [
  Questions,
  TopicProgress,
  QuestionProgress,
  Items,
  UserItems,
  SyncActions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(conn.openConnection());

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  @override
  int get schemaVersion => 1;

  /// 🧹 Clears all user-specific data from the local database.
  /// Used during logout to ensure user isolation.
  Future<void> clearUserData() async {
    await batch((batch) {
      batch.deleteWhere(topicProgress, (row) => const Constant(true));
      batch.deleteWhere(questionProgress, (row) => const Constant(true));
      batch.deleteWhere(userItems, (row) => const Constant(true));
      batch.deleteWhere(syncActions, (row) => const Constant(true));
    });
    debugPrint("✅ Local database user data cleared.");
  }
}
