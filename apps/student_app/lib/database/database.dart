import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'connection/connection.dart' as conn;
import 'connection/browser_storage.dart';

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
  BoolColumn get usesGrid => boolean().withDefault(const Constant(false))();
}

// --- Database Connection ---

@DriftDatabase(tables: [
  Questions,
  TopicProgress,
  QuestionProgress,
  Items,
  UserItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(conn.openConnection());

  AppDatabase.forTesting(super.e);

  Future<void> ensureSubmissionStorage() async {
    final storage = connection;
    if (storage is BrowserStorageConnection) {
      await storage.requirePersistentQueue(this);
    }
  }

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  @override
  int get schemaVersion => 7;

  Future<void> _createSubmissionReceipts() => customStatement('''
    CREATE TABLE IF NOT EXISTS submission_receipts (
      sequence INTEGER PRIMARY KEY,
      submission_id TEXT NOT NULL UNIQUE,
      user_id INTEGER NOT NULL,
      payload TEXT NOT NULL
    )
  ''');

  Future<void> _createSubmissionQueue() => customStatement('''
    CREATE TABLE IF NOT EXISTS pending_submissions (
      sequence INTEGER PRIMARY KEY,
      submission_id TEXT NOT NULL UNIQUE,
      user_id INTEGER NOT NULL,
      topic_slug TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      failure TEXT
    )
  ''');

  Future<void> _createAccountIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS pending_submissions_ready_user '
        'ON pending_submissions(user_id, sequence) WHERE failure IS NULL');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS user_items_by_user ON user_items(user_id)');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => transaction(() async {
        await m.createAll();
        await _createSubmissionQueue();
        await _createSubmissionReceipts();
        await _createAccountIndexes();
      }),
      onUpgrade: (m, from, to) => transaction(() async {
        if (from > to) {
          throw UnsupportedError(
              'Database version $from requires a newer app.');
        }
        if (from < 2) {
          // Retire isDirty columns and SyncActions table
          await m.deleteTable('sync_actions');
          await m.alterTable(TableMigration(topicProgress,
              newColumns: [topicProgress.levelCorrectCount]));
          await m.alterTable(TableMigration(questionProgress));
          await m.alterTable(TableMigration(userItems, newColumns: [userItems.usesGrid]));
        }
        if (from == 2) {
          // A previous release could commit the ALTER before updating user_version.
          final columns =
              await customSelect('PRAGMA table_info(topic_progress)').get();
          if (!columns.any(
              (row) => row.read<String>('name') == 'level_correct_count')) {
            await m.addColumn(topicProgress, topicProgress.levelCorrectCount);
          }
        }
        if (from < 4) await _createSubmissionQueue();
        if (from < 5) await _createAccountIndexes();
        if (from < 7) await _createSubmissionReceipts();
        if (from >= 2 && from < 6) {
          await m.addColumn(userItems, userItems.usesGrid);
        }
        if (from < 6) {
          await customStatement('''
            UPDATE user_items SET uses_grid = 1
            WHERE is_placed = 1 AND (x_pos <> 0 OR y_pos <> 0 OR slot = 'floor')
          ''');
        }
      }),
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Clears only the outgoing account's cache. Its pending submissions remain available on return.
  Future<void> clearUserCacheFor(int userId) => batch((batch) {
        batch.customStatement('DELETE FROM submission_receipts WHERE user_id = ?', [userId]);
        batch.deleteWhere(topicProgress, (row) => row.userId.equals(userId));
        batch.deleteWhere(questionProgress, (row) => row.userId.equals(userId));
        batch.deleteWhere(userItems, (row) => row.userId.equals(userId));
      });

  /// Clears cached progress and inventory for every account.
  /// Sign-out uses [clearUserCacheFor]. Both methods retain queued submissions.
  Future<void> clearUserData() async {
    await batch((batch) {
      batch.customStatement('DELETE FROM submission_receipts');
      batch.deleteWhere(topicProgress, (row) => const Constant(true));
      batch.deleteWhere(questionProgress, (row) => const Constant(true));
      batch.deleteWhere(userItems, (row) => const Constant(true));
    });
    debugPrint("✅ Local database user data cleared.");
  }
}
