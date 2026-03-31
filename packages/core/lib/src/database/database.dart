import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'collections/topic_collection.dart';
import 'collections/question_collection.dart';
import 'collections/student_profile_collection.dart';
import 'collections/furniture_collection.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Isar? _isar;
  Isar get isar => _isar!;

  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [
        TopicCollectionSchema,
        QuestionCollectionSchema,
        StudentProfileCollectionSchema,
        FurnitureCollectionSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
  }

  Future<void> clearAll() async {
    await _isar?.writeTxn(() async {
      await _isar?.clear();
    });
  }
}
