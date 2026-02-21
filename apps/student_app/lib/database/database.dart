import 'package:drift/drift.dart';
import 'connection.dart' as impl;

part 'database.g.dart';

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique()();
  TextColumn get topicId => text()();
  IntColumn get bloomLevel => integer()();
  TextColumn get content => text()();
  TextColumn get optionsJson => text()();
}

@DriftDatabase(tables: [Questions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  @override
  int get schemaVersion => 1;
}
