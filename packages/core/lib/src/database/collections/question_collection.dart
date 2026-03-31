import 'package:isar/isar.dart';

part 'question_collection.g.dart';

@collection
class QuestionCollection {
  Id id = Isar.autoIncrement;

  @Index()
  late int remoteId; // Legacy ID from JSON/SQL

  @Index()
  late String topicSlug;

  // Bilingual Content
  late String textEn;
  late String textHu;

  List<String> optionsEn = [];
  List<String> optionsHu = [];

  // Correct answer is the zero-based index of the option
  late int correctAnswerIndex;

  String? explanationEn;
  String? explanationHu;

  // Metadata
  int bloomLevel = 1; // 1-6 Knowledge/Analysis
  String type = 'single_choice'; // single_choice, multiple_choice, etc.

  // Stats (Denormalized for simple lookup)
  int attempts = 0;
  double successRate = 0.0;
  bool isFavorite = false;

  DateTime createdAt = DateTime.now();
}
