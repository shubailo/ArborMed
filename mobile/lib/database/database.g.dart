// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions with TableInfo<$QuestionsTable, Question>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$QuestionsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _serverIdMeta = const VerificationMeta('serverId');
@override
late final GeneratedColumn<int> serverId = GeneratedColumn<int>('server_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
static const VerificationMeta _topicIdMeta = const VerificationMeta('topicId');
@override
late final GeneratedColumn<int> topicId = GeneratedColumn<int>('topic_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _questionTextMeta = const VerificationMeta('questionText');
@override
late final GeneratedColumn<String> questionText = GeneratedColumn<String>('question_text', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _typeMeta = const VerificationMeta('type');
@override
late final GeneratedColumn<String> type = GeneratedColumn<String>('type', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _optionsMeta = const VerificationMeta('options');
@override
late final GeneratedColumn<String> options = GeneratedColumn<String>('options', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _correctAnswerMeta = const VerificationMeta('correctAnswer');
@override
late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>('correct_answer', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _explanationMeta = const VerificationMeta('explanation');
@override
late final GeneratedColumn<String> explanation = GeneratedColumn<String>('explanation', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _bloomLevelMeta = const VerificationMeta('bloomLevel');
@override
late final GeneratedColumn<int> bloomLevel = GeneratedColumn<int>('bloom_level', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _difficultyMeta = const VerificationMeta('difficulty');
@override
late final GeneratedColumn<int> difficulty = GeneratedColumn<int>('difficulty', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _activeMeta = const VerificationMeta('active');
@override
late final GeneratedColumn<bool> active = GeneratedColumn<bool>('active', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'), defaultValue: const Constant(true));
static const VerificationMeta _lastFetchedMeta = const VerificationMeta('lastFetched');
@override
late final GeneratedColumn<DateTime> lastFetched = GeneratedColumn<DateTime>('last_fetched', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
@override
List<GeneratedColumn> get $columns => [id, serverId, topicId, questionText, type, options, correctAnswer, explanation, bloomLevel, difficulty, active, lastFetched];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'questions';
@override
VerificationContext validateIntegrity(Insertable<Question> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('server_id')) {
context.handle(_serverIdMeta, serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));}if (data.containsKey('topic_id')) {
context.handle(_topicIdMeta, topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));}if (data.containsKey('question_text')) {
context.handle(_questionTextMeta, questionText.isAcceptableOrUnknown(data['question_text']!, _questionTextMeta));}if (data.containsKey('type')) {
context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));}if (data.containsKey('options')) {
context.handle(_optionsMeta, options.isAcceptableOrUnknown(data['options']!, _optionsMeta));}if (data.containsKey('correct_answer')) {
context.handle(_correctAnswerMeta, correctAnswer.isAcceptableOrUnknown(data['correct_answer']!, _correctAnswerMeta));}if (data.containsKey('explanation')) {
context.handle(_explanationMeta, explanation.isAcceptableOrUnknown(data['explanation']!, _explanationMeta));}if (data.containsKey('bloom_level')) {
context.handle(_bloomLevelMeta, bloomLevel.isAcceptableOrUnknown(data['bloom_level']!, _bloomLevelMeta));}if (data.containsKey('difficulty')) {
context.handle(_difficultyMeta, difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta));}if (data.containsKey('active')) {
context.handle(_activeMeta, active.isAcceptableOrUnknown(data['active']!, _activeMeta));}if (data.containsKey('last_fetched')) {
context.handle(_lastFetchedMeta, lastFetched.isAcceptableOrUnknown(data['last_fetched']!, _lastFetchedMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Question map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Question(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, serverId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}server_id']), topicId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}topic_id']), questionText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}question_text']), type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type']), options: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}options']), correctAnswer: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}correct_answer']), explanation: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}explanation']), bloomLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bloom_level']), difficulty: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}difficulty']), active: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}active'])!, lastFetched: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_fetched']), );
}
@override
$QuestionsTable createAlias(String alias) {
return $QuestionsTable(attachedDatabase, alias);}}class Question extends DataClass implements Insertable<Question> 
{
final int id;
final int? serverId;
final int? topicId;
final String? questionText;
final String? type;
final String? options;
final String? correctAnswer;
final String? explanation;
final int? bloomLevel;
final int? difficulty;
final bool active;
final DateTime? lastFetched;
const Question({required this.id, this.serverId, this.topicId, this.questionText, this.type, this.options, this.correctAnswer, this.explanation, this.bloomLevel, this.difficulty, required this.active, this.lastFetched});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || serverId != null){map['server_id'] = Variable<int>(serverId);
}if (!nullToAbsent || topicId != null){map['topic_id'] = Variable<int>(topicId);
}if (!nullToAbsent || questionText != null){map['question_text'] = Variable<String>(questionText);
}if (!nullToAbsent || type != null){map['type'] = Variable<String>(type);
}if (!nullToAbsent || options != null){map['options'] = Variable<String>(options);
}if (!nullToAbsent || correctAnswer != null){map['correct_answer'] = Variable<String>(correctAnswer);
}if (!nullToAbsent || explanation != null){map['explanation'] = Variable<String>(explanation);
}if (!nullToAbsent || bloomLevel != null){map['bloom_level'] = Variable<int>(bloomLevel);
}if (!nullToAbsent || difficulty != null){map['difficulty'] = Variable<int>(difficulty);
}map['active'] = Variable<bool>(active);
if (!nullToAbsent || lastFetched != null){map['last_fetched'] = Variable<DateTime>(lastFetched);
}return map; 
}
QuestionsCompanion toCompanion(bool nullToAbsent) {
return QuestionsCompanion(id: Value(id),serverId: serverId == null && nullToAbsent ? const Value.absent() : Value(serverId),topicId: topicId == null && nullToAbsent ? const Value.absent() : Value(topicId),questionText: questionText == null && nullToAbsent ? const Value.absent() : Value(questionText),type: type == null && nullToAbsent ? const Value.absent() : Value(type),options: options == null && nullToAbsent ? const Value.absent() : Value(options),correctAnswer: correctAnswer == null && nullToAbsent ? const Value.absent() : Value(correctAnswer),explanation: explanation == null && nullToAbsent ? const Value.absent() : Value(explanation),bloomLevel: bloomLevel == null && nullToAbsent ? const Value.absent() : Value(bloomLevel),difficulty: difficulty == null && nullToAbsent ? const Value.absent() : Value(difficulty),active: Value(active),lastFetched: lastFetched == null && nullToAbsent ? const Value.absent() : Value(lastFetched),);
}
factory Question.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Question(id: serializer.fromJson<int>(json['id']),serverId: serializer.fromJson<int?>(json['serverId']),topicId: serializer.fromJson<int?>(json['topicId']),questionText: serializer.fromJson<String?>(json['questionText']),type: serializer.fromJson<String?>(json['type']),options: serializer.fromJson<String?>(json['options']),correctAnswer: serializer.fromJson<String?>(json['correctAnswer']),explanation: serializer.fromJson<String?>(json['explanation']),bloomLevel: serializer.fromJson<int?>(json['bloomLevel']),difficulty: serializer.fromJson<int?>(json['difficulty']),active: serializer.fromJson<bool>(json['active']),lastFetched: serializer.fromJson<DateTime?>(json['lastFetched']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'serverId': serializer.toJson<int?>(serverId),'topicId': serializer.toJson<int?>(topicId),'questionText': serializer.toJson<String?>(questionText),'type': serializer.toJson<String?>(type),'options': serializer.toJson<String?>(options),'correctAnswer': serializer.toJson<String?>(correctAnswer),'explanation': serializer.toJson<String?>(explanation),'bloomLevel': serializer.toJson<int?>(bloomLevel),'difficulty': serializer.toJson<int?>(difficulty),'active': serializer.toJson<bool>(active),'lastFetched': serializer.toJson<DateTime?>(lastFetched),};}Question copyWith({int? id,Value<int?> serverId = const Value.absent(),Value<int?> topicId = const Value.absent(),Value<String?> questionText = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> options = const Value.absent(),Value<String?> correctAnswer = const Value.absent(),Value<String?> explanation = const Value.absent(),Value<int?> bloomLevel = const Value.absent(),Value<int?> difficulty = const Value.absent(),bool? active,Value<DateTime?> lastFetched = const Value.absent()}) => Question(id: id ?? this.id,serverId: serverId.present ? serverId.value : this.serverId,topicId: topicId.present ? topicId.value : this.topicId,questionText: questionText.present ? questionText.value : this.questionText,type: type.present ? type.value : this.type,options: options.present ? options.value : this.options,correctAnswer: correctAnswer.present ? correctAnswer.value : this.correctAnswer,explanation: explanation.present ? explanation.value : this.explanation,bloomLevel: bloomLevel.present ? bloomLevel.value : this.bloomLevel,difficulty: difficulty.present ? difficulty.value : this.difficulty,active: active ?? this.active,lastFetched: lastFetched.present ? lastFetched.value : this.lastFetched,);Question copyWithCompanion(QuestionsCompanion data) {
return Question(
id: data.id.present ? data.id.value : this.id,serverId: data.serverId.present ? data.serverId.value : this.serverId,topicId: data.topicId.present ? data.topicId.value : this.topicId,questionText: data.questionText.present ? data.questionText.value : this.questionText,type: data.type.present ? data.type.value : this.type,options: data.options.present ? data.options.value : this.options,correctAnswer: data.correctAnswer.present ? data.correctAnswer.value : this.correctAnswer,explanation: data.explanation.present ? data.explanation.value : this.explanation,bloomLevel: data.bloomLevel.present ? data.bloomLevel.value : this.bloomLevel,difficulty: data.difficulty.present ? data.difficulty.value : this.difficulty,active: data.active.present ? data.active.value : this.active,lastFetched: data.lastFetched.present ? data.lastFetched.value : this.lastFetched,);
}
@override
String toString() {return (StringBuffer('Question(')..write('id: $id, ')..write('serverId: $serverId, ')..write('topicId: $topicId, ')..write('questionText: $questionText, ')..write('type: $type, ')..write('options: $options, ')..write('correctAnswer: $correctAnswer, ')..write('explanation: $explanation, ')..write('bloomLevel: $bloomLevel, ')..write('difficulty: $difficulty, ')..write('active: $active, ')..write('lastFetched: $lastFetched')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, serverId, topicId, questionText, type, options, correctAnswer, explanation, bloomLevel, difficulty, active, lastFetched);@override
bool operator ==(Object other) => identical(this, other) || (other is Question && other.id == this.id && other.serverId == this.serverId && other.topicId == this.topicId && other.questionText == this.questionText && other.type == this.type && other.options == this.options && other.correctAnswer == this.correctAnswer && other.explanation == this.explanation && other.bloomLevel == this.bloomLevel && other.difficulty == this.difficulty && other.active == this.active && other.lastFetched == this.lastFetched);
}class QuestionsCompanion extends UpdateCompanion<Question> {
final Value<int> id;
final Value<int?> serverId;
final Value<int?> topicId;
final Value<String?> questionText;
final Value<String?> type;
final Value<String?> options;
final Value<String?> correctAnswer;
final Value<String?> explanation;
final Value<int?> bloomLevel;
final Value<int?> difficulty;
final Value<bool> active;
final Value<DateTime?> lastFetched;
const QuestionsCompanion({this.id = const Value.absent(),this.serverId = const Value.absent(),this.topicId = const Value.absent(),this.questionText = const Value.absent(),this.type = const Value.absent(),this.options = const Value.absent(),this.correctAnswer = const Value.absent(),this.explanation = const Value.absent(),this.bloomLevel = const Value.absent(),this.difficulty = const Value.absent(),this.active = const Value.absent(),this.lastFetched = const Value.absent(),});
QuestionsCompanion.insert({this.id = const Value.absent(),this.serverId = const Value.absent(),this.topicId = const Value.absent(),this.questionText = const Value.absent(),this.type = const Value.absent(),this.options = const Value.absent(),this.correctAnswer = const Value.absent(),this.explanation = const Value.absent(),this.bloomLevel = const Value.absent(),this.difficulty = const Value.absent(),this.active = const Value.absent(),this.lastFetched = const Value.absent(),});
static Insertable<Question> custom({Expression<int>? id, 
Expression<int>? serverId, 
Expression<int>? topicId, 
Expression<String>? questionText, 
Expression<String>? type, 
Expression<String>? options, 
Expression<String>? correctAnswer, 
Expression<String>? explanation, 
Expression<int>? bloomLevel, 
Expression<int>? difficulty, 
Expression<bool>? active, 
Expression<DateTime>? lastFetched, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (serverId != null)'server_id': serverId,if (topicId != null)'topic_id': topicId,if (questionText != null)'question_text': questionText,if (type != null)'type': type,if (options != null)'options': options,if (correctAnswer != null)'correct_answer': correctAnswer,if (explanation != null)'explanation': explanation,if (bloomLevel != null)'bloom_level': bloomLevel,if (difficulty != null)'difficulty': difficulty,if (active != null)'active': active,if (lastFetched != null)'last_fetched': lastFetched,});
}QuestionsCompanion copyWith({Value<int>? id, Value<int?>? serverId, Value<int?>? topicId, Value<String?>? questionText, Value<String?>? type, Value<String?>? options, Value<String?>? correctAnswer, Value<String?>? explanation, Value<int?>? bloomLevel, Value<int?>? difficulty, Value<bool>? active, Value<DateTime?>? lastFetched}) {
return QuestionsCompanion(id: id ?? this.id,serverId: serverId ?? this.serverId,topicId: topicId ?? this.topicId,questionText: questionText ?? this.questionText,type: type ?? this.type,options: options ?? this.options,correctAnswer: correctAnswer ?? this.correctAnswer,explanation: explanation ?? this.explanation,bloomLevel: bloomLevel ?? this.bloomLevel,difficulty: difficulty ?? this.difficulty,active: active ?? this.active,lastFetched: lastFetched ?? this.lastFetched,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (serverId.present) {
map['server_id'] = Variable<int>(serverId.value);}
if (topicId.present) {
map['topic_id'] = Variable<int>(topicId.value);}
if (questionText.present) {
map['question_text'] = Variable<String>(questionText.value);}
if (type.present) {
map['type'] = Variable<String>(type.value);}
if (options.present) {
map['options'] = Variable<String>(options.value);}
if (correctAnswer.present) {
map['correct_answer'] = Variable<String>(correctAnswer.value);}
if (explanation.present) {
map['explanation'] = Variable<String>(explanation.value);}
if (bloomLevel.present) {
map['bloom_level'] = Variable<int>(bloomLevel.value);}
if (difficulty.present) {
map['difficulty'] = Variable<int>(difficulty.value);}
if (active.present) {
map['active'] = Variable<bool>(active.value);}
if (lastFetched.present) {
map['last_fetched'] = Variable<DateTime>(lastFetched.value);}
return map; 
}
@override
String toString() {return (StringBuffer('QuestionsCompanion(')..write('id: $id, ')..write('serverId: $serverId, ')..write('topicId: $topicId, ')..write('questionText: $questionText, ')..write('type: $type, ')..write('options: $options, ')..write('correctAnswer: $correctAnswer, ')..write('explanation: $explanation, ')..write('bloomLevel: $bloomLevel, ')..write('difficulty: $difficulty, ')..write('active: $active, ')..write('lastFetched: $lastFetched')..write(')')).toString();}
}
class $TopicProgressTable extends TopicProgress with TableInfo<$TopicProgressTable, TopicProgressData>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$TopicProgressTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
@override
late final GeneratedColumn<int> userId = GeneratedColumn<int>('user_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _topicSlugMeta = const VerificationMeta('topicSlug');
@override
late final GeneratedColumn<String> topicSlug = GeneratedColumn<String>('topic_slug', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _currentBloomLevelMeta = const VerificationMeta('currentBloomLevel');
@override
late final GeneratedColumn<int> currentBloomLevel = GeneratedColumn<int>('current_bloom_level', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(1));
static const VerificationMeta _currentStreakMeta = const VerificationMeta('currentStreak');
@override
late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>('current_streak', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _consecutiveWrongMeta = const VerificationMeta('consecutiveWrong');
@override
late final GeneratedColumn<int> consecutiveWrong = GeneratedColumn<int>('consecutive_wrong', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _totalAnsweredMeta = const VerificationMeta('totalAnswered');
@override
late final GeneratedColumn<int> totalAnswered = GeneratedColumn<int>('total_answered', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _correctAnsweredMeta = const VerificationMeta('correctAnswered');
@override
late final GeneratedColumn<int> correctAnswered = GeneratedColumn<int>('correct_answered', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _masteryScoreMeta = const VerificationMeta('masteryScore');
@override
late final GeneratedColumn<int> masteryScore = GeneratedColumn<int>('mastery_score', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _unlockedBloomLevelMeta = const VerificationMeta('unlockedBloomLevel');
@override
late final GeneratedColumn<int> unlockedBloomLevel = GeneratedColumn<int>('unlocked_bloom_level', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(1));
static const VerificationMeta _questionsMasteredMeta = const VerificationMeta('questionsMastered');
@override
late final GeneratedColumn<int> questionsMastered = GeneratedColumn<int>('questions_mastered', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _lastStudiedAtMeta = const VerificationMeta('lastStudiedAt');
@override
late final GeneratedColumn<DateTime> lastStudiedAt = GeneratedColumn<DateTime>('last_studied_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
static const VerificationMeta _isDirtyMeta = const VerificationMeta('isDirty');
@override
late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>('is_dirty', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_dirty" IN (0, 1))'), defaultValue: const Constant(false));
@override
List<GeneratedColumn> get $columns => [id, userId, topicSlug, currentBloomLevel, currentStreak, consecutiveWrong, totalAnswered, correctAnswered, masteryScore, unlockedBloomLevel, questionsMastered, lastStudiedAt, isDirty];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'topic_progress';
@override
VerificationContext validateIntegrity(Insertable<TopicProgressData> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('user_id')) {
context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));}if (data.containsKey('topic_slug')) {
context.handle(_topicSlugMeta, topicSlug.isAcceptableOrUnknown(data['topic_slug']!, _topicSlugMeta));}if (data.containsKey('current_bloom_level')) {
context.handle(_currentBloomLevelMeta, currentBloomLevel.isAcceptableOrUnknown(data['current_bloom_level']!, _currentBloomLevelMeta));}if (data.containsKey('current_streak')) {
context.handle(_currentStreakMeta, currentStreak.isAcceptableOrUnknown(data['current_streak']!, _currentStreakMeta));}if (data.containsKey('consecutive_wrong')) {
context.handle(_consecutiveWrongMeta, consecutiveWrong.isAcceptableOrUnknown(data['consecutive_wrong']!, _consecutiveWrongMeta));}if (data.containsKey('total_answered')) {
context.handle(_totalAnsweredMeta, totalAnswered.isAcceptableOrUnknown(data['total_answered']!, _totalAnsweredMeta));}if (data.containsKey('correct_answered')) {
context.handle(_correctAnsweredMeta, correctAnswered.isAcceptableOrUnknown(data['correct_answered']!, _correctAnsweredMeta));}if (data.containsKey('mastery_score')) {
context.handle(_masteryScoreMeta, masteryScore.isAcceptableOrUnknown(data['mastery_score']!, _masteryScoreMeta));}if (data.containsKey('unlocked_bloom_level')) {
context.handle(_unlockedBloomLevelMeta, unlockedBloomLevel.isAcceptableOrUnknown(data['unlocked_bloom_level']!, _unlockedBloomLevelMeta));}if (data.containsKey('questions_mastered')) {
context.handle(_questionsMasteredMeta, questionsMastered.isAcceptableOrUnknown(data['questions_mastered']!, _questionsMasteredMeta));}if (data.containsKey('last_studied_at')) {
context.handle(_lastStudiedAtMeta, lastStudiedAt.isAcceptableOrUnknown(data['last_studied_at']!, _lastStudiedAtMeta));}if (data.containsKey('is_dirty')) {
context.handle(_isDirtyMeta, isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override
List<Set<GeneratedColumn>> get uniqueKeys => [{userId, topicSlug},
];
@override TopicProgressData map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return TopicProgressData(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, userId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}user_id']), topicSlug: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}topic_slug']), currentBloomLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}current_bloom_level'])!, currentStreak: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!, consecutiveWrong: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}consecutive_wrong'])!, totalAnswered: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total_answered'])!, correctAnswered: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_answered'])!, masteryScore: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}mastery_score'])!, unlockedBloomLevel: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}unlocked_bloom_level'])!, questionsMastered: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}questions_mastered'])!, lastStudiedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_studied_at']), isDirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_dirty'])!, );
}
@override
$TopicProgressTable createAlias(String alias) {
return $TopicProgressTable(attachedDatabase, alias);}}class TopicProgressData extends DataClass implements Insertable<TopicProgressData> 
{
final int id;
final int? userId;
final String? topicSlug;
final int currentBloomLevel;
final int currentStreak;
final int consecutiveWrong;
final int totalAnswered;
final int correctAnswered;
final int masteryScore;
final int unlockedBloomLevel;
final int questionsMastered;
final DateTime? lastStudiedAt;
final bool isDirty;
const TopicProgressData({required this.id, this.userId, this.topicSlug, required this.currentBloomLevel, required this.currentStreak, required this.consecutiveWrong, required this.totalAnswered, required this.correctAnswered, required this.masteryScore, required this.unlockedBloomLevel, required this.questionsMastered, this.lastStudiedAt, required this.isDirty});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || userId != null){map['user_id'] = Variable<int>(userId);
}if (!nullToAbsent || topicSlug != null){map['topic_slug'] = Variable<String>(topicSlug);
}map['current_bloom_level'] = Variable<int>(currentBloomLevel);
map['current_streak'] = Variable<int>(currentStreak);
map['consecutive_wrong'] = Variable<int>(consecutiveWrong);
map['total_answered'] = Variable<int>(totalAnswered);
map['correct_answered'] = Variable<int>(correctAnswered);
map['mastery_score'] = Variable<int>(masteryScore);
map['unlocked_bloom_level'] = Variable<int>(unlockedBloomLevel);
map['questions_mastered'] = Variable<int>(questionsMastered);
if (!nullToAbsent || lastStudiedAt != null){map['last_studied_at'] = Variable<DateTime>(lastStudiedAt);
}map['is_dirty'] = Variable<bool>(isDirty);
return map; 
}
TopicProgressCompanion toCompanion(bool nullToAbsent) {
return TopicProgressCompanion(id: Value(id),userId: userId == null && nullToAbsent ? const Value.absent() : Value(userId),topicSlug: topicSlug == null && nullToAbsent ? const Value.absent() : Value(topicSlug),currentBloomLevel: Value(currentBloomLevel),currentStreak: Value(currentStreak),consecutiveWrong: Value(consecutiveWrong),totalAnswered: Value(totalAnswered),correctAnswered: Value(correctAnswered),masteryScore: Value(masteryScore),unlockedBloomLevel: Value(unlockedBloomLevel),questionsMastered: Value(questionsMastered),lastStudiedAt: lastStudiedAt == null && nullToAbsent ? const Value.absent() : Value(lastStudiedAt),isDirty: Value(isDirty),);
}
factory TopicProgressData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return TopicProgressData(id: serializer.fromJson<int>(json['id']),userId: serializer.fromJson<int?>(json['userId']),topicSlug: serializer.fromJson<String?>(json['topicSlug']),currentBloomLevel: serializer.fromJson<int>(json['currentBloomLevel']),currentStreak: serializer.fromJson<int>(json['currentStreak']),consecutiveWrong: serializer.fromJson<int>(json['consecutiveWrong']),totalAnswered: serializer.fromJson<int>(json['totalAnswered']),correctAnswered: serializer.fromJson<int>(json['correctAnswered']),masteryScore: serializer.fromJson<int>(json['masteryScore']),unlockedBloomLevel: serializer.fromJson<int>(json['unlockedBloomLevel']),questionsMastered: serializer.fromJson<int>(json['questionsMastered']),lastStudiedAt: serializer.fromJson<DateTime?>(json['lastStudiedAt']),isDirty: serializer.fromJson<bool>(json['isDirty']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'userId': serializer.toJson<int?>(userId),'topicSlug': serializer.toJson<String?>(topicSlug),'currentBloomLevel': serializer.toJson<int>(currentBloomLevel),'currentStreak': serializer.toJson<int>(currentStreak),'consecutiveWrong': serializer.toJson<int>(consecutiveWrong),'totalAnswered': serializer.toJson<int>(totalAnswered),'correctAnswered': serializer.toJson<int>(correctAnswered),'masteryScore': serializer.toJson<int>(masteryScore),'unlockedBloomLevel': serializer.toJson<int>(unlockedBloomLevel),'questionsMastered': serializer.toJson<int>(questionsMastered),'lastStudiedAt': serializer.toJson<DateTime?>(lastStudiedAt),'isDirty': serializer.toJson<bool>(isDirty),};}TopicProgressData copyWith({int? id,Value<int?> userId = const Value.absent(),Value<String?> topicSlug = const Value.absent(),int? currentBloomLevel,int? currentStreak,int? consecutiveWrong,int? totalAnswered,int? correctAnswered,int? masteryScore,int? unlockedBloomLevel,int? questionsMastered,Value<DateTime?> lastStudiedAt = const Value.absent(),bool? isDirty}) => TopicProgressData(id: id ?? this.id,userId: userId.present ? userId.value : this.userId,topicSlug: topicSlug.present ? topicSlug.value : this.topicSlug,currentBloomLevel: currentBloomLevel ?? this.currentBloomLevel,currentStreak: currentStreak ?? this.currentStreak,consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,totalAnswered: totalAnswered ?? this.totalAnswered,correctAnswered: correctAnswered ?? this.correctAnswered,masteryScore: masteryScore ?? this.masteryScore,unlockedBloomLevel: unlockedBloomLevel ?? this.unlockedBloomLevel,questionsMastered: questionsMastered ?? this.questionsMastered,lastStudiedAt: lastStudiedAt.present ? lastStudiedAt.value : this.lastStudiedAt,isDirty: isDirty ?? this.isDirty,);TopicProgressData copyWithCompanion(TopicProgressCompanion data) {
return TopicProgressData(
id: data.id.present ? data.id.value : this.id,userId: data.userId.present ? data.userId.value : this.userId,topicSlug: data.topicSlug.present ? data.topicSlug.value : this.topicSlug,currentBloomLevel: data.currentBloomLevel.present ? data.currentBloomLevel.value : this.currentBloomLevel,currentStreak: data.currentStreak.present ? data.currentStreak.value : this.currentStreak,consecutiveWrong: data.consecutiveWrong.present ? data.consecutiveWrong.value : this.consecutiveWrong,totalAnswered: data.totalAnswered.present ? data.totalAnswered.value : this.totalAnswered,correctAnswered: data.correctAnswered.present ? data.correctAnswered.value : this.correctAnswered,masteryScore: data.masteryScore.present ? data.masteryScore.value : this.masteryScore,unlockedBloomLevel: data.unlockedBloomLevel.present ? data.unlockedBloomLevel.value : this.unlockedBloomLevel,questionsMastered: data.questionsMastered.present ? data.questionsMastered.value : this.questionsMastered,lastStudiedAt: data.lastStudiedAt.present ? data.lastStudiedAt.value : this.lastStudiedAt,isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,);
}
@override
String toString() {return (StringBuffer('TopicProgressData(')..write('id: $id, ')..write('userId: $userId, ')..write('topicSlug: $topicSlug, ')..write('currentBloomLevel: $currentBloomLevel, ')..write('currentStreak: $currentStreak, ')..write('consecutiveWrong: $consecutiveWrong, ')..write('totalAnswered: $totalAnswered, ')..write('correctAnswered: $correctAnswered, ')..write('masteryScore: $masteryScore, ')..write('unlockedBloomLevel: $unlockedBloomLevel, ')..write('questionsMastered: $questionsMastered, ')..write('lastStudiedAt: $lastStudiedAt, ')..write('isDirty: $isDirty')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, userId, topicSlug, currentBloomLevel, currentStreak, consecutiveWrong, totalAnswered, correctAnswered, masteryScore, unlockedBloomLevel, questionsMastered, lastStudiedAt, isDirty);@override
bool operator ==(Object other) => identical(this, other) || (other is TopicProgressData && other.id == this.id && other.userId == this.userId && other.topicSlug == this.topicSlug && other.currentBloomLevel == this.currentBloomLevel && other.currentStreak == this.currentStreak && other.consecutiveWrong == this.consecutiveWrong && other.totalAnswered == this.totalAnswered && other.correctAnswered == this.correctAnswered && other.masteryScore == this.masteryScore && other.unlockedBloomLevel == this.unlockedBloomLevel && other.questionsMastered == this.questionsMastered && other.lastStudiedAt == this.lastStudiedAt && other.isDirty == this.isDirty);
}class TopicProgressCompanion extends UpdateCompanion<TopicProgressData> {
final Value<int> id;
final Value<int?> userId;
final Value<String?> topicSlug;
final Value<int> currentBloomLevel;
final Value<int> currentStreak;
final Value<int> consecutiveWrong;
final Value<int> totalAnswered;
final Value<int> correctAnswered;
final Value<int> masteryScore;
final Value<int> unlockedBloomLevel;
final Value<int> questionsMastered;
final Value<DateTime?> lastStudiedAt;
final Value<bool> isDirty;
const TopicProgressCompanion({this.id = const Value.absent(),this.userId = const Value.absent(),this.topicSlug = const Value.absent(),this.currentBloomLevel = const Value.absent(),this.currentStreak = const Value.absent(),this.consecutiveWrong = const Value.absent(),this.totalAnswered = const Value.absent(),this.correctAnswered = const Value.absent(),this.masteryScore = const Value.absent(),this.unlockedBloomLevel = const Value.absent(),this.questionsMastered = const Value.absent(),this.lastStudiedAt = const Value.absent(),this.isDirty = const Value.absent(),});
TopicProgressCompanion.insert({this.id = const Value.absent(),this.userId = const Value.absent(),this.topicSlug = const Value.absent(),this.currentBloomLevel = const Value.absent(),this.currentStreak = const Value.absent(),this.consecutiveWrong = const Value.absent(),this.totalAnswered = const Value.absent(),this.correctAnswered = const Value.absent(),this.masteryScore = const Value.absent(),this.unlockedBloomLevel = const Value.absent(),this.questionsMastered = const Value.absent(),this.lastStudiedAt = const Value.absent(),this.isDirty = const Value.absent(),});
static Insertable<TopicProgressData> custom({Expression<int>? id, 
Expression<int>? userId, 
Expression<String>? topicSlug, 
Expression<int>? currentBloomLevel, 
Expression<int>? currentStreak, 
Expression<int>? consecutiveWrong, 
Expression<int>? totalAnswered, 
Expression<int>? correctAnswered, 
Expression<int>? masteryScore, 
Expression<int>? unlockedBloomLevel, 
Expression<int>? questionsMastered, 
Expression<DateTime>? lastStudiedAt, 
Expression<bool>? isDirty, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (userId != null)'user_id': userId,if (topicSlug != null)'topic_slug': topicSlug,if (currentBloomLevel != null)'current_bloom_level': currentBloomLevel,if (currentStreak != null)'current_streak': currentStreak,if (consecutiveWrong != null)'consecutive_wrong': consecutiveWrong,if (totalAnswered != null)'total_answered': totalAnswered,if (correctAnswered != null)'correct_answered': correctAnswered,if (masteryScore != null)'mastery_score': masteryScore,if (unlockedBloomLevel != null)'unlocked_bloom_level': unlockedBloomLevel,if (questionsMastered != null)'questions_mastered': questionsMastered,if (lastStudiedAt != null)'last_studied_at': lastStudiedAt,if (isDirty != null)'is_dirty': isDirty,});
}TopicProgressCompanion copyWith({Value<int>? id, Value<int?>? userId, Value<String?>? topicSlug, Value<int>? currentBloomLevel, Value<int>? currentStreak, Value<int>? consecutiveWrong, Value<int>? totalAnswered, Value<int>? correctAnswered, Value<int>? masteryScore, Value<int>? unlockedBloomLevel, Value<int>? questionsMastered, Value<DateTime?>? lastStudiedAt, Value<bool>? isDirty}) {
return TopicProgressCompanion(id: id ?? this.id,userId: userId ?? this.userId,topicSlug: topicSlug ?? this.topicSlug,currentBloomLevel: currentBloomLevel ?? this.currentBloomLevel,currentStreak: currentStreak ?? this.currentStreak,consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,totalAnswered: totalAnswered ?? this.totalAnswered,correctAnswered: correctAnswered ?? this.correctAnswered,masteryScore: masteryScore ?? this.masteryScore,unlockedBloomLevel: unlockedBloomLevel ?? this.unlockedBloomLevel,questionsMastered: questionsMastered ?? this.questionsMastered,lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,isDirty: isDirty ?? this.isDirty,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (userId.present) {
map['user_id'] = Variable<int>(userId.value);}
if (topicSlug.present) {
map['topic_slug'] = Variable<String>(topicSlug.value);}
if (currentBloomLevel.present) {
map['current_bloom_level'] = Variable<int>(currentBloomLevel.value);}
if (currentStreak.present) {
map['current_streak'] = Variable<int>(currentStreak.value);}
if (consecutiveWrong.present) {
map['consecutive_wrong'] = Variable<int>(consecutiveWrong.value);}
if (totalAnswered.present) {
map['total_answered'] = Variable<int>(totalAnswered.value);}
if (correctAnswered.present) {
map['correct_answered'] = Variable<int>(correctAnswered.value);}
if (masteryScore.present) {
map['mastery_score'] = Variable<int>(masteryScore.value);}
if (unlockedBloomLevel.present) {
map['unlocked_bloom_level'] = Variable<int>(unlockedBloomLevel.value);}
if (questionsMastered.present) {
map['questions_mastered'] = Variable<int>(questionsMastered.value);}
if (lastStudiedAt.present) {
map['last_studied_at'] = Variable<DateTime>(lastStudiedAt.value);}
if (isDirty.present) {
map['is_dirty'] = Variable<bool>(isDirty.value);}
return map; 
}
@override
String toString() {return (StringBuffer('TopicProgressCompanion(')..write('id: $id, ')..write('userId: $userId, ')..write('topicSlug: $topicSlug, ')..write('currentBloomLevel: $currentBloomLevel, ')..write('currentStreak: $currentStreak, ')..write('consecutiveWrong: $consecutiveWrong, ')..write('totalAnswered: $totalAnswered, ')..write('correctAnswered: $correctAnswered, ')..write('masteryScore: $masteryScore, ')..write('unlockedBloomLevel: $unlockedBloomLevel, ')..write('questionsMastered: $questionsMastered, ')..write('lastStudiedAt: $lastStudiedAt, ')..write('isDirty: $isDirty')..write(')')).toString();}
}
class $QuestionProgressTable extends QuestionProgress with TableInfo<$QuestionProgressTable, QuestionProgressData>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$QuestionProgressTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
@override
late final GeneratedColumn<int> userId = GeneratedColumn<int>('user_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _questionIdMeta = const VerificationMeta('questionId');
@override
late final GeneratedColumn<int> questionId = GeneratedColumn<int>('question_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _boxMeta = const VerificationMeta('box');
@override
late final GeneratedColumn<int> box = GeneratedColumn<int>('box', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _consecutiveCorrectMeta = const VerificationMeta('consecutiveCorrect');
@override
late final GeneratedColumn<int> consecutiveCorrect = GeneratedColumn<int>('consecutive_correct', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
static const VerificationMeta _masteredMeta = const VerificationMeta('mastered');
@override
late final GeneratedColumn<bool> mastered = GeneratedColumn<bool>('mastered', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("mastered" IN (0, 1))'), defaultValue: const Constant(false));
static const VerificationMeta _nextReviewAtMeta = const VerificationMeta('nextReviewAt');
@override
late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>('next_review_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
static const VerificationMeta _lastAnsweredAtMeta = const VerificationMeta('lastAnsweredAt');
@override
late final GeneratedColumn<DateTime> lastAnsweredAt = GeneratedColumn<DateTime>('last_answered_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
@override
late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>('updated_at', aliasedName, true, type: DriftSqlType.dateTime, requiredDuringInsert: false);
static const VerificationMeta _isDirtyMeta = const VerificationMeta('isDirty');
@override
late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>('is_dirty', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_dirty" IN (0, 1))'), defaultValue: const Constant(false));
@override
List<GeneratedColumn> get $columns => [id, userId, questionId, box, consecutiveCorrect, mastered, nextReviewAt, lastAnsweredAt, updatedAt, isDirty];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'question_progress';
@override
VerificationContext validateIntegrity(Insertable<QuestionProgressData> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('user_id')) {
context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));}if (data.containsKey('question_id')) {
context.handle(_questionIdMeta, questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta));}if (data.containsKey('box')) {
context.handle(_boxMeta, box.isAcceptableOrUnknown(data['box']!, _boxMeta));}if (data.containsKey('consecutive_correct')) {
context.handle(_consecutiveCorrectMeta, consecutiveCorrect.isAcceptableOrUnknown(data['consecutive_correct']!, _consecutiveCorrectMeta));}if (data.containsKey('mastered')) {
context.handle(_masteredMeta, mastered.isAcceptableOrUnknown(data['mastered']!, _masteredMeta));}if (data.containsKey('next_review_at')) {
context.handle(_nextReviewAtMeta, nextReviewAt.isAcceptableOrUnknown(data['next_review_at']!, _nextReviewAtMeta));}if (data.containsKey('last_answered_at')) {
context.handle(_lastAnsweredAtMeta, lastAnsweredAt.isAcceptableOrUnknown(data['last_answered_at']!, _lastAnsweredAtMeta));}if (data.containsKey('updated_at')) {
context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));}if (data.containsKey('is_dirty')) {
context.handle(_isDirtyMeta, isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override
List<Set<GeneratedColumn>> get uniqueKeys => [{userId, questionId},
];
@override QuestionProgressData map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return QuestionProgressData(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, userId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}user_id']), questionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}question_id']), box: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}box'])!, consecutiveCorrect: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}consecutive_correct'])!, mastered: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}mastered'])!, nextReviewAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}next_review_at']), lastAnsweredAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_answered_at']), updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']), isDirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_dirty'])!, );
}
@override
$QuestionProgressTable createAlias(String alias) {
return $QuestionProgressTable(attachedDatabase, alias);}}class QuestionProgressData extends DataClass implements Insertable<QuestionProgressData> 
{
final int id;
final int? userId;
final int? questionId;
final int box;
final int consecutiveCorrect;
final bool mastered;
final DateTime? nextReviewAt;
final DateTime? lastAnsweredAt;
final DateTime? updatedAt;
final bool isDirty;
const QuestionProgressData({required this.id, this.userId, this.questionId, required this.box, required this.consecutiveCorrect, required this.mastered, this.nextReviewAt, this.lastAnsweredAt, this.updatedAt, required this.isDirty});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || userId != null){map['user_id'] = Variable<int>(userId);
}if (!nullToAbsent || questionId != null){map['question_id'] = Variable<int>(questionId);
}map['box'] = Variable<int>(box);
map['consecutive_correct'] = Variable<int>(consecutiveCorrect);
map['mastered'] = Variable<bool>(mastered);
if (!nullToAbsent || nextReviewAt != null){map['next_review_at'] = Variable<DateTime>(nextReviewAt);
}if (!nullToAbsent || lastAnsweredAt != null){map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt);
}if (!nullToAbsent || updatedAt != null){map['updated_at'] = Variable<DateTime>(updatedAt);
}map['is_dirty'] = Variable<bool>(isDirty);
return map; 
}
QuestionProgressCompanion toCompanion(bool nullToAbsent) {
return QuestionProgressCompanion(id: Value(id),userId: userId == null && nullToAbsent ? const Value.absent() : Value(userId),questionId: questionId == null && nullToAbsent ? const Value.absent() : Value(questionId),box: Value(box),consecutiveCorrect: Value(consecutiveCorrect),mastered: Value(mastered),nextReviewAt: nextReviewAt == null && nullToAbsent ? const Value.absent() : Value(nextReviewAt),lastAnsweredAt: lastAnsweredAt == null && nullToAbsent ? const Value.absent() : Value(lastAnsweredAt),updatedAt: updatedAt == null && nullToAbsent ? const Value.absent() : Value(updatedAt),isDirty: Value(isDirty),);
}
factory QuestionProgressData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return QuestionProgressData(id: serializer.fromJson<int>(json['id']),userId: serializer.fromJson<int?>(json['userId']),questionId: serializer.fromJson<int?>(json['questionId']),box: serializer.fromJson<int>(json['box']),consecutiveCorrect: serializer.fromJson<int>(json['consecutiveCorrect']),mastered: serializer.fromJson<bool>(json['mastered']),nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),lastAnsweredAt: serializer.fromJson<DateTime?>(json['lastAnsweredAt']),updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),isDirty: serializer.fromJson<bool>(json['isDirty']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'userId': serializer.toJson<int?>(userId),'questionId': serializer.toJson<int?>(questionId),'box': serializer.toJson<int>(box),'consecutiveCorrect': serializer.toJson<int>(consecutiveCorrect),'mastered': serializer.toJson<bool>(mastered),'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),'lastAnsweredAt': serializer.toJson<DateTime?>(lastAnsweredAt),'updatedAt': serializer.toJson<DateTime?>(updatedAt),'isDirty': serializer.toJson<bool>(isDirty),};}QuestionProgressData copyWith({int? id,Value<int?> userId = const Value.absent(),Value<int?> questionId = const Value.absent(),int? box,int? consecutiveCorrect,bool? mastered,Value<DateTime?> nextReviewAt = const Value.absent(),Value<DateTime?> lastAnsweredAt = const Value.absent(),Value<DateTime?> updatedAt = const Value.absent(),bool? isDirty}) => QuestionProgressData(id: id ?? this.id,userId: userId.present ? userId.value : this.userId,questionId: questionId.present ? questionId.value : this.questionId,box: box ?? this.box,consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,mastered: mastered ?? this.mastered,nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,lastAnsweredAt: lastAnsweredAt.present ? lastAnsweredAt.value : this.lastAnsweredAt,updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,isDirty: isDirty ?? this.isDirty,);QuestionProgressData copyWithCompanion(QuestionProgressCompanion data) {
return QuestionProgressData(
id: data.id.present ? data.id.value : this.id,userId: data.userId.present ? data.userId.value : this.userId,questionId: data.questionId.present ? data.questionId.value : this.questionId,box: data.box.present ? data.box.value : this.box,consecutiveCorrect: data.consecutiveCorrect.present ? data.consecutiveCorrect.value : this.consecutiveCorrect,mastered: data.mastered.present ? data.mastered.value : this.mastered,nextReviewAt: data.nextReviewAt.present ? data.nextReviewAt.value : this.nextReviewAt,lastAnsweredAt: data.lastAnsweredAt.present ? data.lastAnsweredAt.value : this.lastAnsweredAt,updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,);
}
@override
String toString() {return (StringBuffer('QuestionProgressData(')..write('id: $id, ')..write('userId: $userId, ')..write('questionId: $questionId, ')..write('box: $box, ')..write('consecutiveCorrect: $consecutiveCorrect, ')..write('mastered: $mastered, ')..write('nextReviewAt: $nextReviewAt, ')..write('lastAnsweredAt: $lastAnsweredAt, ')..write('updatedAt: $updatedAt, ')..write('isDirty: $isDirty')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, userId, questionId, box, consecutiveCorrect, mastered, nextReviewAt, lastAnsweredAt, updatedAt, isDirty);@override
bool operator ==(Object other) => identical(this, other) || (other is QuestionProgressData && other.id == this.id && other.userId == this.userId && other.questionId == this.questionId && other.box == this.box && other.consecutiveCorrect == this.consecutiveCorrect && other.mastered == this.mastered && other.nextReviewAt == this.nextReviewAt && other.lastAnsweredAt == this.lastAnsweredAt && other.updatedAt == this.updatedAt && other.isDirty == this.isDirty);
}class QuestionProgressCompanion extends UpdateCompanion<QuestionProgressData> {
final Value<int> id;
final Value<int?> userId;
final Value<int?> questionId;
final Value<int> box;
final Value<int> consecutiveCorrect;
final Value<bool> mastered;
final Value<DateTime?> nextReviewAt;
final Value<DateTime?> lastAnsweredAt;
final Value<DateTime?> updatedAt;
final Value<bool> isDirty;
const QuestionProgressCompanion({this.id = const Value.absent(),this.userId = const Value.absent(),this.questionId = const Value.absent(),this.box = const Value.absent(),this.consecutiveCorrect = const Value.absent(),this.mastered = const Value.absent(),this.nextReviewAt = const Value.absent(),this.lastAnsweredAt = const Value.absent(),this.updatedAt = const Value.absent(),this.isDirty = const Value.absent(),});
QuestionProgressCompanion.insert({this.id = const Value.absent(),this.userId = const Value.absent(),this.questionId = const Value.absent(),this.box = const Value.absent(),this.consecutiveCorrect = const Value.absent(),this.mastered = const Value.absent(),this.nextReviewAt = const Value.absent(),this.lastAnsweredAt = const Value.absent(),this.updatedAt = const Value.absent(),this.isDirty = const Value.absent(),});
static Insertable<QuestionProgressData> custom({Expression<int>? id, 
Expression<int>? userId, 
Expression<int>? questionId, 
Expression<int>? box, 
Expression<int>? consecutiveCorrect, 
Expression<bool>? mastered, 
Expression<DateTime>? nextReviewAt, 
Expression<DateTime>? lastAnsweredAt, 
Expression<DateTime>? updatedAt, 
Expression<bool>? isDirty, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (userId != null)'user_id': userId,if (questionId != null)'question_id': questionId,if (box != null)'box': box,if (consecutiveCorrect != null)'consecutive_correct': consecutiveCorrect,if (mastered != null)'mastered': mastered,if (nextReviewAt != null)'next_review_at': nextReviewAt,if (lastAnsweredAt != null)'last_answered_at': lastAnsweredAt,if (updatedAt != null)'updated_at': updatedAt,if (isDirty != null)'is_dirty': isDirty,});
}QuestionProgressCompanion copyWith({Value<int>? id, Value<int?>? userId, Value<int?>? questionId, Value<int>? box, Value<int>? consecutiveCorrect, Value<bool>? mastered, Value<DateTime?>? nextReviewAt, Value<DateTime?>? lastAnsweredAt, Value<DateTime?>? updatedAt, Value<bool>? isDirty}) {
return QuestionProgressCompanion(id: id ?? this.id,userId: userId ?? this.userId,questionId: questionId ?? this.questionId,box: box ?? this.box,consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,mastered: mastered ?? this.mastered,nextReviewAt: nextReviewAt ?? this.nextReviewAt,lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,updatedAt: updatedAt ?? this.updatedAt,isDirty: isDirty ?? this.isDirty,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (userId.present) {
map['user_id'] = Variable<int>(userId.value);}
if (questionId.present) {
map['question_id'] = Variable<int>(questionId.value);}
if (box.present) {
map['box'] = Variable<int>(box.value);}
if (consecutiveCorrect.present) {
map['consecutive_correct'] = Variable<int>(consecutiveCorrect.value);}
if (mastered.present) {
map['mastered'] = Variable<bool>(mastered.value);}
if (nextReviewAt.present) {
map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);}
if (lastAnsweredAt.present) {
map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt.value);}
if (updatedAt.present) {
map['updated_at'] = Variable<DateTime>(updatedAt.value);}
if (isDirty.present) {
map['is_dirty'] = Variable<bool>(isDirty.value);}
return map; 
}
@override
String toString() {return (StringBuffer('QuestionProgressCompanion(')..write('id: $id, ')..write('userId: $userId, ')..write('questionId: $questionId, ')..write('box: $box, ')..write('consecutiveCorrect: $consecutiveCorrect, ')..write('mastered: $mastered, ')..write('nextReviewAt: $nextReviewAt, ')..write('lastAnsweredAt: $lastAnsweredAt, ')..write('updatedAt: $updatedAt, ')..write('isDirty: $isDirty')..write(')')).toString();}
}
class $ItemsTable extends Items with TableInfo<$ItemsTable, Item>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$ItemsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _serverIdMeta = const VerificationMeta('serverId');
@override
late final GeneratedColumn<int> serverId = GeneratedColumn<int>('server_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
static const VerificationMeta _nameMeta = const VerificationMeta('name');
@override
late final GeneratedColumn<String> name = GeneratedColumn<String>('name', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _typeMeta = const VerificationMeta('type');
@override
late final GeneratedColumn<String> type = GeneratedColumn<String>('type', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _slotTypeMeta = const VerificationMeta('slotType');
@override
late final GeneratedColumn<String> slotType = GeneratedColumn<String>('slot_type', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _priceMeta = const VerificationMeta('price');
@override
late final GeneratedColumn<int> price = GeneratedColumn<int>('price', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _assetPathMeta = const VerificationMeta('assetPath');
@override
late final GeneratedColumn<String> assetPath = GeneratedColumn<String>('asset_path', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
@override
late final GeneratedColumn<String> description = GeneratedColumn<String>('description', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _themeMeta = const VerificationMeta('theme');
@override
late final GeneratedColumn<String> theme = GeneratedColumn<String>('theme', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _isPremiumMeta = const VerificationMeta('isPremium');
@override
late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>('is_premium', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_premium" IN (0, 1))'), defaultValue: const Constant(false));
@override
List<GeneratedColumn> get $columns => [id, serverId, name, type, slotType, price, assetPath, description, theme, isPremium];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'items';
@override
VerificationContext validateIntegrity(Insertable<Item> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('server_id')) {
context.handle(_serverIdMeta, serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));}if (data.containsKey('name')) {
context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));}if (data.containsKey('type')) {
context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));}if (data.containsKey('slot_type')) {
context.handle(_slotTypeMeta, slotType.isAcceptableOrUnknown(data['slot_type']!, _slotTypeMeta));}if (data.containsKey('price')) {
context.handle(_priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));}if (data.containsKey('asset_path')) {
context.handle(_assetPathMeta, assetPath.isAcceptableOrUnknown(data['asset_path']!, _assetPathMeta));}if (data.containsKey('description')) {
context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));}if (data.containsKey('theme')) {
context.handle(_themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));}if (data.containsKey('is_premium')) {
context.handle(_isPremiumMeta, isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override Item map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return Item(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, serverId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}server_id']), name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name']), type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type']), slotType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}slot_type']), price: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}price']), assetPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}asset_path']), description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description']), theme: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}theme']), isPremium: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_premium'])!, );
}
@override
$ItemsTable createAlias(String alias) {
return $ItemsTable(attachedDatabase, alias);}}class Item extends DataClass implements Insertable<Item> 
{
final int id;
final int? serverId;
final String? name;
final String? type;
final String? slotType;
final int? price;
final String? assetPath;
final String? description;
final String? theme;
final bool isPremium;
const Item({required this.id, this.serverId, this.name, this.type, this.slotType, this.price, this.assetPath, this.description, this.theme, required this.isPremium});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || serverId != null){map['server_id'] = Variable<int>(serverId);
}if (!nullToAbsent || name != null){map['name'] = Variable<String>(name);
}if (!nullToAbsent || type != null){map['type'] = Variable<String>(type);
}if (!nullToAbsent || slotType != null){map['slot_type'] = Variable<String>(slotType);
}if (!nullToAbsent || price != null){map['price'] = Variable<int>(price);
}if (!nullToAbsent || assetPath != null){map['asset_path'] = Variable<String>(assetPath);
}if (!nullToAbsent || description != null){map['description'] = Variable<String>(description);
}if (!nullToAbsent || theme != null){map['theme'] = Variable<String>(theme);
}map['is_premium'] = Variable<bool>(isPremium);
return map; 
}
ItemsCompanion toCompanion(bool nullToAbsent) {
return ItemsCompanion(id: Value(id),serverId: serverId == null && nullToAbsent ? const Value.absent() : Value(serverId),name: name == null && nullToAbsent ? const Value.absent() : Value(name),type: type == null && nullToAbsent ? const Value.absent() : Value(type),slotType: slotType == null && nullToAbsent ? const Value.absent() : Value(slotType),price: price == null && nullToAbsent ? const Value.absent() : Value(price),assetPath: assetPath == null && nullToAbsent ? const Value.absent() : Value(assetPath),description: description == null && nullToAbsent ? const Value.absent() : Value(description),theme: theme == null && nullToAbsent ? const Value.absent() : Value(theme),isPremium: Value(isPremium),);
}
factory Item.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return Item(id: serializer.fromJson<int>(json['id']),serverId: serializer.fromJson<int?>(json['serverId']),name: serializer.fromJson<String?>(json['name']),type: serializer.fromJson<String?>(json['type']),slotType: serializer.fromJson<String?>(json['slotType']),price: serializer.fromJson<int?>(json['price']),assetPath: serializer.fromJson<String?>(json['assetPath']),description: serializer.fromJson<String?>(json['description']),theme: serializer.fromJson<String?>(json['theme']),isPremium: serializer.fromJson<bool>(json['isPremium']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'serverId': serializer.toJson<int?>(serverId),'name': serializer.toJson<String?>(name),'type': serializer.toJson<String?>(type),'slotType': serializer.toJson<String?>(slotType),'price': serializer.toJson<int?>(price),'assetPath': serializer.toJson<String?>(assetPath),'description': serializer.toJson<String?>(description),'theme': serializer.toJson<String?>(theme),'isPremium': serializer.toJson<bool>(isPremium),};}Item copyWith({int? id,Value<int?> serverId = const Value.absent(),Value<String?> name = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> slotType = const Value.absent(),Value<int?> price = const Value.absent(),Value<String?> assetPath = const Value.absent(),Value<String?> description = const Value.absent(),Value<String?> theme = const Value.absent(),bool? isPremium}) => Item(id: id ?? this.id,serverId: serverId.present ? serverId.value : this.serverId,name: name.present ? name.value : this.name,type: type.present ? type.value : this.type,slotType: slotType.present ? slotType.value : this.slotType,price: price.present ? price.value : this.price,assetPath: assetPath.present ? assetPath.value : this.assetPath,description: description.present ? description.value : this.description,theme: theme.present ? theme.value : this.theme,isPremium: isPremium ?? this.isPremium,);Item copyWithCompanion(ItemsCompanion data) {
return Item(
id: data.id.present ? data.id.value : this.id,serverId: data.serverId.present ? data.serverId.value : this.serverId,name: data.name.present ? data.name.value : this.name,type: data.type.present ? data.type.value : this.type,slotType: data.slotType.present ? data.slotType.value : this.slotType,price: data.price.present ? data.price.value : this.price,assetPath: data.assetPath.present ? data.assetPath.value : this.assetPath,description: data.description.present ? data.description.value : this.description,theme: data.theme.present ? data.theme.value : this.theme,isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,);
}
@override
String toString() {return (StringBuffer('Item(')..write('id: $id, ')..write('serverId: $serverId, ')..write('name: $name, ')..write('type: $type, ')..write('slotType: $slotType, ')..write('price: $price, ')..write('assetPath: $assetPath, ')..write('description: $description, ')..write('theme: $theme, ')..write('isPremium: $isPremium')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, serverId, name, type, slotType, price, assetPath, description, theme, isPremium);@override
bool operator ==(Object other) => identical(this, other) || (other is Item && other.id == this.id && other.serverId == this.serverId && other.name == this.name && other.type == this.type && other.slotType == this.slotType && other.price == this.price && other.assetPath == this.assetPath && other.description == this.description && other.theme == this.theme && other.isPremium == this.isPremium);
}class ItemsCompanion extends UpdateCompanion<Item> {
final Value<int> id;
final Value<int?> serverId;
final Value<String?> name;
final Value<String?> type;
final Value<String?> slotType;
final Value<int?> price;
final Value<String?> assetPath;
final Value<String?> description;
final Value<String?> theme;
final Value<bool> isPremium;
const ItemsCompanion({this.id = const Value.absent(),this.serverId = const Value.absent(),this.name = const Value.absent(),this.type = const Value.absent(),this.slotType = const Value.absent(),this.price = const Value.absent(),this.assetPath = const Value.absent(),this.description = const Value.absent(),this.theme = const Value.absent(),this.isPremium = const Value.absent(),});
ItemsCompanion.insert({this.id = const Value.absent(),this.serverId = const Value.absent(),this.name = const Value.absent(),this.type = const Value.absent(),this.slotType = const Value.absent(),this.price = const Value.absent(),this.assetPath = const Value.absent(),this.description = const Value.absent(),this.theme = const Value.absent(),this.isPremium = const Value.absent(),});
static Insertable<Item> custom({Expression<int>? id, 
Expression<int>? serverId, 
Expression<String>? name, 
Expression<String>? type, 
Expression<String>? slotType, 
Expression<int>? price, 
Expression<String>? assetPath, 
Expression<String>? description, 
Expression<String>? theme, 
Expression<bool>? isPremium, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (serverId != null)'server_id': serverId,if (name != null)'name': name,if (type != null)'type': type,if (slotType != null)'slot_type': slotType,if (price != null)'price': price,if (assetPath != null)'asset_path': assetPath,if (description != null)'description': description,if (theme != null)'theme': theme,if (isPremium != null)'is_premium': isPremium,});
}ItemsCompanion copyWith({Value<int>? id, Value<int?>? serverId, Value<String?>? name, Value<String?>? type, Value<String?>? slotType, Value<int?>? price, Value<String?>? assetPath, Value<String?>? description, Value<String?>? theme, Value<bool>? isPremium}) {
return ItemsCompanion(id: id ?? this.id,serverId: serverId ?? this.serverId,name: name ?? this.name,type: type ?? this.type,slotType: slotType ?? this.slotType,price: price ?? this.price,assetPath: assetPath ?? this.assetPath,description: description ?? this.description,theme: theme ?? this.theme,isPremium: isPremium ?? this.isPremium,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (serverId.present) {
map['server_id'] = Variable<int>(serverId.value);}
if (name.present) {
map['name'] = Variable<String>(name.value);}
if (type.present) {
map['type'] = Variable<String>(type.value);}
if (slotType.present) {
map['slot_type'] = Variable<String>(slotType.value);}
if (price.present) {
map['price'] = Variable<int>(price.value);}
if (assetPath.present) {
map['asset_path'] = Variable<String>(assetPath.value);}
if (description.present) {
map['description'] = Variable<String>(description.value);}
if (theme.present) {
map['theme'] = Variable<String>(theme.value);}
if (isPremium.present) {
map['is_premium'] = Variable<bool>(isPremium.value);}
return map; 
}
@override
String toString() {return (StringBuffer('ItemsCompanion(')..write('id: $id, ')..write('serverId: $serverId, ')..write('name: $name, ')..write('type: $type, ')..write('slotType: $slotType, ')..write('price: $price, ')..write('assetPath: $assetPath, ')..write('description: $description, ')..write('theme: $theme, ')..write('isPremium: $isPremium')..write(')')).toString();}
}
class $UserItemsTable extends UserItems with TableInfo<$UserItemsTable, UserItem>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$UserItemsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _serverIdMeta = const VerificationMeta('serverId');
@override
late final GeneratedColumn<int> serverId = GeneratedColumn<int>('server_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
@override
late final GeneratedColumn<int> userId = GeneratedColumn<int>('user_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
@override
late final GeneratedColumn<int> itemId = GeneratedColumn<int>('item_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _isPlacedMeta = const VerificationMeta('isPlaced');
@override
late final GeneratedColumn<bool> isPlaced = GeneratedColumn<bool>('is_placed', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_placed" IN (0, 1))'), defaultValue: const Constant(false));
static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
@override
late final GeneratedColumn<int> roomId = GeneratedColumn<int>('room_id', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _slotMeta = const VerificationMeta('slot');
@override
late final GeneratedColumn<String> slot = GeneratedColumn<String>('slot', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _xPosMeta = const VerificationMeta('xPos');
@override
late final GeneratedColumn<int> xPos = GeneratedColumn<int>('x_pos', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _yPosMeta = const VerificationMeta('yPos');
@override
late final GeneratedColumn<int> yPos = GeneratedColumn<int>('y_pos', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
static const VerificationMeta _isDirtyMeta = const VerificationMeta('isDirty');
@override
late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>('is_dirty', aliasedName, false, type: DriftSqlType.bool, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_dirty" IN (0, 1))'), defaultValue: const Constant(false));
@override
List<GeneratedColumn> get $columns => [id, serverId, userId, itemId, isPlaced, roomId, slot, xPos, yPos, isDirty];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'user_items';
@override
VerificationContext validateIntegrity(Insertable<UserItem> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('server_id')) {
context.handle(_serverIdMeta, serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));}if (data.containsKey('user_id')) {
context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));}if (data.containsKey('item_id')) {
context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));}if (data.containsKey('is_placed')) {
context.handle(_isPlacedMeta, isPlaced.isAcceptableOrUnknown(data['is_placed']!, _isPlacedMeta));}if (data.containsKey('room_id')) {
context.handle(_roomIdMeta, roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));}if (data.containsKey('slot')) {
context.handle(_slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));}if (data.containsKey('x_pos')) {
context.handle(_xPosMeta, xPos.isAcceptableOrUnknown(data['x_pos']!, _xPosMeta));}if (data.containsKey('y_pos')) {
context.handle(_yPosMeta, yPos.isAcceptableOrUnknown(data['y_pos']!, _yPosMeta));}if (data.containsKey('is_dirty')) {
context.handle(_isDirtyMeta, isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override UserItem map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return UserItem(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, serverId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}server_id']), userId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}user_id']), itemId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}item_id']), isPlaced: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_placed'])!, roomId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}room_id']), slot: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}slot']), xPos: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}x_pos']), yPos: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}y_pos']), isDirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_dirty'])!, );
}
@override
$UserItemsTable createAlias(String alias) {
return $UserItemsTable(attachedDatabase, alias);}}class UserItem extends DataClass implements Insertable<UserItem> 
{
final int id;
final int? serverId;
final int? userId;
final int? itemId;
final bool isPlaced;
final int? roomId;
final String? slot;
final int? xPos;
final int? yPos;
final bool isDirty;
const UserItem({required this.id, this.serverId, this.userId, this.itemId, required this.isPlaced, this.roomId, this.slot, this.xPos, this.yPos, required this.isDirty});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || serverId != null){map['server_id'] = Variable<int>(serverId);
}if (!nullToAbsent || userId != null){map['user_id'] = Variable<int>(userId);
}if (!nullToAbsent || itemId != null){map['item_id'] = Variable<int>(itemId);
}map['is_placed'] = Variable<bool>(isPlaced);
if (!nullToAbsent || roomId != null){map['room_id'] = Variable<int>(roomId);
}if (!nullToAbsent || slot != null){map['slot'] = Variable<String>(slot);
}if (!nullToAbsent || xPos != null){map['x_pos'] = Variable<int>(xPos);
}if (!nullToAbsent || yPos != null){map['y_pos'] = Variable<int>(yPos);
}map['is_dirty'] = Variable<bool>(isDirty);
return map; 
}
UserItemsCompanion toCompanion(bool nullToAbsent) {
return UserItemsCompanion(id: Value(id),serverId: serverId == null && nullToAbsent ? const Value.absent() : Value(serverId),userId: userId == null && nullToAbsent ? const Value.absent() : Value(userId),itemId: itemId == null && nullToAbsent ? const Value.absent() : Value(itemId),isPlaced: Value(isPlaced),roomId: roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),xPos: xPos == null && nullToAbsent ? const Value.absent() : Value(xPos),yPos: yPos == null && nullToAbsent ? const Value.absent() : Value(yPos),isDirty: Value(isDirty),);
}
factory UserItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return UserItem(id: serializer.fromJson<int>(json['id']),serverId: serializer.fromJson<int?>(json['serverId']),userId: serializer.fromJson<int?>(json['userId']),itemId: serializer.fromJson<int?>(json['itemId']),isPlaced: serializer.fromJson<bool>(json['isPlaced']),roomId: serializer.fromJson<int?>(json['roomId']),slot: serializer.fromJson<String?>(json['slot']),xPos: serializer.fromJson<int?>(json['xPos']),yPos: serializer.fromJson<int?>(json['yPos']),isDirty: serializer.fromJson<bool>(json['isDirty']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'serverId': serializer.toJson<int?>(serverId),'userId': serializer.toJson<int?>(userId),'itemId': serializer.toJson<int?>(itemId),'isPlaced': serializer.toJson<bool>(isPlaced),'roomId': serializer.toJson<int?>(roomId),'slot': serializer.toJson<String?>(slot),'xPos': serializer.toJson<int?>(xPos),'yPos': serializer.toJson<int?>(yPos),'isDirty': serializer.toJson<bool>(isDirty),};}UserItem copyWith({int? id,Value<int?> serverId = const Value.absent(),Value<int?> userId = const Value.absent(),Value<int?> itemId = const Value.absent(),bool? isPlaced,Value<int?> roomId = const Value.absent(),Value<String?> slot = const Value.absent(),Value<int?> xPos = const Value.absent(),Value<int?> yPos = const Value.absent(),bool? isDirty}) => UserItem(id: id ?? this.id,serverId: serverId.present ? serverId.value : this.serverId,userId: userId.present ? userId.value : this.userId,itemId: itemId.present ? itemId.value : this.itemId,isPlaced: isPlaced ?? this.isPlaced,roomId: roomId.present ? roomId.value : this.roomId,slot: slot.present ? slot.value : this.slot,xPos: xPos.present ? xPos.value : this.xPos,yPos: yPos.present ? yPos.value : this.yPos,isDirty: isDirty ?? this.isDirty,);UserItem copyWithCompanion(UserItemsCompanion data) {
return UserItem(
id: data.id.present ? data.id.value : this.id,serverId: data.serverId.present ? data.serverId.value : this.serverId,userId: data.userId.present ? data.userId.value : this.userId,itemId: data.itemId.present ? data.itemId.value : this.itemId,isPlaced: data.isPlaced.present ? data.isPlaced.value : this.isPlaced,roomId: data.roomId.present ? data.roomId.value : this.roomId,slot: data.slot.present ? data.slot.value : this.slot,xPos: data.xPos.present ? data.xPos.value : this.xPos,yPos: data.yPos.present ? data.yPos.value : this.yPos,isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,);
}
@override
String toString() {return (StringBuffer('UserItem(')..write('id: $id, ')..write('serverId: $serverId, ')..write('userId: $userId, ')..write('itemId: $itemId, ')..write('isPlaced: $isPlaced, ')..write('roomId: $roomId, ')..write('slot: $slot, ')..write('xPos: $xPos, ')..write('yPos: $yPos, ')..write('isDirty: $isDirty')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, serverId, userId, itemId, isPlaced, roomId, slot, xPos, yPos, isDirty);@override
bool operator ==(Object other) => identical(this, other) || (other is UserItem && other.id == this.id && other.serverId == this.serverId && other.userId == this.userId && other.itemId == this.itemId && other.isPlaced == this.isPlaced && other.roomId == this.roomId && other.slot == this.slot && other.xPos == this.xPos && other.yPos == this.yPos && other.isDirty == this.isDirty);
}class UserItemsCompanion extends UpdateCompanion<UserItem> {
final Value<int> id;
final Value<int?> serverId;
final Value<int?> userId;
final Value<int?> itemId;
final Value<bool> isPlaced;
final Value<int?> roomId;
final Value<String?> slot;
final Value<int?> xPos;
final Value<int?> yPos;
final Value<bool> isDirty;
const UserItemsCompanion({this.id = const Value.absent(),this.serverId = const Value.absent(),this.userId = const Value.absent(),this.itemId = const Value.absent(),this.isPlaced = const Value.absent(),this.roomId = const Value.absent(),this.slot = const Value.absent(),this.xPos = const Value.absent(),this.yPos = const Value.absent(),this.isDirty = const Value.absent(),});
UserItemsCompanion.insert({this.id = const Value.absent(),this.serverId = const Value.absent(),this.userId = const Value.absent(),this.itemId = const Value.absent(),this.isPlaced = const Value.absent(),this.roomId = const Value.absent(),this.slot = const Value.absent(),this.xPos = const Value.absent(),this.yPos = const Value.absent(),this.isDirty = const Value.absent(),});
static Insertable<UserItem> custom({Expression<int>? id, 
Expression<int>? serverId, 
Expression<int>? userId, 
Expression<int>? itemId, 
Expression<bool>? isPlaced, 
Expression<int>? roomId, 
Expression<String>? slot, 
Expression<int>? xPos, 
Expression<int>? yPos, 
Expression<bool>? isDirty, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (serverId != null)'server_id': serverId,if (userId != null)'user_id': userId,if (itemId != null)'item_id': itemId,if (isPlaced != null)'is_placed': isPlaced,if (roomId != null)'room_id': roomId,if (slot != null)'slot': slot,if (xPos != null)'x_pos': xPos,if (yPos != null)'y_pos': yPos,if (isDirty != null)'is_dirty': isDirty,});
}UserItemsCompanion copyWith({Value<int>? id, Value<int?>? serverId, Value<int?>? userId, Value<int?>? itemId, Value<bool>? isPlaced, Value<int?>? roomId, Value<String?>? slot, Value<int?>? xPos, Value<int?>? yPos, Value<bool>? isDirty}) {
return UserItemsCompanion(id: id ?? this.id,serverId: serverId ?? this.serverId,userId: userId ?? this.userId,itemId: itemId ?? this.itemId,isPlaced: isPlaced ?? this.isPlaced,roomId: roomId ?? this.roomId,slot: slot ?? this.slot,xPos: xPos ?? this.xPos,yPos: yPos ?? this.yPos,isDirty: isDirty ?? this.isDirty,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (serverId.present) {
map['server_id'] = Variable<int>(serverId.value);}
if (userId.present) {
map['user_id'] = Variable<int>(userId.value);}
if (itemId.present) {
map['item_id'] = Variable<int>(itemId.value);}
if (isPlaced.present) {
map['is_placed'] = Variable<bool>(isPlaced.value);}
if (roomId.present) {
map['room_id'] = Variable<int>(roomId.value);}
if (slot.present) {
map['slot'] = Variable<String>(slot.value);}
if (xPos.present) {
map['x_pos'] = Variable<int>(xPos.value);}
if (yPos.present) {
map['y_pos'] = Variable<int>(yPos.value);}
if (isDirty.present) {
map['is_dirty'] = Variable<bool>(isDirty.value);}
return map; 
}
@override
String toString() {return (StringBuffer('UserItemsCompanion(')..write('id: $id, ')..write('serverId: $serverId, ')..write('userId: $userId, ')..write('itemId: $itemId, ')..write('isPlaced: $isPlaced, ')..write('roomId: $roomId, ')..write('slot: $slot, ')..write('xPos: $xPos, ')..write('yPos: $yPos, ')..write('isDirty: $isDirty')..write(')')).toString();}
}
class $SyncActionsTable extends SyncActions with TableInfo<$SyncActionsTable, SyncAction>{
@override final GeneratedDatabase attachedDatabase;
final String? _alias;
$SyncActionsTable(this.attachedDatabase, [this._alias]);
static const VerificationMeta _idMeta = const VerificationMeta('id');
@override
late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false, hasAutoIncrement: true, type: DriftSqlType.int, requiredDuringInsert: false, defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
static const VerificationMeta _actionTypeMeta = const VerificationMeta('actionType');
@override
late final GeneratedColumn<String> actionType = GeneratedColumn<String>('action_type', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
@override
late final GeneratedColumn<String> payload = GeneratedColumn<String>('payload', aliasedName, true, type: DriftSqlType.string, requiredDuringInsert: false);
static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
@override
late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>('created_at', aliasedName, false, type: DriftSqlType.dateTime, requiredDuringInsert: false, defaultValue: currentDateAndTime);
static const VerificationMeta _retryCountMeta = const VerificationMeta('retryCount');
@override
late final GeneratedColumn<int> retryCount = GeneratedColumn<int>('retry_count', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
@override
List<GeneratedColumn> get $columns => [id, actionType, payload, createdAt, retryCount];
@override
String get aliasedName => _alias ?? actualTableName;
@override
 String get actualTableName => $name;
static const String $name = 'sync_actions';
@override
VerificationContext validateIntegrity(Insertable<SyncAction> instance, {bool isInserting = false}) {
final context = VerificationContext();
final data = instance.toColumns(true);
if (data.containsKey('id')) {
context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));}if (data.containsKey('action_type')) {
context.handle(_actionTypeMeta, actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta));}if (data.containsKey('payload')) {
context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));}if (data.containsKey('created_at')) {
context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));}if (data.containsKey('retry_count')) {
context.handle(_retryCountMeta, retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta));}return context;
}
@override
Set<GeneratedColumn> get $primaryKey => {id};
@override SyncAction map(Map<String, dynamic> data, {String? tablePrefix})  {
final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';return SyncAction(id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!, actionType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}action_type']), payload: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload']), createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!, retryCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!, );
}
@override
$SyncActionsTable createAlias(String alias) {
return $SyncActionsTable(attachedDatabase, alias);}}class SyncAction extends DataClass implements Insertable<SyncAction> 
{
final int id;
final String? actionType;
final String? payload;
final DateTime createdAt;
final int retryCount;
const SyncAction({required this.id, this.actionType, this.payload, required this.createdAt, required this.retryCount});@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};map['id'] = Variable<int>(id);
if (!nullToAbsent || actionType != null){map['action_type'] = Variable<String>(actionType);
}if (!nullToAbsent || payload != null){map['payload'] = Variable<String>(payload);
}map['created_at'] = Variable<DateTime>(createdAt);
map['retry_count'] = Variable<int>(retryCount);
return map; 
}
SyncActionsCompanion toCompanion(bool nullToAbsent) {
return SyncActionsCompanion(id: Value(id),actionType: actionType == null && nullToAbsent ? const Value.absent() : Value(actionType),payload: payload == null && nullToAbsent ? const Value.absent() : Value(payload),createdAt: Value(createdAt),retryCount: Value(retryCount),);
}
factory SyncAction.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return SyncAction(id: serializer.fromJson<int>(json['id']),actionType: serializer.fromJson<String?>(json['actionType']),payload: serializer.fromJson<String?>(json['payload']),createdAt: serializer.fromJson<DateTime>(json['createdAt']),retryCount: serializer.fromJson<int>(json['retryCount']),);}
@override Map<String, dynamic> toJson({ValueSerializer? serializer}) {
serializer ??= driftRuntimeOptions.defaultSerializer;
return <String, dynamic>{
'id': serializer.toJson<int>(id),'actionType': serializer.toJson<String?>(actionType),'payload': serializer.toJson<String?>(payload),'createdAt': serializer.toJson<DateTime>(createdAt),'retryCount': serializer.toJson<int>(retryCount),};}SyncAction copyWith({int? id,Value<String?> actionType = const Value.absent(),Value<String?> payload = const Value.absent(),DateTime? createdAt,int? retryCount}) => SyncAction(id: id ?? this.id,actionType: actionType.present ? actionType.value : this.actionType,payload: payload.present ? payload.value : this.payload,createdAt: createdAt ?? this.createdAt,retryCount: retryCount ?? this.retryCount,);SyncAction copyWithCompanion(SyncActionsCompanion data) {
return SyncAction(
id: data.id.present ? data.id.value : this.id,actionType: data.actionType.present ? data.actionType.value : this.actionType,payload: data.payload.present ? data.payload.value : this.payload,createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,retryCount: data.retryCount.present ? data.retryCount.value : this.retryCount,);
}
@override
String toString() {return (StringBuffer('SyncAction(')..write('id: $id, ')..write('actionType: $actionType, ')..write('payload: $payload, ')..write('createdAt: $createdAt, ')..write('retryCount: $retryCount')..write(')')).toString();}
@override
 int get hashCode => Object.hash(id, actionType, payload, createdAt, retryCount);@override
bool operator ==(Object other) => identical(this, other) || (other is SyncAction && other.id == this.id && other.actionType == this.actionType && other.payload == this.payload && other.createdAt == this.createdAt && other.retryCount == this.retryCount);
}class SyncActionsCompanion extends UpdateCompanion<SyncAction> {
final Value<int> id;
final Value<String?> actionType;
final Value<String?> payload;
final Value<DateTime> createdAt;
final Value<int> retryCount;
const SyncActionsCompanion({this.id = const Value.absent(),this.actionType = const Value.absent(),this.payload = const Value.absent(),this.createdAt = const Value.absent(),this.retryCount = const Value.absent(),});
SyncActionsCompanion.insert({this.id = const Value.absent(),this.actionType = const Value.absent(),this.payload = const Value.absent(),this.createdAt = const Value.absent(),this.retryCount = const Value.absent(),});
static Insertable<SyncAction> custom({Expression<int>? id, 
Expression<String>? actionType, 
Expression<String>? payload, 
Expression<DateTime>? createdAt, 
Expression<int>? retryCount, 
}) {
return RawValuesInsertable({if (id != null)'id': id,if (actionType != null)'action_type': actionType,if (payload != null)'payload': payload,if (createdAt != null)'created_at': createdAt,if (retryCount != null)'retry_count': retryCount,});
}SyncActionsCompanion copyWith({Value<int>? id, Value<String?>? actionType, Value<String?>? payload, Value<DateTime>? createdAt, Value<int>? retryCount}) {
return SyncActionsCompanion(id: id ?? this.id,actionType: actionType ?? this.actionType,payload: payload ?? this.payload,createdAt: createdAt ?? this.createdAt,retryCount: retryCount ?? this.retryCount,);
}
@override
Map<String, Expression> toColumns(bool nullToAbsent) {
final map = <String, Expression> {};if (id.present) {
map['id'] = Variable<int>(id.value);}
if (actionType.present) {
map['action_type'] = Variable<String>(actionType.value);}
if (payload.present) {
map['payload'] = Variable<String>(payload.value);}
if (createdAt.present) {
map['created_at'] = Variable<DateTime>(createdAt.value);}
if (retryCount.present) {
map['retry_count'] = Variable<int>(retryCount.value);}
return map; 
}
@override
String toString() {return (StringBuffer('SyncActionsCompanion(')..write('id: $id, ')..write('actionType: $actionType, ')..write('payload: $payload, ')..write('createdAt: $createdAt, ')..write('retryCount: $retryCount')..write(')')).toString();}
}
abstract class _$AppDatabase extends GeneratedDatabase{
_$AppDatabase(QueryExecutor e): super(e);
$AppDatabaseManager get managers => $AppDatabaseManager(this);
late final $QuestionsTable questions = $QuestionsTable(this);
late final $TopicProgressTable topicProgress = $TopicProgressTable(this);
late final $QuestionProgressTable questionProgress = $QuestionProgressTable(this);
late final $ItemsTable items = $ItemsTable(this);
late final $UserItemsTable userItems = $UserItemsTable(this);
late final $SyncActionsTable syncActions = $SyncActionsTable(this);
@override
Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
@override
List<DatabaseSchemaEntity> get allSchemaEntities => [questions, topicProgress, questionProgress, items, userItems, syncActions];
}
typedef $$QuestionsTableCreateCompanionBuilder = QuestionsCompanion Function({Value<int> id,Value<int?> serverId,Value<int?> topicId,Value<String?> questionText,Value<String?> type,Value<String?> options,Value<String?> correctAnswer,Value<String?> explanation,Value<int?> bloomLevel,Value<int?> difficulty,Value<bool> active,Value<DateTime?> lastFetched,});
typedef $$QuestionsTableUpdateCompanionBuilder = QuestionsCompanion Function({Value<int> id,Value<int?> serverId,Value<int?> topicId,Value<String?> questionText,Value<String?> type,Value<String?> options,Value<String?> correctAnswer,Value<String?> explanation,Value<int?> bloomLevel,Value<int?> difficulty,Value<bool> active,Value<DateTime?> lastFetched,});
class $$QuestionsTableFilterComposer extends Composer<
        _$AppDatabase,
        $QuestionsTable> {
        $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get topicId => $composableBuilder(
      column: $table.topicId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get options => $composableBuilder(
      column: $table.options,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$QuestionsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $QuestionsTable> {
        $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get topicId => $composableBuilder(
      column: $table.topicId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get options => $composableBuilder(
      column: $table.options,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$QuestionsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $QuestionsTable> {
        $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => column);
      
GeneratedColumn<int> get topicId => $composableBuilder(
      column: $table.topicId,
      builder: (column) => column);
      
GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => column);
      
GeneratedColumn<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => column);
      
GeneratedColumn<String> get options => $composableBuilder(
      column: $table.options,
      builder: (column) => column);
      
GeneratedColumn<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => column);
      
GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation,
      builder: (column) => column);
      
GeneratedColumn<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel,
      builder: (column) => column);
      
GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty,
      builder: (column) => column);
      
GeneratedColumn<bool> get active => $composableBuilder(
      column: $table.active,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched,
      builder: (column) => column);
      
        }
      class $$QuestionsTableTableManager extends RootTableManager    <_$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question,BaseReferences<_$AppDatabase,$QuestionsTable,Question>),
    Question,
    PrefetchHooks Function()
    > {
    $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$QuestionsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$QuestionsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$QuestionsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<int?> topicId = const Value.absent(),Value<String?> questionText = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> options = const Value.absent(),Value<String?> correctAnswer = const Value.absent(),Value<String?> explanation = const Value.absent(),Value<int?> bloomLevel = const Value.absent(),Value<int?> difficulty = const Value.absent(),Value<bool> active = const Value.absent(),Value<DateTime?> lastFetched = const Value.absent(),})=> QuestionsCompanion(id: id,serverId: serverId,topicId: topicId,questionText: questionText,type: type,options: options,correctAnswer: correctAnswer,explanation: explanation,bloomLevel: bloomLevel,difficulty: difficulty,active: active,lastFetched: lastFetched,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<int?> topicId = const Value.absent(),Value<String?> questionText = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> options = const Value.absent(),Value<String?> correctAnswer = const Value.absent(),Value<String?> explanation = const Value.absent(),Value<int?> bloomLevel = const Value.absent(),Value<int?> difficulty = const Value.absent(),Value<bool> active = const Value.absent(),Value<DateTime?> lastFetched = const Value.absent(),})=> QuestionsCompanion.insert(id: id,serverId: serverId,topicId: topicId,questionText: questionText,type: type,options: options,correctAnswer: correctAnswer,explanation: explanation,bloomLevel: bloomLevel,difficulty: difficulty,active: active,lastFetched: lastFetched,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$QuestionsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question,BaseReferences<_$AppDatabase,$QuestionsTable,Question>),
    Question,
    PrefetchHooks Function()
    >;typedef $$TopicProgressTableCreateCompanionBuilder = TopicProgressCompanion Function({Value<int> id,Value<int?> userId,Value<String?> topicSlug,Value<int> currentBloomLevel,Value<int> currentStreak,Value<int> consecutiveWrong,Value<int> totalAnswered,Value<int> correctAnswered,Value<int> masteryScore,Value<int> unlockedBloomLevel,Value<int> questionsMastered,Value<DateTime?> lastStudiedAt,Value<bool> isDirty,});
typedef $$TopicProgressTableUpdateCompanionBuilder = TopicProgressCompanion Function({Value<int> id,Value<int?> userId,Value<String?> topicSlug,Value<int> currentBloomLevel,Value<int> currentStreak,Value<int> consecutiveWrong,Value<int> totalAnswered,Value<int> correctAnswered,Value<int> masteryScore,Value<int> unlockedBloomLevel,Value<int> questionsMastered,Value<DateTime?> lastStudiedAt,Value<bool> isDirty,});
class $$TopicProgressTableFilterComposer extends Composer<
        _$AppDatabase,
        $TopicProgressTable> {
        $$TopicProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get topicSlug => $composableBuilder(
      column: $table.topicSlug,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$TopicProgressTableOrderingComposer extends Composer<
        _$AppDatabase,
        $TopicProgressTable> {
        $$TopicProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get topicSlug => $composableBuilder(
      column: $table.topicSlug,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$TopicProgressTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $TopicProgressTable> {
        $$TopicProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => column);
      
GeneratedColumn<String> get topicSlug => $composableBuilder(
      column: $table.topicSlug,
      builder: (column) => column);
      
GeneratedColumn<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel,
      builder: (column) => column);
      
GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => column);
      
GeneratedColumn<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong,
      builder: (column) => column);
      
GeneratedColumn<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered,
      builder: (column) => column);
      
GeneratedColumn<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered,
      builder: (column) => column);
      
GeneratedColumn<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore,
      builder: (column) => column);
      
GeneratedColumn<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel,
      builder: (column) => column);
      
GeneratedColumn<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt,
      builder: (column) => column);
      
GeneratedColumn<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => column);
      
        }
      class $$TopicProgressTableTableManager extends RootTableManager    <_$AppDatabase,
    $TopicProgressTable,
    TopicProgressData,
    $$TopicProgressTableFilterComposer,
    $$TopicProgressTableOrderingComposer,
    $$TopicProgressTableAnnotationComposer,
    $$TopicProgressTableCreateCompanionBuilder,
    $$TopicProgressTableUpdateCompanionBuilder,
    (TopicProgressData,BaseReferences<_$AppDatabase,$TopicProgressTable,TopicProgressData>),
    TopicProgressData,
    PrefetchHooks Function()
    > {
    $$TopicProgressTableTableManager(_$AppDatabase db, $TopicProgressTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$TopicProgressTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$TopicProgressTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$TopicProgressTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> userId = const Value.absent(),Value<String?> topicSlug = const Value.absent(),Value<int> currentBloomLevel = const Value.absent(),Value<int> currentStreak = const Value.absent(),Value<int> consecutiveWrong = const Value.absent(),Value<int> totalAnswered = const Value.absent(),Value<int> correctAnswered = const Value.absent(),Value<int> masteryScore = const Value.absent(),Value<int> unlockedBloomLevel = const Value.absent(),Value<int> questionsMastered = const Value.absent(),Value<DateTime?> lastStudiedAt = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> TopicProgressCompanion(id: id,userId: userId,topicSlug: topicSlug,currentBloomLevel: currentBloomLevel,currentStreak: currentStreak,consecutiveWrong: consecutiveWrong,totalAnswered: totalAnswered,correctAnswered: correctAnswered,masteryScore: masteryScore,unlockedBloomLevel: unlockedBloomLevel,questionsMastered: questionsMastered,lastStudiedAt: lastStudiedAt,isDirty: isDirty,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> userId = const Value.absent(),Value<String?> topicSlug = const Value.absent(),Value<int> currentBloomLevel = const Value.absent(),Value<int> currentStreak = const Value.absent(),Value<int> consecutiveWrong = const Value.absent(),Value<int> totalAnswered = const Value.absent(),Value<int> correctAnswered = const Value.absent(),Value<int> masteryScore = const Value.absent(),Value<int> unlockedBloomLevel = const Value.absent(),Value<int> questionsMastered = const Value.absent(),Value<DateTime?> lastStudiedAt = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> TopicProgressCompanion.insert(id: id,userId: userId,topicSlug: topicSlug,currentBloomLevel: currentBloomLevel,currentStreak: currentStreak,consecutiveWrong: consecutiveWrong,totalAnswered: totalAnswered,correctAnswered: correctAnswered,masteryScore: masteryScore,unlockedBloomLevel: unlockedBloomLevel,questionsMastered: questionsMastered,lastStudiedAt: lastStudiedAt,isDirty: isDirty,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$TopicProgressTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $TopicProgressTable,
    TopicProgressData,
    $$TopicProgressTableFilterComposer,
    $$TopicProgressTableOrderingComposer,
    $$TopicProgressTableAnnotationComposer,
    $$TopicProgressTableCreateCompanionBuilder,
    $$TopicProgressTableUpdateCompanionBuilder,
    (TopicProgressData,BaseReferences<_$AppDatabase,$TopicProgressTable,TopicProgressData>),
    TopicProgressData,
    PrefetchHooks Function()
    >;typedef $$QuestionProgressTableCreateCompanionBuilder = QuestionProgressCompanion Function({Value<int> id,Value<int?> userId,Value<int?> questionId,Value<int> box,Value<int> consecutiveCorrect,Value<bool> mastered,Value<DateTime?> nextReviewAt,Value<DateTime?> lastAnsweredAt,Value<DateTime?> updatedAt,Value<bool> isDirty,});
typedef $$QuestionProgressTableUpdateCompanionBuilder = QuestionProgressCompanion Function({Value<int> id,Value<int?> userId,Value<int?> questionId,Value<int> box,Value<int> consecutiveCorrect,Value<bool> mastered,Value<DateTime?> nextReviewAt,Value<DateTime?> lastAnsweredAt,Value<DateTime?> updatedAt,Value<bool> isDirty,});
class $$QuestionProgressTableFilterComposer extends Composer<
        _$AppDatabase,
        $QuestionProgressTable> {
        $$QuestionProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get questionId => $composableBuilder(
      column: $table.questionId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get box => $composableBuilder(
      column: $table.box,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get mastered => $composableBuilder(
      column: $table.mastered,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$QuestionProgressTableOrderingComposer extends Composer<
        _$AppDatabase,
        $QuestionProgressTable> {
        $$QuestionProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get questionId => $composableBuilder(
      column: $table.questionId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get box => $composableBuilder(
      column: $table.box,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get mastered => $composableBuilder(
      column: $table.mastered,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$QuestionProgressTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $QuestionProgressTable> {
        $$QuestionProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => column);
      
GeneratedColumn<int> get questionId => $composableBuilder(
      column: $table.questionId,
      builder: (column) => column);
      
GeneratedColumn<int> get box => $composableBuilder(
      column: $table.box,
      builder: (column) => column);
      
GeneratedColumn<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => column);
      
GeneratedColumn<bool> get mastered => $composableBuilder(
      column: $table.mastered,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt,
      builder: (column) => column);
      
GeneratedColumn<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => column);
      
        }
      class $$QuestionProgressTableTableManager extends RootTableManager    <_$AppDatabase,
    $QuestionProgressTable,
    QuestionProgressData,
    $$QuestionProgressTableFilterComposer,
    $$QuestionProgressTableOrderingComposer,
    $$QuestionProgressTableAnnotationComposer,
    $$QuestionProgressTableCreateCompanionBuilder,
    $$QuestionProgressTableUpdateCompanionBuilder,
    (QuestionProgressData,BaseReferences<_$AppDatabase,$QuestionProgressTable,QuestionProgressData>),
    QuestionProgressData,
    PrefetchHooks Function()
    > {
    $$QuestionProgressTableTableManager(_$AppDatabase db, $QuestionProgressTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$QuestionProgressTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$QuestionProgressTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$QuestionProgressTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> userId = const Value.absent(),Value<int?> questionId = const Value.absent(),Value<int> box = const Value.absent(),Value<int> consecutiveCorrect = const Value.absent(),Value<bool> mastered = const Value.absent(),Value<DateTime?> nextReviewAt = const Value.absent(),Value<DateTime?> lastAnsweredAt = const Value.absent(),Value<DateTime?> updatedAt = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> QuestionProgressCompanion(id: id,userId: userId,questionId: questionId,box: box,consecutiveCorrect: consecutiveCorrect,mastered: mastered,nextReviewAt: nextReviewAt,lastAnsweredAt: lastAnsweredAt,updatedAt: updatedAt,isDirty: isDirty,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> userId = const Value.absent(),Value<int?> questionId = const Value.absent(),Value<int> box = const Value.absent(),Value<int> consecutiveCorrect = const Value.absent(),Value<bool> mastered = const Value.absent(),Value<DateTime?> nextReviewAt = const Value.absent(),Value<DateTime?> lastAnsweredAt = const Value.absent(),Value<DateTime?> updatedAt = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> QuestionProgressCompanion.insert(id: id,userId: userId,questionId: questionId,box: box,consecutiveCorrect: consecutiveCorrect,mastered: mastered,nextReviewAt: nextReviewAt,lastAnsweredAt: lastAnsweredAt,updatedAt: updatedAt,isDirty: isDirty,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$QuestionProgressTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $QuestionProgressTable,
    QuestionProgressData,
    $$QuestionProgressTableFilterComposer,
    $$QuestionProgressTableOrderingComposer,
    $$QuestionProgressTableAnnotationComposer,
    $$QuestionProgressTableCreateCompanionBuilder,
    $$QuestionProgressTableUpdateCompanionBuilder,
    (QuestionProgressData,BaseReferences<_$AppDatabase,$QuestionProgressTable,QuestionProgressData>),
    QuestionProgressData,
    PrefetchHooks Function()
    >;typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({Value<int> id,Value<int?> serverId,Value<String?> name,Value<String?> type,Value<String?> slotType,Value<int?> price,Value<String?> assetPath,Value<String?> description,Value<String?> theme,Value<bool> isPremium,});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({Value<int> id,Value<int?> serverId,Value<String?> name,Value<String?> type,Value<String?> slotType,Value<int?> price,Value<String?> assetPath,Value<String?> description,Value<String?> theme,Value<bool> isPremium,});
class $$ItemsTableFilterComposer extends Composer<
        _$AppDatabase,
        $ItemsTable> {
        $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get name => $composableBuilder(
      column: $table.name,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get slotType => $composableBuilder(
      column: $table.slotType,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get price => $composableBuilder(
      column: $table.price,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get assetPath => $composableBuilder(
      column: $table.assetPath,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get theme => $composableBuilder(
      column: $table.theme,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isPremium => $composableBuilder(
      column: $table.isPremium,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$ItemsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $ItemsTable> {
        $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get slotType => $composableBuilder(
      column: $table.slotType,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get assetPath => $composableBuilder(
      column: $table.assetPath,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get theme => $composableBuilder(
      column: $table.theme,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isPremium => $composableBuilder(
      column: $table.isPremium,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$ItemsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $ItemsTable> {
        $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => column);
      
GeneratedColumn<String> get name => $composableBuilder(
      column: $table.name,
      builder: (column) => column);
      
GeneratedColumn<String> get type => $composableBuilder(
      column: $table.type,
      builder: (column) => column);
      
GeneratedColumn<String> get slotType => $composableBuilder(
      column: $table.slotType,
      builder: (column) => column);
      
GeneratedColumn<int> get price => $composableBuilder(
      column: $table.price,
      builder: (column) => column);
      
GeneratedColumn<String> get assetPath => $composableBuilder(
      column: $table.assetPath,
      builder: (column) => column);
      
GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description,
      builder: (column) => column);
      
GeneratedColumn<String> get theme => $composableBuilder(
      column: $table.theme,
      builder: (column) => column);
      
GeneratedColumn<bool> get isPremium => $composableBuilder(
      column: $table.isPremium,
      builder: (column) => column);
      
        }
      class $$ItemsTableTableManager extends RootTableManager    <_$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item,BaseReferences<_$AppDatabase,$ItemsTable,Item>),
    Item,
    PrefetchHooks Function()
    > {
    $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$ItemsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$ItemsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$ItemsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<String?> name = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> slotType = const Value.absent(),Value<int?> price = const Value.absent(),Value<String?> assetPath = const Value.absent(),Value<String?> description = const Value.absent(),Value<String?> theme = const Value.absent(),Value<bool> isPremium = const Value.absent(),})=> ItemsCompanion(id: id,serverId: serverId,name: name,type: type,slotType: slotType,price: price,assetPath: assetPath,description: description,theme: theme,isPremium: isPremium,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<String?> name = const Value.absent(),Value<String?> type = const Value.absent(),Value<String?> slotType = const Value.absent(),Value<int?> price = const Value.absent(),Value<String?> assetPath = const Value.absent(),Value<String?> description = const Value.absent(),Value<String?> theme = const Value.absent(),Value<bool> isPremium = const Value.absent(),})=> ItemsCompanion.insert(id: id,serverId: serverId,name: name,type: type,slotType: slotType,price: price,assetPath: assetPath,description: description,theme: theme,isPremium: isPremium,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$ItemsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item,BaseReferences<_$AppDatabase,$ItemsTable,Item>),
    Item,
    PrefetchHooks Function()
    >;typedef $$UserItemsTableCreateCompanionBuilder = UserItemsCompanion Function({Value<int> id,Value<int?> serverId,Value<int?> userId,Value<int?> itemId,Value<bool> isPlaced,Value<int?> roomId,Value<String?> slot,Value<int?> xPos,Value<int?> yPos,Value<bool> isDirty,});
typedef $$UserItemsTableUpdateCompanionBuilder = UserItemsCompanion Function({Value<int> id,Value<int?> serverId,Value<int?> userId,Value<int?> itemId,Value<bool> isPlaced,Value<int?> roomId,Value<String?> slot,Value<int?> xPos,Value<int?> yPos,Value<bool> isDirty,});
class $$UserItemsTableFilterComposer extends Composer<
        _$AppDatabase,
        $UserItemsTable> {
        $$UserItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get roomId => $composableBuilder(
      column: $table.roomId,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get xPos => $composableBuilder(
      column: $table.xPos,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get yPos => $composableBuilder(
      column: $table.yPos,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$UserItemsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $UserItemsTable> {
        $$UserItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get roomId => $composableBuilder(
      column: $table.roomId,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get xPos => $composableBuilder(
      column: $table.xPos,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get yPos => $composableBuilder(
      column: $table.yPos,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$UserItemsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $UserItemsTable> {
        $$UserItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<int> get serverId => $composableBuilder(
      column: $table.serverId,
      builder: (column) => column);
      
GeneratedColumn<int> get userId => $composableBuilder(
      column: $table.userId,
      builder: (column) => column);
      
GeneratedColumn<int> get itemId => $composableBuilder(
      column: $table.itemId,
      builder: (column) => column);
      
GeneratedColumn<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced,
      builder: (column) => column);
      
GeneratedColumn<int> get roomId => $composableBuilder(
      column: $table.roomId,
      builder: (column) => column);
      
GeneratedColumn<String> get slot => $composableBuilder(
      column: $table.slot,
      builder: (column) => column);
      
GeneratedColumn<int> get xPos => $composableBuilder(
      column: $table.xPos,
      builder: (column) => column);
      
GeneratedColumn<int> get yPos => $composableBuilder(
      column: $table.yPos,
      builder: (column) => column);
      
GeneratedColumn<bool> get isDirty => $composableBuilder(
      column: $table.isDirty,
      builder: (column) => column);
      
        }
      class $$UserItemsTableTableManager extends RootTableManager    <_$AppDatabase,
    $UserItemsTable,
    UserItem,
    $$UserItemsTableFilterComposer,
    $$UserItemsTableOrderingComposer,
    $$UserItemsTableAnnotationComposer,
    $$UserItemsTableCreateCompanionBuilder,
    $$UserItemsTableUpdateCompanionBuilder,
    (UserItem,BaseReferences<_$AppDatabase,$UserItemsTable,UserItem>),
    UserItem,
    PrefetchHooks Function()
    > {
    $$UserItemsTableTableManager(_$AppDatabase db, $UserItemsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$UserItemsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$UserItemsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$UserItemsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<int?> userId = const Value.absent(),Value<int?> itemId = const Value.absent(),Value<bool> isPlaced = const Value.absent(),Value<int?> roomId = const Value.absent(),Value<String?> slot = const Value.absent(),Value<int?> xPos = const Value.absent(),Value<int?> yPos = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> UserItemsCompanion(id: id,serverId: serverId,userId: userId,itemId: itemId,isPlaced: isPlaced,roomId: roomId,slot: slot,xPos: xPos,yPos: yPos,isDirty: isDirty,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<int?> serverId = const Value.absent(),Value<int?> userId = const Value.absent(),Value<int?> itemId = const Value.absent(),Value<bool> isPlaced = const Value.absent(),Value<int?> roomId = const Value.absent(),Value<String?> slot = const Value.absent(),Value<int?> xPos = const Value.absent(),Value<int?> yPos = const Value.absent(),Value<bool> isDirty = const Value.absent(),})=> UserItemsCompanion.insert(id: id,serverId: serverId,userId: userId,itemId: itemId,isPlaced: isPlaced,roomId: roomId,slot: slot,xPos: xPos,yPos: yPos,isDirty: isDirty,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$UserItemsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $UserItemsTable,
    UserItem,
    $$UserItemsTableFilterComposer,
    $$UserItemsTableOrderingComposer,
    $$UserItemsTableAnnotationComposer,
    $$UserItemsTableCreateCompanionBuilder,
    $$UserItemsTableUpdateCompanionBuilder,
    (UserItem,BaseReferences<_$AppDatabase,$UserItemsTable,UserItem>),
    UserItem,
    PrefetchHooks Function()
    >;typedef $$SyncActionsTableCreateCompanionBuilder = SyncActionsCompanion Function({Value<int> id,Value<String?> actionType,Value<String?> payload,Value<DateTime> createdAt,Value<int> retryCount,});
typedef $$SyncActionsTableUpdateCompanionBuilder = SyncActionsCompanion Function({Value<int> id,Value<String?> actionType,Value<String?> payload,Value<DateTime> createdAt,Value<int> retryCount,});
class $$SyncActionsTableFilterComposer extends Composer<
        _$AppDatabase,
        $SyncActionsTable> {
        $$SyncActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnFilters<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get actionType => $composableBuilder(
      column: $table.actionType,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnFilters(column));
      
ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount,
      builder: (column) => 
      ColumnFilters(column));
      
        }
      class $$SyncActionsTableOrderingComposer extends Composer<
        _$AppDatabase,
        $SyncActionsTable> {
        $$SyncActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get actionType => $composableBuilder(
      column: $table.actionType,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => 
      ColumnOrderings(column));
      
ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount,
      builder: (column) => 
      ColumnOrderings(column));
      
        }
      class $$SyncActionsTableAnnotationComposer extends Composer<
        _$AppDatabase,
        $SyncActionsTable> {
        $$SyncActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
          GeneratedColumn<int> get id => $composableBuilder(
      column: $table.id,
      builder: (column) => column);
      
GeneratedColumn<String> get actionType => $composableBuilder(
      column: $table.actionType,
      builder: (column) => column);
      
GeneratedColumn<String> get payload => $composableBuilder(
      column: $table.payload,
      builder: (column) => column);
      
GeneratedColumn<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt,
      builder: (column) => column);
      
GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount,
      builder: (column) => column);
      
        }
      class $$SyncActionsTableTableManager extends RootTableManager    <_$AppDatabase,
    $SyncActionsTable,
    SyncAction,
    $$SyncActionsTableFilterComposer,
    $$SyncActionsTableOrderingComposer,
    $$SyncActionsTableAnnotationComposer,
    $$SyncActionsTableCreateCompanionBuilder,
    $$SyncActionsTableUpdateCompanionBuilder,
    (SyncAction,BaseReferences<_$AppDatabase,$SyncActionsTable,SyncAction>),
    SyncAction,
    PrefetchHooks Function()
    > {
    $$SyncActionsTableTableManager(_$AppDatabase db, $SyncActionsTable table) : super(
      TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: () => $$SyncActionsTableFilterComposer($db: db,$table:table),
        createOrderingComposer: () => $$SyncActionsTableOrderingComposer($db: db,$table:table),
        createComputedFieldComposer: () => $$SyncActionsTableAnnotationComposer($db: db,$table:table),
        updateCompanionCallback: ({Value<int> id = const Value.absent(),Value<String?> actionType = const Value.absent(),Value<String?> payload = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> retryCount = const Value.absent(),})=> SyncActionsCompanion(id: id,actionType: actionType,payload: payload,createdAt: createdAt,retryCount: retryCount,),
        createCompanionCallback: ({Value<int> id = const Value.absent(),Value<String?> actionType = const Value.absent(),Value<String?> payload = const Value.absent(),Value<DateTime> createdAt = const Value.absent(),Value<int> retryCount = const Value.absent(),})=> SyncActionsCompanion.insert(id: id,actionType: actionType,payload: payload,createdAt: createdAt,retryCount: retryCount,),
        withReferenceMapper: (p0) => p0
              .map(
                  (e) =>
                     (e.readTable(table), BaseReferences(db, table, e))
                  )
              .toList(),
        prefetchHooksCallback: null,
        ));
        }
    typedef $$SyncActionsTableProcessedTableManager = ProcessedTableManager    <_$AppDatabase,
    $SyncActionsTable,
    SyncAction,
    $$SyncActionsTableFilterComposer,
    $$SyncActionsTableOrderingComposer,
    $$SyncActionsTableAnnotationComposer,
    $$SyncActionsTableCreateCompanionBuilder,
    $$SyncActionsTableUpdateCompanionBuilder,
    (SyncAction,BaseReferences<_$AppDatabase,$SyncActionsTable,SyncAction>),
    SyncAction,
    PrefetchHooks Function()
    >;class $AppDatabaseManager {
final _$AppDatabase _db;
$AppDatabaseManager(this._db);
$$QuestionsTableTableManager get questions => $$QuestionsTableTableManager(_db, _db.questions);
$$TopicProgressTableTableManager get topicProgress => $$TopicProgressTableTableManager(_db, _db.topicProgress);
$$QuestionProgressTableTableManager get questionProgress => $$QuestionProgressTableTableManager(_db, _db.questionProgress);
$$ItemsTableTableManager get items => $$ItemsTableTableManager(_db, _db.items);
$$UserItemsTableTableManager get userItems => $$UserItemsTableTableManager(_db, _db.userItems);
$$SyncActionsTableTableManager get syncActions => $$SyncActionsTableTableManager(_db, _db.syncActions);
}
