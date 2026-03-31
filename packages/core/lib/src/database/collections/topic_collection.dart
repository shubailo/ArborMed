import 'package:isar/isar.dart';

part 'topic_collection.g.dart';

@collection
class TopicCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String slug;

  late String nameEn;
  late String nameHu;

  String? descriptionEn;
  String? descriptionHu;

  int orderIndex = 0;
  bool isPremium = false;

  // Timestamps
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
