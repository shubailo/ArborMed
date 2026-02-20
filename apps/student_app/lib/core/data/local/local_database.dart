import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

class LocalQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get topicId => text()();
  IntColumn get bloomLevel => integer()();
  TextColumn get content => text()();
  TextColumn get explanation => text()();
  TextColumn get optionsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMastery extends Table {
  TextColumn get userId => text()();
  TextColumn get questionId => text()();
  RealColumn get easiness => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReview => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId, questionId};
}

@DriftDatabase(tables: [LocalQuestions, LocalMastery])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
