import 'dart:io';
import 'package:arbor_med/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const oldInventory = 'CREATE TABLE user_items (id INTEGER PRIMARY KEY,user_id INTEGER, '
      'server_id INTEGER,item_id INTEGER,room_id INTEGER,is_placed INTEGER NOT NULL DEFAULT 0, '
      'slot TEXT,x_pos INTEGER NOT NULL DEFAULT 0,y_pos INTEGER NOT NULL DEFAULT 0)';
  AppDatabase open([DatabaseSetup? setup]) {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: setup));
    addTearDown(db.close);
    return db;
  }

  const queue =
      'CREATE TABLE pending_submissions (sequence INTEGER PRIMARY KEY,submission_id TEXT NOT NULL UNIQUE,user_id INTEGER NOT NULL,topic_slug TEXT NOT NULL,payload TEXT NOT NULL,created_at INTEGER NOT NULL,failure TEXT)';
  const insert =
      "INSERT INTO pending_submissions(submission_id,user_id,topic_slug,payload,created_at) VALUES ('a',1,'ekg','{}',1)";
  test(
      'a partially upgraded local database reopens without dropping a queued answer',
      () async {
    final db = open((raw) {
      raw.execute(
          'CREATE TABLE topic_progress (id INTEGER PRIMARY KEY, level_correct_count INTEGER NOT NULL DEFAULT 0)');
      raw.execute(
          oldInventory);
      raw.execute(queue);
      raw.execute(insert);
      raw.execute('PRAGMA user_version=2');
    });
    expect(
        (await db
                .customSelect('SELECT submission_id FROM pending_submissions')
                .getSingle())
            .data['submission_id'],
        'a');
    expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        7);
  });
  test('an older app refuses to stamp a newer database with its own version',
      () async {
    final db = open((raw) => raw.execute('PRAGMA user_version=99'));
    await expectLater(
        db.customSelect('SELECT 1').get(), throwsUnsupportedError);
  });
  for (final version in [0, 4]) {
    test(
        'account-scoped reads and eviction have indexed plans from version $version',
        () async {
      final db = open(version == 0
          ? null
          : (raw) {
              raw.execute(queue);
              raw.execute(insert);
              raw.execute(
                  oldInventory);
              raw.execute('PRAGMA user_version=4');
            });
      Future<String> plan(String sql) async =>
          (await db.customSelect('EXPLAIN QUERY PLAN $sql').get())
              .map((r) => r.data['detail'])
              .join(' ');
      expect(
          await plan(
              'SELECT * FROM pending_submissions WHERE user_id=1 AND failure IS NULL ORDER BY sequence LIMIT 1'),
          contains('pending_submissions_ready_user'));
      expect(await plan('DELETE FROM user_items WHERE user_id=1'),
          contains('user_items_by_user'));
      if (version == 4) {
        expect(
            (await db
                    .customSelect(
                        'SELECT submission_id FROM pending_submissions')
                    .getSingle())
                .data['submission_id'],
            'a');
      }
    });
  }

  test('v5 derives known grid locations and keeps local identities', () async {
    final db = open((raw) {
      raw.execute(oldInventory);
      raw.execute('''
        INSERT INTO user_items(id,user_id,server_id,item_id,is_placed,slot,x_pos,y_pos)
        VALUES (31,1,101,9,1,'desk',0,0), (32,1,102,9,1,'floor',0,0),
               (33,1,103,9,1,'desk',4,0), (34,1,104,9,0,'floor',2,0)
      ''');
      raw.execute('PRAGMA user_version=5');
    });
    final rows = await db.select(db.userItems).get();
    expect({for (final row in rows) row.id: row.usesGrid},
        {31:false,32:true,33:true,34:false});
    expect(rows.map((row) => row.serverId), [101,102,103,104]);
  });
  test('an explicit grid origin survives closing and reopening the SQLite file', () async {
    final folder = await Directory.systemTemp.createTemp('arbormed-placement-');
    addTearDown(() => folder.delete(recursive:true));
    final file = File('${folder.path}/inventory.db');
    final writer = AppDatabase.forTesting(NativeDatabase(file));
    try {
      await writer.customStatement("INSERT INTO user_items(user_id,item_id,is_placed,slot,uses_grid) VALUES(1,2,1,'desk',1)");
    } finally {
      await writer.close();
    }
    final reader = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final item = await reader.select(reader.userItems).getSingle();
      expect((item.xPos,item.yPos,item.usesGrid), (0,0,true));
    } finally {
      await reader.close();
    }
  });

  test(
      'logout clears just one profile and keeps its pending answers and the shared catalogue',
      () async {
    final db = open();
    await db.customStatement("INSERT INTO questions(server_id) VALUES (10)");
    await db.customStatement("INSERT INTO items(server_id) VALUES (20)");
    for (final id in [1, 2]) {
      await db.customStatement(
          'INSERT INTO user_items (user_id,item_id) VALUES (?,1)', [id]);
      await db.customStatement(
          "INSERT INTO topic_progress(user_id,topic_slug) VALUES (?,'ekg')",
          [id]);
      await db.customStatement(
          'INSERT INTO question_progress(user_id,question_id) VALUES (?,1)',
          [id]);
      await db.customStatement(
          "INSERT INTO pending_submissions(submission_id,user_id,topic_slug,payload,created_at) VALUES (?,?, 'ekg','{}',1)",
          ['answer-$id', id]);
    }
    await db.clearUserCacheFor(1);
    for (final table in ['user_items', 'question_progress', 'topic_progress']) {
      expect(
          (await db.customSelect('SELECT user_id FROM $table').getSingle())
              .data['user_id'],
          2);
    }
    expect(
        (await db.customSelect('SELECT * FROM pending_submissions').get())
            .length,
        2);
    for (final table in ['questions', 'items']) {
      expect((await db.customSelect('SELECT * FROM $table').get()).length, 1);
    }
  });
  test('failed upgrade rolls back completed DDL and can retry on the same file',
      () async {
    final dir = await Directory.systemTemp.createTemp('arbor-local-db-');
    final file = File('${dir.path}/cache.sqlite');
    addTearDown(() => dir.delete(recursive: true));
    final broken = AppDatabase.forTesting(NativeDatabase(file, setup: (raw) {
      raw.execute('CREATE TABLE topic_progress(id INTEGER PRIMARY KEY)');
      raw.execute('INSERT INTO topic_progress(id) VALUES (7)');
      raw.execute(
          oldInventory);
      raw.execute('CREATE VIEW pending_submissions AS SELECT 1 AS user_id');
      raw.execute('PRAGMA user_version=2');
    }));
    try {
      await expectLater(
          broken.customSelect('SELECT 1').get(), throwsA(isA<Exception>()));
    } finally {
      await broken.close();
    }
    late bool hadPartialColumn;
    final repaired = AppDatabase.forTesting(NativeDatabase(file, setup: (raw) {
      hadPartialColumn = raw
          .select('PRAGMA table_info(topic_progress)')
          .any((r) => r['name'] == 'level_correct_count');
      raw.execute('DROP VIEW pending_submissions');
    }));
    addTearDown(repaired.close);
    expect(
        (await repaired
                .customSelect(
                    'SELECT id, level_correct_count FROM topic_progress')
                .getSingle())
            .data,
        {'id': 7, 'level_correct_count': 0});
    expect(hadPartialColumn, isFalse);
  });
  test('an interrupted account eviction rolls all cache tables back together',
      () async {
    final db = open();
    await db.customStatement(
        "INSERT INTO topic_progress(user_id,topic_slug) VALUES (1,'ekg')");
    await db.customStatement(
        'INSERT INTO question_progress(user_id,question_id) VALUES (1,10)');
    await db.customStatement(
        "CREATE TRIGGER fail_second BEFORE DELETE ON question_progress BEGIN SELECT RAISE(ABORT,'fixture'); END");
    await expectLater(db.clearUserCacheFor(1), throwsA(isA<Exception>()));
    for (final table in ['question_progress', 'topic_progress']) {
      expect(
          (await db.customSelect('SELECT user_id FROM $table').getSingle())
              .data['user_id'],
          1);
    }
  });
}
