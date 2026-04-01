// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
      'topic_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _questionTextMeta =
      const VerificationMeta('questionText');
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
      'question_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _optionsMeta =
      const VerificationMeta('options');
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
      'options', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _correctAnswerMeta =
      const VerificationMeta('correctAnswer');
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
      'correct_answer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bloomLevelMeta =
      const VerificationMeta('bloomLevel');
  @override
  late final GeneratedColumn<int> bloomLevel = GeneratedColumn<int>(
      'bloom_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastFetchedMeta =
      const VerificationMeta('lastFetched');
  @override
  late final GeneratedColumn<DateTime> lastFetched = GeneratedColumn<DateTime>(
      'last_fetched', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        topicId,
        questionText,
        type,
        options,
        correctAnswer,
        explanation,
        bloomLevel,
        difficulty,
        active,
        lastFetched
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(Insertable<Question> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('question_text')) {
      context.handle(
          _questionTextMeta,
          questionText.isAcceptableOrUnknown(
              data['question_text']!, _questionTextMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('options')) {
      context.handle(_optionsMeta,
          options.isAcceptableOrUnknown(data['options']!, _optionsMeta));
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
          _correctAnswerMeta,
          correctAnswer.isAcceptableOrUnknown(
              data['correct_answer']!, _correctAnswerMeta));
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    if (data.containsKey('bloom_level')) {
      context.handle(
          _bloomLevelMeta,
          bloomLevel.isAcceptableOrUnknown(
              data['bloom_level']!, _bloomLevelMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('last_fetched')) {
      context.handle(
          _lastFetchedMeta,
          lastFetched.isAcceptableOrUnknown(
              data['last_fetched']!, _lastFetchedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}topic_id']),
      questionText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_text']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type']),
      options: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options']),
      correctAnswer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correct_answer']),
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
      bloomLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bloom_level']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      lastFetched: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_fetched']),
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
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
  const Question(
      {required this.id,
      this.serverId,
      this.topicId,
      this.questionText,
      this.type,
      this.options,
      this.correctAnswer,
      this.explanation,
      this.bloomLevel,
      this.difficulty,
      required this.active,
      this.lastFetched});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<int>(topicId);
    }
    if (!nullToAbsent || questionText != null) {
      map['question_text'] = Variable<String>(questionText);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    if (!nullToAbsent || correctAnswer != null) {
      map['correct_answer'] = Variable<String>(correctAnswer);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || bloomLevel != null) {
      map['bloom_level'] = Variable<int>(bloomLevel);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<int>(difficulty);
    }
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || lastFetched != null) {
      map['last_fetched'] = Variable<DateTime>(lastFetched);
    }
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      questionText: questionText == null && nullToAbsent
          ? const Value.absent()
          : Value(questionText),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      correctAnswer: correctAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(correctAnswer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      bloomLevel: bloomLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(bloomLevel),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      active: Value(active),
      lastFetched: lastFetched == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetched),
    );
  }

  factory Question.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      topicId: serializer.fromJson<int?>(json['topicId']),
      questionText: serializer.fromJson<String?>(json['questionText']),
      type: serializer.fromJson<String?>(json['type']),
      options: serializer.fromJson<String?>(json['options']),
      correctAnswer: serializer.fromJson<String?>(json['correctAnswer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      bloomLevel: serializer.fromJson<int?>(json['bloomLevel']),
      difficulty: serializer.fromJson<int?>(json['difficulty']),
      active: serializer.fromJson<bool>(json['active']),
      lastFetched: serializer.fromJson<DateTime?>(json['lastFetched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'topicId': serializer.toJson<int?>(topicId),
      'questionText': serializer.toJson<String?>(questionText),
      'type': serializer.toJson<String?>(type),
      'options': serializer.toJson<String?>(options),
      'correctAnswer': serializer.toJson<String?>(correctAnswer),
      'explanation': serializer.toJson<String?>(explanation),
      'bloomLevel': serializer.toJson<int?>(bloomLevel),
      'difficulty': serializer.toJson<int?>(difficulty),
      'active': serializer.toJson<bool>(active),
      'lastFetched': serializer.toJson<DateTime?>(lastFetched),
    };
  }

  Question copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          Value<int?> topicId = const Value.absent(),
          Value<String?> questionText = const Value.absent(),
          Value<String?> type = const Value.absent(),
          Value<String?> options = const Value.absent(),
          Value<String?> correctAnswer = const Value.absent(),
          Value<String?> explanation = const Value.absent(),
          Value<int?> bloomLevel = const Value.absent(),
          Value<int?> difficulty = const Value.absent(),
          bool? active,
          Value<DateTime?> lastFetched = const Value.absent()}) =>
      Question(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        topicId: topicId.present ? topicId.value : this.topicId,
        questionText:
            questionText.present ? questionText.value : this.questionText,
        type: type.present ? type.value : this.type,
        options: options.present ? options.value : this.options,
        correctAnswer:
            correctAnswer.present ? correctAnswer.value : this.correctAnswer,
        explanation: explanation.present ? explanation.value : this.explanation,
        bloomLevel: bloomLevel.present ? bloomLevel.value : this.bloomLevel,
        difficulty: difficulty.present ? difficulty.value : this.difficulty,
        active: active ?? this.active,
        lastFetched: lastFetched.present ? lastFetched.value : this.lastFetched,
      );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      type: data.type.present ? data.type.value : this.type,
      options: data.options.present ? data.options.value : this.options,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      bloomLevel:
          data.bloomLevel.present ? data.bloomLevel.value : this.bloomLevel,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      active: data.active.present ? data.active.value : this.active,
      lastFetched:
          data.lastFetched.present ? data.lastFetched.value : this.lastFetched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('topicId: $topicId, ')
          ..write('questionText: $questionText, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('bloomLevel: $bloomLevel, ')
          ..write('difficulty: $difficulty, ')
          ..write('active: $active, ')
          ..write('lastFetched: $lastFetched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      topicId,
      questionText,
      type,
      options,
      correctAnswer,
      explanation,
      bloomLevel,
      difficulty,
      active,
      lastFetched);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.topicId == this.topicId &&
          other.questionText == this.questionText &&
          other.type == this.type &&
          other.options == this.options &&
          other.correctAnswer == this.correctAnswer &&
          other.explanation == this.explanation &&
          other.bloomLevel == this.bloomLevel &&
          other.difficulty == this.difficulty &&
          other.active == this.active &&
          other.lastFetched == this.lastFetched);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
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
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.questionText = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.bloomLevel = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.active = const Value.absent(),
    this.lastFetched = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.questionText = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.bloomLevel = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.active = const Value.absent(),
    this.lastFetched = const Value.absent(),
  });
  static Insertable<Question> custom({
    Expression<int>? id,
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
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (topicId != null) 'topic_id': topicId,
      if (questionText != null) 'question_text': questionText,
      if (type != null) 'type': type,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (bloomLevel != null) 'bloom_level': bloomLevel,
      if (difficulty != null) 'difficulty': difficulty,
      if (active != null) 'active': active,
      if (lastFetched != null) 'last_fetched': lastFetched,
    });
  }

  QuestionsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int?>? topicId,
      Value<String?>? questionText,
      Value<String?>? type,
      Value<String?>? options,
      Value<String?>? correctAnswer,
      Value<String?>? explanation,
      Value<int?>? bloomLevel,
      Value<int?>? difficulty,
      Value<bool>? active,
      Value<DateTime?>? lastFetched}) {
    return QuestionsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      topicId: topicId ?? this.topicId,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      difficulty: difficulty ?? this.difficulty,
      active: active ?? this.active,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (bloomLevel.present) {
      map['bloom_level'] = Variable<int>(bloomLevel.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (lastFetched.present) {
      map['last_fetched'] = Variable<DateTime>(lastFetched.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('topicId: $topicId, ')
          ..write('questionText: $questionText, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('bloomLevel: $bloomLevel, ')
          ..write('difficulty: $difficulty, ')
          ..write('active: $active, ')
          ..write('lastFetched: $lastFetched')
          ..write(')'))
        .toString();
  }
}

class $TopicProgressTable extends TopicProgress
    with TableInfo<$TopicProgressTable, TopicProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _topicSlugMeta =
      const VerificationMeta('topicSlug');
  @override
  late final GeneratedColumn<String> topicSlug = GeneratedColumn<String>(
      'topic_slug', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentBloomLevelMeta =
      const VerificationMeta('currentBloomLevel');
  @override
  late final GeneratedColumn<int> currentBloomLevel = GeneratedColumn<int>(
      'current_bloom_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currentStreakMeta =
      const VerificationMeta('currentStreak');
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
      'current_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consecutiveWrongMeta =
      const VerificationMeta('consecutiveWrong');
  @override
  late final GeneratedColumn<int> consecutiveWrong = GeneratedColumn<int>(
      'consecutive_wrong', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalAnsweredMeta =
      const VerificationMeta('totalAnswered');
  @override
  late final GeneratedColumn<int> totalAnswered = GeneratedColumn<int>(
      'total_answered', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctAnsweredMeta =
      const VerificationMeta('correctAnswered');
  @override
  late final GeneratedColumn<int> correctAnswered = GeneratedColumn<int>(
      'correct_answered', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _masteryScoreMeta =
      const VerificationMeta('masteryScore');
  @override
  late final GeneratedColumn<int> masteryScore = GeneratedColumn<int>(
      'mastery_score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unlockedBloomLevelMeta =
      const VerificationMeta('unlockedBloomLevel');
  @override
  late final GeneratedColumn<int> unlockedBloomLevel = GeneratedColumn<int>(
      'unlocked_bloom_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _questionsMasteredMeta =
      const VerificationMeta('questionsMastered');
  @override
  late final GeneratedColumn<int> questionsMastered = GeneratedColumn<int>(
      'questions_mastered', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _levelCorrectCountMeta =
      const VerificationMeta('levelCorrectCount');
  @override
  late final GeneratedColumn<int> levelCorrectCount = GeneratedColumn<int>(
      'level_correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastStudiedAtMeta =
      const VerificationMeta('lastStudiedAt');
  @override
  late final GeneratedColumn<DateTime> lastStudiedAt =
      GeneratedColumn<DateTime>('last_studied_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        topicSlug,
        currentBloomLevel,
        currentStreak,
        consecutiveWrong,
        totalAnswered,
        correctAnswered,
        masteryScore,
        unlockedBloomLevel,
        questionsMastered,
        levelCorrectCount,
        lastStudiedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_progress';
  @override
  VerificationContext validateIntegrity(Insertable<TopicProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('topic_slug')) {
      context.handle(_topicSlugMeta,
          topicSlug.isAcceptableOrUnknown(data['topic_slug']!, _topicSlugMeta));
    }
    if (data.containsKey('current_bloom_level')) {
      context.handle(
          _currentBloomLevelMeta,
          currentBloomLevel.isAcceptableOrUnknown(
              data['current_bloom_level']!, _currentBloomLevelMeta));
    }
    if (data.containsKey('current_streak')) {
      context.handle(
          _currentStreakMeta,
          currentStreak.isAcceptableOrUnknown(
              data['current_streak']!, _currentStreakMeta));
    }
    if (data.containsKey('consecutive_wrong')) {
      context.handle(
          _consecutiveWrongMeta,
          consecutiveWrong.isAcceptableOrUnknown(
              data['consecutive_wrong']!, _consecutiveWrongMeta));
    }
    if (data.containsKey('total_answered')) {
      context.handle(
          _totalAnsweredMeta,
          totalAnswered.isAcceptableOrUnknown(
              data['total_answered']!, _totalAnsweredMeta));
    }
    if (data.containsKey('correct_answered')) {
      context.handle(
          _correctAnsweredMeta,
          correctAnswered.isAcceptableOrUnknown(
              data['correct_answered']!, _correctAnsweredMeta));
    }
    if (data.containsKey('mastery_score')) {
      context.handle(
          _masteryScoreMeta,
          masteryScore.isAcceptableOrUnknown(
              data['mastery_score']!, _masteryScoreMeta));
    }
    if (data.containsKey('unlocked_bloom_level')) {
      context.handle(
          _unlockedBloomLevelMeta,
          unlockedBloomLevel.isAcceptableOrUnknown(
              data['unlocked_bloom_level']!, _unlockedBloomLevelMeta));
    }
    if (data.containsKey('questions_mastered')) {
      context.handle(
          _questionsMasteredMeta,
          questionsMastered.isAcceptableOrUnknown(
              data['questions_mastered']!, _questionsMasteredMeta));
    }
    if (data.containsKey('level_correct_count')) {
      context.handle(
          _levelCorrectCountMeta,
          levelCorrectCount.isAcceptableOrUnknown(
              data['level_correct_count']!, _levelCorrectCountMeta));
    }
    if (data.containsKey('last_studied_at')) {
      context.handle(
          _lastStudiedAtMeta,
          lastStudiedAt.isAcceptableOrUnknown(
              data['last_studied_at']!, _lastStudiedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, topicSlug},
      ];
  @override
  TopicProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id']),
      topicSlug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic_slug']),
      currentBloomLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_bloom_level'])!,
      currentStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!,
      consecutiveWrong: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}consecutive_wrong'])!,
      totalAnswered: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_answered'])!,
      correctAnswered: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_answered'])!,
      masteryScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mastery_score'])!,
      unlockedBloomLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}unlocked_bloom_level'])!,
      questionsMastered: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}questions_mastered'])!,
      levelCorrectCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}level_correct_count'])!,
      lastStudiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_studied_at']),
    );
  }

  @override
  $TopicProgressTable createAlias(String alias) {
    return $TopicProgressTable(attachedDatabase, alias);
  }
}

class TopicProgressData extends DataClass
    implements Insertable<TopicProgressData> {
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
  final int levelCorrectCount;
  final DateTime? lastStudiedAt;
  const TopicProgressData(
      {required this.id,
      this.userId,
      this.topicSlug,
      required this.currentBloomLevel,
      required this.currentStreak,
      required this.consecutiveWrong,
      required this.totalAnswered,
      required this.correctAnswered,
      required this.masteryScore,
      required this.unlockedBloomLevel,
      required this.questionsMastered,
      required this.levelCorrectCount,
      this.lastStudiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || topicSlug != null) {
      map['topic_slug'] = Variable<String>(topicSlug);
    }
    map['current_bloom_level'] = Variable<int>(currentBloomLevel);
    map['current_streak'] = Variable<int>(currentStreak);
    map['consecutive_wrong'] = Variable<int>(consecutiveWrong);
    map['total_answered'] = Variable<int>(totalAnswered);
    map['correct_answered'] = Variable<int>(correctAnswered);
    map['mastery_score'] = Variable<int>(masteryScore);
    map['unlocked_bloom_level'] = Variable<int>(unlockedBloomLevel);
    map['questions_mastered'] = Variable<int>(questionsMastered);
    map['level_correct_count'] = Variable<int>(levelCorrectCount);
    if (!nullToAbsent || lastStudiedAt != null) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt);
    }
    return map;
  }

  TopicProgressCompanion toCompanion(bool nullToAbsent) {
    return TopicProgressCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      topicSlug: topicSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(topicSlug),
      currentBloomLevel: Value(currentBloomLevel),
      currentStreak: Value(currentStreak),
      consecutiveWrong: Value(consecutiveWrong),
      totalAnswered: Value(totalAnswered),
      correctAnswered: Value(correctAnswered),
      masteryScore: Value(masteryScore),
      unlockedBloomLevel: Value(unlockedBloomLevel),
      questionsMastered: Value(questionsMastered),
      levelCorrectCount: Value(levelCorrectCount),
      lastStudiedAt: lastStudiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudiedAt),
    );
  }

  factory TopicProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicProgressData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      topicSlug: serializer.fromJson<String?>(json['topicSlug']),
      currentBloomLevel: serializer.fromJson<int>(json['currentBloomLevel']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      consecutiveWrong: serializer.fromJson<int>(json['consecutiveWrong']),
      totalAnswered: serializer.fromJson<int>(json['totalAnswered']),
      correctAnswered: serializer.fromJson<int>(json['correctAnswered']),
      masteryScore: serializer.fromJson<int>(json['masteryScore']),
      unlockedBloomLevel: serializer.fromJson<int>(json['unlockedBloomLevel']),
      questionsMastered: serializer.fromJson<int>(json['questionsMastered']),
      levelCorrectCount: serializer.fromJson<int>(json['levelCorrectCount']),
      lastStudiedAt: serializer.fromJson<DateTime?>(json['lastStudiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'topicSlug': serializer.toJson<String?>(topicSlug),
      'currentBloomLevel': serializer.toJson<int>(currentBloomLevel),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'consecutiveWrong': serializer.toJson<int>(consecutiveWrong),
      'totalAnswered': serializer.toJson<int>(totalAnswered),
      'correctAnswered': serializer.toJson<int>(correctAnswered),
      'masteryScore': serializer.toJson<int>(masteryScore),
      'unlockedBloomLevel': serializer.toJson<int>(unlockedBloomLevel),
      'questionsMastered': serializer.toJson<int>(questionsMastered),
      'levelCorrectCount': serializer.toJson<int>(levelCorrectCount),
      'lastStudiedAt': serializer.toJson<DateTime?>(lastStudiedAt),
    };
  }

  TopicProgressData copyWith(
          {int? id,
          Value<int?> userId = const Value.absent(),
          Value<String?> topicSlug = const Value.absent(),
          int? currentBloomLevel,
          int? currentStreak,
          int? consecutiveWrong,
          int? totalAnswered,
          int? correctAnswered,
          int? masteryScore,
          int? unlockedBloomLevel,
          int? questionsMastered,
          int? levelCorrectCount,
          Value<DateTime?> lastStudiedAt = const Value.absent()}) =>
      TopicProgressData(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        topicSlug: topicSlug.present ? topicSlug.value : this.topicSlug,
        currentBloomLevel: currentBloomLevel ?? this.currentBloomLevel,
        currentStreak: currentStreak ?? this.currentStreak,
        consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
        totalAnswered: totalAnswered ?? this.totalAnswered,
        correctAnswered: correctAnswered ?? this.correctAnswered,
        masteryScore: masteryScore ?? this.masteryScore,
        unlockedBloomLevel: unlockedBloomLevel ?? this.unlockedBloomLevel,
        questionsMastered: questionsMastered ?? this.questionsMastered,
        levelCorrectCount: levelCorrectCount ?? this.levelCorrectCount,
        lastStudiedAt:
            lastStudiedAt.present ? lastStudiedAt.value : this.lastStudiedAt,
      );
  TopicProgressData copyWithCompanion(TopicProgressCompanion data) {
    return TopicProgressData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      topicSlug: data.topicSlug.present ? data.topicSlug.value : this.topicSlug,
      currentBloomLevel: data.currentBloomLevel.present
          ? data.currentBloomLevel.value
          : this.currentBloomLevel,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      consecutiveWrong: data.consecutiveWrong.present
          ? data.consecutiveWrong.value
          : this.consecutiveWrong,
      totalAnswered: data.totalAnswered.present
          ? data.totalAnswered.value
          : this.totalAnswered,
      correctAnswered: data.correctAnswered.present
          ? data.correctAnswered.value
          : this.correctAnswered,
      masteryScore: data.masteryScore.present
          ? data.masteryScore.value
          : this.masteryScore,
      unlockedBloomLevel: data.unlockedBloomLevel.present
          ? data.unlockedBloomLevel.value
          : this.unlockedBloomLevel,
      questionsMastered: data.questionsMastered.present
          ? data.questionsMastered.value
          : this.questionsMastered,
      levelCorrectCount: data.levelCorrectCount.present
          ? data.levelCorrectCount.value
          : this.levelCorrectCount,
      lastStudiedAt: data.lastStudiedAt.present
          ? data.lastStudiedAt.value
          : this.lastStudiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('topicSlug: $topicSlug, ')
          ..write('currentBloomLevel: $currentBloomLevel, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('consecutiveWrong: $consecutiveWrong, ')
          ..write('totalAnswered: $totalAnswered, ')
          ..write('correctAnswered: $correctAnswered, ')
          ..write('masteryScore: $masteryScore, ')
          ..write('unlockedBloomLevel: $unlockedBloomLevel, ')
          ..write('questionsMastered: $questionsMastered, ')
          ..write('levelCorrectCount: $levelCorrectCount, ')
          ..write('lastStudiedAt: $lastStudiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      topicSlug,
      currentBloomLevel,
      currentStreak,
      consecutiveWrong,
      totalAnswered,
      correctAnswered,
      masteryScore,
      unlockedBloomLevel,
      questionsMastered,
      levelCorrectCount,
      lastStudiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicProgressData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.topicSlug == this.topicSlug &&
          other.currentBloomLevel == this.currentBloomLevel &&
          other.currentStreak == this.currentStreak &&
          other.consecutiveWrong == this.consecutiveWrong &&
          other.totalAnswered == this.totalAnswered &&
          other.correctAnswered == this.correctAnswered &&
          other.masteryScore == this.masteryScore &&
          other.unlockedBloomLevel == this.unlockedBloomLevel &&
          other.questionsMastered == this.questionsMastered &&
          other.levelCorrectCount == this.levelCorrectCount &&
          other.lastStudiedAt == this.lastStudiedAt);
}

class TopicProgressCompanion extends UpdateCompanion<TopicProgressData> {
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
  final Value<int> levelCorrectCount;
  final Value<DateTime?> lastStudiedAt;
  const TopicProgressCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.topicSlug = const Value.absent(),
    this.currentBloomLevel = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.totalAnswered = const Value.absent(),
    this.correctAnswered = const Value.absent(),
    this.masteryScore = const Value.absent(),
    this.unlockedBloomLevel = const Value.absent(),
    this.questionsMastered = const Value.absent(),
    this.levelCorrectCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
  });
  TopicProgressCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.topicSlug = const Value.absent(),
    this.currentBloomLevel = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.totalAnswered = const Value.absent(),
    this.correctAnswered = const Value.absent(),
    this.masteryScore = const Value.absent(),
    this.unlockedBloomLevel = const Value.absent(),
    this.questionsMastered = const Value.absent(),
    this.levelCorrectCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
  });
  static Insertable<TopicProgressData> custom({
    Expression<int>? id,
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
    Expression<int>? levelCorrectCount,
    Expression<DateTime>? lastStudiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (topicSlug != null) 'topic_slug': topicSlug,
      if (currentBloomLevel != null) 'current_bloom_level': currentBloomLevel,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (consecutiveWrong != null) 'consecutive_wrong': consecutiveWrong,
      if (totalAnswered != null) 'total_answered': totalAnswered,
      if (correctAnswered != null) 'correct_answered': correctAnswered,
      if (masteryScore != null) 'mastery_score': masteryScore,
      if (unlockedBloomLevel != null)
        'unlocked_bloom_level': unlockedBloomLevel,
      if (questionsMastered != null) 'questions_mastered': questionsMastered,
      if (levelCorrectCount != null) 'level_correct_count': levelCorrectCount,
      if (lastStudiedAt != null) 'last_studied_at': lastStudiedAt,
    });
  }

  TopicProgressCompanion copyWith(
      {Value<int>? id,
      Value<int?>? userId,
      Value<String?>? topicSlug,
      Value<int>? currentBloomLevel,
      Value<int>? currentStreak,
      Value<int>? consecutiveWrong,
      Value<int>? totalAnswered,
      Value<int>? correctAnswered,
      Value<int>? masteryScore,
      Value<int>? unlockedBloomLevel,
      Value<int>? questionsMastered,
      Value<int>? levelCorrectCount,
      Value<DateTime?>? lastStudiedAt}) {
    return TopicProgressCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicSlug: topicSlug ?? this.topicSlug,
      currentBloomLevel: currentBloomLevel ?? this.currentBloomLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      correctAnswered: correctAnswered ?? this.correctAnswered,
      masteryScore: masteryScore ?? this.masteryScore,
      unlockedBloomLevel: unlockedBloomLevel ?? this.unlockedBloomLevel,
      questionsMastered: questionsMastered ?? this.questionsMastered,
      levelCorrectCount: levelCorrectCount ?? this.levelCorrectCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (topicSlug.present) {
      map['topic_slug'] = Variable<String>(topicSlug.value);
    }
    if (currentBloomLevel.present) {
      map['current_bloom_level'] = Variable<int>(currentBloomLevel.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (consecutiveWrong.present) {
      map['consecutive_wrong'] = Variable<int>(consecutiveWrong.value);
    }
    if (totalAnswered.present) {
      map['total_answered'] = Variable<int>(totalAnswered.value);
    }
    if (correctAnswered.present) {
      map['correct_answered'] = Variable<int>(correctAnswered.value);
    }
    if (masteryScore.present) {
      map['mastery_score'] = Variable<int>(masteryScore.value);
    }
    if (unlockedBloomLevel.present) {
      map['unlocked_bloom_level'] = Variable<int>(unlockedBloomLevel.value);
    }
    if (questionsMastered.present) {
      map['questions_mastered'] = Variable<int>(questionsMastered.value);
    }
    if (levelCorrectCount.present) {
      map['level_correct_count'] = Variable<int>(levelCorrectCount.value);
    }
    if (lastStudiedAt.present) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('topicSlug: $topicSlug, ')
          ..write('currentBloomLevel: $currentBloomLevel, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('consecutiveWrong: $consecutiveWrong, ')
          ..write('totalAnswered: $totalAnswered, ')
          ..write('correctAnswered: $correctAnswered, ')
          ..write('masteryScore: $masteryScore, ')
          ..write('unlockedBloomLevel: $unlockedBloomLevel, ')
          ..write('questionsMastered: $questionsMastered, ')
          ..write('levelCorrectCount: $levelCorrectCount, ')
          ..write('lastStudiedAt: $lastStudiedAt')
          ..write(')'))
        .toString();
  }
}

class $QuestionProgressTable extends QuestionProgress
    with TableInfo<$QuestionProgressTable, QuestionProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
      'question_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
      'box', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _consecutiveCorrectMeta =
      const VerificationMeta('consecutiveCorrect');
  @override
  late final GeneratedColumn<int> consecutiveCorrect = GeneratedColumn<int>(
      'consecutive_correct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _masteredMeta =
      const VerificationMeta('mastered');
  @override
  late final GeneratedColumn<bool> mastered = GeneratedColumn<bool>(
      'mastered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("mastered" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _nextReviewAtMeta =
      const VerificationMeta('nextReviewAt');
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
      'next_review_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastAnsweredAtMeta =
      const VerificationMeta('lastAnsweredAt');
  @override
  late final GeneratedColumn<DateTime> lastAnsweredAt =
      GeneratedColumn<DateTime>('last_answered_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        questionId,
        box,
        consecutiveCorrect,
        mastered,
        nextReviewAt,
        lastAnsweredAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<QuestionProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    }
    if (data.containsKey('box')) {
      context.handle(
          _boxMeta, box.isAcceptableOrUnknown(data['box']!, _boxMeta));
    }
    if (data.containsKey('consecutive_correct')) {
      context.handle(
          _consecutiveCorrectMeta,
          consecutiveCorrect.isAcceptableOrUnknown(
              data['consecutive_correct']!, _consecutiveCorrectMeta));
    }
    if (data.containsKey('mastered')) {
      context.handle(_masteredMeta,
          mastered.isAcceptableOrUnknown(data['mastered']!, _masteredMeta));
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
          _nextReviewAtMeta,
          nextReviewAt.isAcceptableOrUnknown(
              data['next_review_at']!, _nextReviewAtMeta));
    }
    if (data.containsKey('last_answered_at')) {
      context.handle(
          _lastAnsweredAtMeta,
          lastAnsweredAt.isAcceptableOrUnknown(
              data['last_answered_at']!, _lastAnsweredAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, questionId},
      ];
  @override
  QuestionProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id']),
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_id']),
      box: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}box'])!,
      consecutiveCorrect: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}consecutive_correct'])!,
      mastered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}mastered'])!,
      nextReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_review_at']),
      lastAnsweredAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_answered_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $QuestionProgressTable createAlias(String alias) {
    return $QuestionProgressTable(attachedDatabase, alias);
  }
}

class QuestionProgressData extends DataClass
    implements Insertable<QuestionProgressData> {
  final int id;
  final int? userId;
  final int? questionId;
  final int box;
  final int consecutiveCorrect;
  final bool mastered;
  final DateTime? nextReviewAt;
  final DateTime? lastAnsweredAt;
  final DateTime? updatedAt;
  const QuestionProgressData(
      {required this.id,
      this.userId,
      this.questionId,
      required this.box,
      required this.consecutiveCorrect,
      required this.mastered,
      this.nextReviewAt,
      this.lastAnsweredAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || questionId != null) {
      map['question_id'] = Variable<int>(questionId);
    }
    map['box'] = Variable<int>(box);
    map['consecutive_correct'] = Variable<int>(consecutiveCorrect);
    map['mastered'] = Variable<bool>(mastered);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    if (!nullToAbsent || lastAnsweredAt != null) {
      map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  QuestionProgressCompanion toCompanion(bool nullToAbsent) {
    return QuestionProgressCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      questionId: questionId == null && nullToAbsent
          ? const Value.absent()
          : Value(questionId),
      box: Value(box),
      consecutiveCorrect: Value(consecutiveCorrect),
      mastered: Value(mastered),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      lastAnsweredAt: lastAnsweredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAnsweredAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory QuestionProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionProgressData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      questionId: serializer.fromJson<int?>(json['questionId']),
      box: serializer.fromJson<int>(json['box']),
      consecutiveCorrect: serializer.fromJson<int>(json['consecutiveCorrect']),
      mastered: serializer.fromJson<bool>(json['mastered']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      lastAnsweredAt: serializer.fromJson<DateTime?>(json['lastAnsweredAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'questionId': serializer.toJson<int?>(questionId),
      'box': serializer.toJson<int>(box),
      'consecutiveCorrect': serializer.toJson<int>(consecutiveCorrect),
      'mastered': serializer.toJson<bool>(mastered),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'lastAnsweredAt': serializer.toJson<DateTime?>(lastAnsweredAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  QuestionProgressData copyWith(
          {int? id,
          Value<int?> userId = const Value.absent(),
          Value<int?> questionId = const Value.absent(),
          int? box,
          int? consecutiveCorrect,
          bool? mastered,
          Value<DateTime?> nextReviewAt = const Value.absent(),
          Value<DateTime?> lastAnsweredAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      QuestionProgressData(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        questionId: questionId.present ? questionId.value : this.questionId,
        box: box ?? this.box,
        consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
        mastered: mastered ?? this.mastered,
        nextReviewAt:
            nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
        lastAnsweredAt:
            lastAnsweredAt.present ? lastAnsweredAt.value : this.lastAnsweredAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  QuestionProgressData copyWithCompanion(QuestionProgressCompanion data) {
    return QuestionProgressData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      box: data.box.present ? data.box.value : this.box,
      consecutiveCorrect: data.consecutiveCorrect.present
          ? data.consecutiveCorrect.value
          : this.consecutiveCorrect,
      mastered: data.mastered.present ? data.mastered.value : this.mastered,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      lastAnsweredAt: data.lastAnsweredAt.present
          ? data.lastAnsweredAt.value
          : this.lastAnsweredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionProgressData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('box: $box, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('mastered: $mastered, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastAnsweredAt: $lastAnsweredAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, questionId, box,
      consecutiveCorrect, mastered, nextReviewAt, lastAnsweredAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionProgressData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.questionId == this.questionId &&
          other.box == this.box &&
          other.consecutiveCorrect == this.consecutiveCorrect &&
          other.mastered == this.mastered &&
          other.nextReviewAt == this.nextReviewAt &&
          other.lastAnsweredAt == this.lastAnsweredAt &&
          other.updatedAt == this.updatedAt);
}

class QuestionProgressCompanion extends UpdateCompanion<QuestionProgressData> {
  final Value<int> id;
  final Value<int?> userId;
  final Value<int?> questionId;
  final Value<int> box;
  final Value<int> consecutiveCorrect;
  final Value<bool> mastered;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime?> lastAnsweredAt;
  final Value<DateTime?> updatedAt;
  const QuestionProgressCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.box = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.mastered = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastAnsweredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QuestionProgressCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.box = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.mastered = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastAnsweredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<QuestionProgressData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? questionId,
    Expression<int>? box,
    Expression<int>? consecutiveCorrect,
    Expression<bool>? mastered,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? lastAnsweredAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      if (box != null) 'box': box,
      if (consecutiveCorrect != null) 'consecutive_correct': consecutiveCorrect,
      if (mastered != null) 'mastered': mastered,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (lastAnsweredAt != null) 'last_answered_at': lastAnsweredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QuestionProgressCompanion copyWith(
      {Value<int>? id,
      Value<int?>? userId,
      Value<int?>? questionId,
      Value<int>? box,
      Value<int>? consecutiveCorrect,
      Value<bool>? mastered,
      Value<DateTime?>? nextReviewAt,
      Value<DateTime?>? lastAnsweredAt,
      Value<DateTime?>? updatedAt}) {
    return QuestionProgressCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      box: box ?? this.box,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      mastered: mastered ?? this.mastered,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (consecutiveCorrect.present) {
      map['consecutive_correct'] = Variable<int>(consecutiveCorrect.value);
    }
    if (mastered.present) {
      map['mastered'] = Variable<bool>(mastered.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (lastAnsweredAt.present) {
      map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionProgressCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('box: $box, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('mastered: $mastered, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastAnsweredAt: $lastAnsweredAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _slotTypeMeta =
      const VerificationMeta('slotType');
  @override
  late final GeneratedColumn<String> slotType = GeneratedColumn<String>(
      'slot_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _assetPathMeta =
      const VerificationMeta('assetPath');
  @override
  late final GeneratedColumn<String> assetPath = GeneratedColumn<String>(
      'asset_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
      'theme', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPremiumMeta =
      const VerificationMeta('isPremium');
  @override
  late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>(
      'is_premium', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_premium" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        name,
        type,
        slotType,
        price,
        assetPath,
        description,
        theme,
        isPremium
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<Item> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('slot_type')) {
      context.handle(_slotTypeMeta,
          slotType.isAcceptableOrUnknown(data['slot_type']!, _slotTypeMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('asset_path')) {
      context.handle(_assetPathMeta,
          assetPath.isAcceptableOrUnknown(data['asset_path']!, _assetPathMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(
          _themeMeta, theme.isAcceptableOrUnknown(data['theme']!, _themeMeta));
    }
    if (data.containsKey('is_premium')) {
      context.handle(_isPremiumMeta,
          isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type']),
      slotType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot_type']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price']),
      assetPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_path']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      theme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme']),
      isPremium: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_premium'])!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
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
  const Item(
      {required this.id,
      this.serverId,
      this.name,
      this.type,
      this.slotType,
      this.price,
      this.assetPath,
      this.description,
      this.theme,
      required this.isPremium});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || slotType != null) {
      map['slot_type'] = Variable<String>(slotType);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<int>(price);
    }
    if (!nullToAbsent || assetPath != null) {
      map['asset_path'] = Variable<String>(assetPath);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || theme != null) {
      map['theme'] = Variable<String>(theme);
    }
    map['is_premium'] = Variable<bool>(isPremium);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      slotType: slotType == null && nullToAbsent
          ? const Value.absent()
          : Value(slotType),
      price:
          price == null && nullToAbsent ? const Value.absent() : Value(price),
      assetPath: assetPath == null && nullToAbsent
          ? const Value.absent()
          : Value(assetPath),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      theme:
          theme == null && nullToAbsent ? const Value.absent() : Value(theme),
      isPremium: Value(isPremium),
    );
  }

  factory Item.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      slotType: serializer.fromJson<String?>(json['slotType']),
      price: serializer.fromJson<int?>(json['price']),
      assetPath: serializer.fromJson<String?>(json['assetPath']),
      description: serializer.fromJson<String?>(json['description']),
      theme: serializer.fromJson<String?>(json['theme']),
      isPremium: serializer.fromJson<bool>(json['isPremium']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String?>(type),
      'slotType': serializer.toJson<String?>(slotType),
      'price': serializer.toJson<int?>(price),
      'assetPath': serializer.toJson<String?>(assetPath),
      'description': serializer.toJson<String?>(description),
      'theme': serializer.toJson<String?>(theme),
      'isPremium': serializer.toJson<bool>(isPremium),
    };
  }

  Item copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> type = const Value.absent(),
          Value<String?> slotType = const Value.absent(),
          Value<int?> price = const Value.absent(),
          Value<String?> assetPath = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> theme = const Value.absent(),
          bool? isPremium}) =>
      Item(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        name: name.present ? name.value : this.name,
        type: type.present ? type.value : this.type,
        slotType: slotType.present ? slotType.value : this.slotType,
        price: price.present ? price.value : this.price,
        assetPath: assetPath.present ? assetPath.value : this.assetPath,
        description: description.present ? description.value : this.description,
        theme: theme.present ? theme.value : this.theme,
        isPremium: isPremium ?? this.isPremium,
      );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      slotType: data.slotType.present ? data.slotType.value : this.slotType,
      price: data.price.present ? data.price.value : this.price,
      assetPath: data.assetPath.present ? data.assetPath.value : this.assetPath,
      description:
          data.description.present ? data.description.value : this.description,
      theme: data.theme.present ? data.theme.value : this.theme,
      isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('slotType: $slotType, ')
          ..write('price: $price, ')
          ..write('assetPath: $assetPath, ')
          ..write('description: $description, ')
          ..write('theme: $theme, ')
          ..write('isPremium: $isPremium')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, name, type, slotType, price,
      assetPath, description, theme, isPremium);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.type == this.type &&
          other.slotType == this.slotType &&
          other.price == this.price &&
          other.assetPath == this.assetPath &&
          other.description == this.description &&
          other.theme == this.theme &&
          other.isPremium == this.isPremium);
}

class ItemsCompanion extends UpdateCompanion<Item> {
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
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.slotType = const Value.absent(),
    this.price = const Value.absent(),
    this.assetPath = const Value.absent(),
    this.description = const Value.absent(),
    this.theme = const Value.absent(),
    this.isPremium = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.slotType = const Value.absent(),
    this.price = const Value.absent(),
    this.assetPath = const Value.absent(),
    this.description = const Value.absent(),
    this.theme = const Value.absent(),
    this.isPremium = const Value.absent(),
  });
  static Insertable<Item> custom({
    Expression<int>? id,
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
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (slotType != null) 'slot_type': slotType,
      if (price != null) 'price': price,
      if (assetPath != null) 'asset_path': assetPath,
      if (description != null) 'description': description,
      if (theme != null) 'theme': theme,
      if (isPremium != null) 'is_premium': isPremium,
    });
  }

  ItemsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String?>? name,
      Value<String?>? type,
      Value<String?>? slotType,
      Value<int?>? price,
      Value<String?>? assetPath,
      Value<String?>? description,
      Value<String?>? theme,
      Value<bool>? isPremium}) {
    return ItemsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      type: type ?? this.type,
      slotType: slotType ?? this.slotType,
      price: price ?? this.price,
      assetPath: assetPath ?? this.assetPath,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (slotType.present) {
      map['slot_type'] = Variable<String>(slotType.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (assetPath.present) {
      map['asset_path'] = Variable<String>(assetPath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (isPremium.present) {
      map['is_premium'] = Variable<bool>(isPremium.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('slotType: $slotType, ')
          ..write('price: $price, ')
          ..write('assetPath: $assetPath, ')
          ..write('description: $description, ')
          ..write('theme: $theme, ')
          ..write('isPremium: $isPremium')
          ..write(')'))
        .toString();
  }
}

class $UserItemsTable extends UserItems
    with TableInfo<$UserItemsTable, UserItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isPlacedMeta =
      const VerificationMeta('isPlaced');
  @override
  late final GeneratedColumn<bool> isPlaced = GeneratedColumn<bool>(
      'is_placed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_placed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<int> roomId = GeneratedColumn<int>(
      'room_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xPosMeta = const VerificationMeta('xPos');
  @override
  late final GeneratedColumn<int> xPos = GeneratedColumn<int>(
      'x_pos', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _yPosMeta = const VerificationMeta('yPos');
  @override
  late final GeneratedColumn<int> yPos = GeneratedColumn<int>(
      'y_pos', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, serverId, userId, itemId, isPlaced, roomId, slot, xPos, yPos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_items';
  @override
  VerificationContext validateIntegrity(Insertable<UserItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    }
    if (data.containsKey('is_placed')) {
      context.handle(_isPlacedMeta,
          isPlaced.isAcceptableOrUnknown(data['is_placed']!, _isPlacedMeta));
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('x_pos')) {
      context.handle(
          _xPosMeta, xPos.isAcceptableOrUnknown(data['x_pos']!, _xPosMeta));
    }
    if (data.containsKey('y_pos')) {
      context.handle(
          _yPosMeta, yPos.isAcceptableOrUnknown(data['y_pos']!, _yPosMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id']),
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id']),
      isPlaced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_placed'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_id']),
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot']),
      xPos: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}x_pos'])!,
      yPos: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}y_pos'])!,
    );
  }

  @override
  $UserItemsTable createAlias(String alias) {
    return $UserItemsTable(attachedDatabase, alias);
  }
}

class UserItem extends DataClass implements Insertable<UserItem> {
  final int id;
  final int? serverId;
  final int? userId;
  final int? itemId;
  final bool isPlaced;
  final int? roomId;
  final String? slot;
  final int xPos;
  final int yPos;
  const UserItem(
      {required this.id,
      this.serverId,
      this.userId,
      this.itemId,
      required this.isPlaced,
      this.roomId,
      this.slot,
      required this.xPos,
      required this.yPos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<int>(itemId);
    }
    map['is_placed'] = Variable<bool>(isPlaced);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<int>(roomId);
    }
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<String>(slot);
    }
    map['x_pos'] = Variable<int>(xPos);
    map['y_pos'] = Variable<int>(yPos);
    return map;
  }

  UserItemsCompanion toCompanion(bool nullToAbsent) {
    return UserItemsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      itemId:
          itemId == null && nullToAbsent ? const Value.absent() : Value(itemId),
      isPlaced: Value(isPlaced),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      xPos: Value(xPos),
      yPos: Value(yPos),
    );
  }

  factory UserItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserItem(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      userId: serializer.fromJson<int?>(json['userId']),
      itemId: serializer.fromJson<int?>(json['itemId']),
      isPlaced: serializer.fromJson<bool>(json['isPlaced']),
      roomId: serializer.fromJson<int?>(json['roomId']),
      slot: serializer.fromJson<String?>(json['slot']),
      xPos: serializer.fromJson<int>(json['xPos']),
      yPos: serializer.fromJson<int>(json['yPos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'userId': serializer.toJson<int?>(userId),
      'itemId': serializer.toJson<int?>(itemId),
      'isPlaced': serializer.toJson<bool>(isPlaced),
      'roomId': serializer.toJson<int?>(roomId),
      'slot': serializer.toJson<String?>(slot),
      'xPos': serializer.toJson<int>(xPos),
      'yPos': serializer.toJson<int>(yPos),
    };
  }

  UserItem copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          Value<int?> userId = const Value.absent(),
          Value<int?> itemId = const Value.absent(),
          bool? isPlaced,
          Value<int?> roomId = const Value.absent(),
          Value<String?> slot = const Value.absent(),
          int? xPos,
          int? yPos}) =>
      UserItem(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        userId: userId.present ? userId.value : this.userId,
        itemId: itemId.present ? itemId.value : this.itemId,
        isPlaced: isPlaced ?? this.isPlaced,
        roomId: roomId.present ? roomId.value : this.roomId,
        slot: slot.present ? slot.value : this.slot,
        xPos: xPos ?? this.xPos,
        yPos: yPos ?? this.yPos,
      );
  UserItem copyWithCompanion(UserItemsCompanion data) {
    return UserItem(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      isPlaced: data.isPlaced.present ? data.isPlaced.value : this.isPlaced,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      slot: data.slot.present ? data.slot.value : this.slot,
      xPos: data.xPos.present ? data.xPos.value : this.xPos,
      yPos: data.yPos.present ? data.yPos.value : this.yPos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserItem(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('isPlaced: $isPlaced, ')
          ..write('roomId: $roomId, ')
          ..write('slot: $slot, ')
          ..write('xPos: $xPos, ')
          ..write('yPos: $yPos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, serverId, userId, itemId, isPlaced, roomId, slot, xPos, yPos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserItem &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.isPlaced == this.isPlaced &&
          other.roomId == this.roomId &&
          other.slot == this.slot &&
          other.xPos == this.xPos &&
          other.yPos == this.yPos);
}

class UserItemsCompanion extends UpdateCompanion<UserItem> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int?> userId;
  final Value<int?> itemId;
  final Value<bool> isPlaced;
  final Value<int?> roomId;
  final Value<String?> slot;
  final Value<int> xPos;
  final Value<int> yPos;
  const UserItemsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.isPlaced = const Value.absent(),
    this.roomId = const Value.absent(),
    this.slot = const Value.absent(),
    this.xPos = const Value.absent(),
    this.yPos = const Value.absent(),
  });
  UserItemsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.isPlaced = const Value.absent(),
    this.roomId = const Value.absent(),
    this.slot = const Value.absent(),
    this.xPos = const Value.absent(),
    this.yPos = const Value.absent(),
  });
  static Insertable<UserItem> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? userId,
    Expression<int>? itemId,
    Expression<bool>? isPlaced,
    Expression<int>? roomId,
    Expression<String>? slot,
    Expression<int>? xPos,
    Expression<int>? yPos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (isPlaced != null) 'is_placed': isPlaced,
      if (roomId != null) 'room_id': roomId,
      if (slot != null) 'slot': slot,
      if (xPos != null) 'x_pos': xPos,
      if (yPos != null) 'y_pos': yPos,
    });
  }

  UserItemsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int?>? userId,
      Value<int?>? itemId,
      Value<bool>? isPlaced,
      Value<int?>? roomId,
      Value<String?>? slot,
      Value<int>? xPos,
      Value<int>? yPos}) {
    return UserItemsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      isPlaced: isPlaced ?? this.isPlaced,
      roomId: roomId ?? this.roomId,
      slot: slot ?? this.slot,
      xPos: xPos ?? this.xPos,
      yPos: yPos ?? this.yPos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (isPlaced.present) {
      map['is_placed'] = Variable<bool>(isPlaced.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<int>(roomId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (xPos.present) {
      map['x_pos'] = Variable<int>(xPos.value);
    }
    if (yPos.present) {
      map['y_pos'] = Variable<int>(yPos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserItemsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('isPlaced: $isPlaced, ')
          ..write('roomId: $roomId, ')
          ..write('slot: $slot, ')
          ..write('xPos: $xPos, ')
          ..write('yPos: $yPos')
          ..write(')'))
        .toString();
  }
}

class $EcgCasesTable extends EcgCases with TableInfo<$EcgCasesTable, EcgCase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcgCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetPathMeta =
      const VerificationMeta('assetPath');
  @override
  late final GeneratedColumn<String> assetPath = GeneratedColumn<String>(
      'asset_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctDiagnosesMeta =
      const VerificationMeta('correctDiagnoses');
  @override
  late final GeneratedColumn<String> correctDiagnoses = GeneratedColumn<String>(
      'correct_diagnoses', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, description, type, difficulty, assetPath, correctDiagnoses];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecg_cases';
  @override
  VerificationContext validateIntegrity(Insertable<EcgCase> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('asset_path')) {
      context.handle(_assetPathMeta,
          assetPath.isAcceptableOrUnknown(data['asset_path']!, _assetPathMeta));
    } else if (isInserting) {
      context.missing(_assetPathMeta);
    }
    if (data.containsKey('correct_diagnoses')) {
      context.handle(
          _correctDiagnosesMeta,
          correctDiagnoses.isAcceptableOrUnknown(
              data['correct_diagnoses']!, _correctDiagnosesMeta));
    } else if (isInserting) {
      context.missing(_correctDiagnosesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EcgCase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcgCase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      assetPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_path'])!,
      correctDiagnoses: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}correct_diagnoses'])!,
    );
  }

  @override
  $EcgCasesTable createAlias(String alias) {
    return $EcgCasesTable(attachedDatabase, alias);
  }
}

class EcgCase extends DataClass implements Insertable<EcgCase> {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String difficulty;
  final String assetPath;
  final String correctDiagnoses;
  const EcgCase(
      {required this.id,
      required this.title,
      this.description,
      required this.type,
      required this.difficulty,
      required this.assetPath,
      required this.correctDiagnoses});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<String>(type);
    map['difficulty'] = Variable<String>(difficulty);
    map['asset_path'] = Variable<String>(assetPath);
    map['correct_diagnoses'] = Variable<String>(correctDiagnoses);
    return map;
  }

  EcgCasesCompanion toCompanion(bool nullToAbsent) {
    return EcgCasesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      difficulty: Value(difficulty),
      assetPath: Value(assetPath),
      correctDiagnoses: Value(correctDiagnoses),
    );
  }

  factory EcgCase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcgCase(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      assetPath: serializer.fromJson<String>(json['assetPath']),
      correctDiagnoses: serializer.fromJson<String>(json['correctDiagnoses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String>(type),
      'difficulty': serializer.toJson<String>(difficulty),
      'assetPath': serializer.toJson<String>(assetPath),
      'correctDiagnoses': serializer.toJson<String>(correctDiagnoses),
    };
  }

  EcgCase copyWith(
          {int? id,
          String? title,
          Value<String?> description = const Value.absent(),
          String? type,
          String? difficulty,
          String? assetPath,
          String? correctDiagnoses}) =>
      EcgCase(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        type: type ?? this.type,
        difficulty: difficulty ?? this.difficulty,
        assetPath: assetPath ?? this.assetPath,
        correctDiagnoses: correctDiagnoses ?? this.correctDiagnoses,
      );
  EcgCase copyWithCompanion(EcgCasesCompanion data) {
    return EcgCase(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      assetPath: data.assetPath.present ? data.assetPath.value : this.assetPath,
      correctDiagnoses: data.correctDiagnoses.present
          ? data.correctDiagnoses.value
          : this.correctDiagnoses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcgCase(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('difficulty: $difficulty, ')
          ..write('assetPath: $assetPath, ')
          ..write('correctDiagnoses: $correctDiagnoses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, description, type, difficulty, assetPath, correctDiagnoses);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcgCase &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.difficulty == this.difficulty &&
          other.assetPath == this.assetPath &&
          other.correctDiagnoses == this.correctDiagnoses);
}

class EcgCasesCompanion extends UpdateCompanion<EcgCase> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<String> difficulty;
  final Value<String> assetPath;
  final Value<String> correctDiagnoses;
  const EcgCasesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.assetPath = const Value.absent(),
    this.correctDiagnoses = const Value.absent(),
  });
  EcgCasesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String type,
    required String difficulty,
    required String assetPath,
    required String correctDiagnoses,
  })  : title = Value(title),
        type = Value(type),
        difficulty = Value(difficulty),
        assetPath = Value(assetPath),
        correctDiagnoses = Value(correctDiagnoses);
  static Insertable<EcgCase> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? difficulty,
    Expression<String>? assetPath,
    Expression<String>? correctDiagnoses,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (difficulty != null) 'difficulty': difficulty,
      if (assetPath != null) 'asset_path': assetPath,
      if (correctDiagnoses != null) 'correct_diagnoses': correctDiagnoses,
    });
  }

  EcgCasesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? type,
      Value<String>? difficulty,
      Value<String>? assetPath,
      Value<String>? correctDiagnoses}) {
    return EcgCasesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      assetPath: assetPath ?? this.assetPath,
      correctDiagnoses: correctDiagnoses ?? this.correctDiagnoses,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (assetPath.present) {
      map['asset_path'] = Variable<String>(assetPath.value);
    }
    if (correctDiagnoses.present) {
      map['correct_diagnoses'] = Variable<String>(correctDiagnoses.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcgCasesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('difficulty: $difficulty, ')
          ..write('assetPath: $assetPath, ')
          ..write('correctDiagnoses: $correctDiagnoses')
          ..write(')'))
        .toString();
  }
}

class $EcgDiagnosesTable extends EcgDiagnoses
    with TableInfo<$EcgDiagnosesTable, EcgDiagnose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcgDiagnosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecg_diagnoses';
  @override
  VerificationContext validateIntegrity(Insertable<EcgDiagnose> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EcgDiagnose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcgDiagnose(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
    );
  }

  @override
  $EcgDiagnosesTable createAlias(String alias) {
    return $EcgDiagnosesTable(attachedDatabase, alias);
  }
}

class EcgDiagnose extends DataClass implements Insertable<EcgDiagnose> {
  final String id;
  final String name;
  final String? description;
  const EcgDiagnose({required this.id, required this.name, this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  EcgDiagnosesCompanion toCompanion(bool nullToAbsent) {
    return EcgDiagnosesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory EcgDiagnose.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcgDiagnose(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
    };
  }

  EcgDiagnose copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent()}) =>
      EcgDiagnose(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
      );
  EcgDiagnose copyWithCompanion(EcgDiagnosesCompanion data) {
    return EcgDiagnose(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcgDiagnose(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcgDiagnose &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description);
}

class EcgDiagnosesCompanion extends UpdateCompanion<EcgDiagnose> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> rowid;
  const EcgDiagnosesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EcgDiagnosesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<EcgDiagnose> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EcgDiagnosesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<int>? rowid}) {
    return EcgDiagnosesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcgDiagnosesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FurnitureTable extends Furniture
    with TableInfo<$FurnitureTable, FurnitureData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FurnitureTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameHuMeta = const VerificationMeta('nameHu');
  @override
  late final GeneratedColumn<String> nameHu = GeneratedColumn<String>(
      'name_hu', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assetPathMeta =
      const VerificationMeta('assetPath');
  @override
  late final GeneratedColumn<String> assetPath = GeneratedColumn<String>(
      'asset_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isPlacedMeta =
      const VerificationMeta('isPlaced');
  @override
  late final GeneratedColumn<bool> isPlaced = GeneratedColumn<bool>(
      'is_placed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_placed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
      'unlocked_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        slug,
        nameEn,
        nameHu,
        assetPath,
        type,
        price,
        isLocked,
        isPlaced,
        unlockedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'furniture';
  @override
  VerificationContext validateIntegrity(Insertable<FurnitureData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    }
    if (data.containsKey('name_hu')) {
      context.handle(_nameHuMeta,
          nameHu.isAcceptableOrUnknown(data['name_hu']!, _nameHuMeta));
    }
    if (data.containsKey('asset_path')) {
      context.handle(_assetPathMeta,
          assetPath.isAcceptableOrUnknown(data['asset_path']!, _assetPathMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('is_placed')) {
      context.handle(_isPlacedMeta,
          isPlaced.isAcceptableOrUnknown(data['is_placed']!, _isPlacedMeta));
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FurnitureData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FurnitureData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en']),
      nameHu: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_hu']),
      assetPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_path']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price'])!,
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      isPlaced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_placed'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlocked_at']),
    );
  }

  @override
  $FurnitureTable createAlias(String alias) {
    return $FurnitureTable(attachedDatabase, alias);
  }
}

class FurnitureData extends DataClass implements Insertable<FurnitureData> {
  final int id;
  final String slug;
  final String? nameEn;
  final String? nameHu;
  final String? assetPath;
  final String? type;
  final int price;
  final bool isLocked;
  final bool isPlaced;
  final DateTime? unlockedAt;
  const FurnitureData(
      {required this.id,
      required this.slug,
      this.nameEn,
      this.nameHu,
      this.assetPath,
      this.type,
      required this.price,
      required this.isLocked,
      required this.isPlaced,
      this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    if (!nullToAbsent || nameHu != null) {
      map['name_hu'] = Variable<String>(nameHu);
    }
    if (!nullToAbsent || assetPath != null) {
      map['asset_path'] = Variable<String>(assetPath);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    map['price'] = Variable<int>(price);
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_placed'] = Variable<bool>(isPlaced);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    }
    return map;
  }

  FurnitureCompanion toCompanion(bool nullToAbsent) {
    return FurnitureCompanion(
      id: Value(id),
      slug: Value(slug),
      nameEn:
          nameEn == null && nullToAbsent ? const Value.absent() : Value(nameEn),
      nameHu:
          nameHu == null && nullToAbsent ? const Value.absent() : Value(nameHu),
      assetPath: assetPath == null && nullToAbsent
          ? const Value.absent()
          : Value(assetPath),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      price: Value(price),
      isLocked: Value(isLocked),
      isPlaced: Value(isPlaced),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
    );
  }

  factory FurnitureData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FurnitureData(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      nameHu: serializer.fromJson<String?>(json['nameHu']),
      assetPath: serializer.fromJson<String?>(json['assetPath']),
      type: serializer.fromJson<String?>(json['type']),
      price: serializer.fromJson<int>(json['price']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isPlaced: serializer.fromJson<bool>(json['isPlaced']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
      'nameEn': serializer.toJson<String?>(nameEn),
      'nameHu': serializer.toJson<String?>(nameHu),
      'assetPath': serializer.toJson<String?>(assetPath),
      'type': serializer.toJson<String?>(type),
      'price': serializer.toJson<int>(price),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isPlaced': serializer.toJson<bool>(isPlaced),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
    };
  }

  FurnitureData copyWith(
          {int? id,
          String? slug,
          Value<String?> nameEn = const Value.absent(),
          Value<String?> nameHu = const Value.absent(),
          Value<String?> assetPath = const Value.absent(),
          Value<String?> type = const Value.absent(),
          int? price,
          bool? isLocked,
          bool? isPlaced,
          Value<DateTime?> unlockedAt = const Value.absent()}) =>
      FurnitureData(
        id: id ?? this.id,
        slug: slug ?? this.slug,
        nameEn: nameEn.present ? nameEn.value : this.nameEn,
        nameHu: nameHu.present ? nameHu.value : this.nameHu,
        assetPath: assetPath.present ? assetPath.value : this.assetPath,
        type: type.present ? type.value : this.type,
        price: price ?? this.price,
        isLocked: isLocked ?? this.isLocked,
        isPlaced: isPlaced ?? this.isPlaced,
        unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
      );
  FurnitureData copyWithCompanion(FurnitureCompanion data) {
    return FurnitureData(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameHu: data.nameHu.present ? data.nameHu.value : this.nameHu,
      assetPath: data.assetPath.present ? data.assetPath.value : this.assetPath,
      type: data.type.present ? data.type.value : this.type,
      price: data.price.present ? data.price.value : this.price,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isPlaced: data.isPlaced.present ? data.isPlaced.value : this.isPlaced,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FurnitureData(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameHu: $nameHu, ')
          ..write('assetPath: $assetPath, ')
          ..write('type: $type, ')
          ..write('price: $price, ')
          ..write('isLocked: $isLocked, ')
          ..write('isPlaced: $isPlaced, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, nameEn, nameHu, assetPath, type,
      price, isLocked, isPlaced, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FurnitureData &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.nameEn == this.nameEn &&
          other.nameHu == this.nameHu &&
          other.assetPath == this.assetPath &&
          other.type == this.type &&
          other.price == this.price &&
          other.isLocked == this.isLocked &&
          other.isPlaced == this.isPlaced &&
          other.unlockedAt == this.unlockedAt);
}

class FurnitureCompanion extends UpdateCompanion<FurnitureData> {
  final Value<int> id;
  final Value<String> slug;
  final Value<String?> nameEn;
  final Value<String?> nameHu;
  final Value<String?> assetPath;
  final Value<String?> type;
  final Value<int> price;
  final Value<bool> isLocked;
  final Value<bool> isPlaced;
  final Value<DateTime?> unlockedAt;
  const FurnitureCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameHu = const Value.absent(),
    this.assetPath = const Value.absent(),
    this.type = const Value.absent(),
    this.price = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isPlaced = const Value.absent(),
    this.unlockedAt = const Value.absent(),
  });
  FurnitureCompanion.insert({
    this.id = const Value.absent(),
    required String slug,
    this.nameEn = const Value.absent(),
    this.nameHu = const Value.absent(),
    this.assetPath = const Value.absent(),
    this.type = const Value.absent(),
    this.price = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isPlaced = const Value.absent(),
    this.unlockedAt = const Value.absent(),
  }) : slug = Value(slug);
  static Insertable<FurnitureData> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? nameEn,
    Expression<String>? nameHu,
    Expression<String>? assetPath,
    Expression<String>? type,
    Expression<int>? price,
    Expression<bool>? isLocked,
    Expression<bool>? isPlaced,
    Expression<DateTime>? unlockedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (nameEn != null) 'name_en': nameEn,
      if (nameHu != null) 'name_hu': nameHu,
      if (assetPath != null) 'asset_path': assetPath,
      if (type != null) 'type': type,
      if (price != null) 'price': price,
      if (isLocked != null) 'is_locked': isLocked,
      if (isPlaced != null) 'is_placed': isPlaced,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
    });
  }

  FurnitureCompanion copyWith(
      {Value<int>? id,
      Value<String>? slug,
      Value<String?>? nameEn,
      Value<String?>? nameHu,
      Value<String?>? assetPath,
      Value<String?>? type,
      Value<int>? price,
      Value<bool>? isLocked,
      Value<bool>? isPlaced,
      Value<DateTime?>? unlockedAt}) {
    return FurnitureCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameEn: nameEn ?? this.nameEn,
      nameHu: nameHu ?? this.nameHu,
      assetPath: assetPath ?? this.assetPath,
      type: type ?? this.type,
      price: price ?? this.price,
      isLocked: isLocked ?? this.isLocked,
      isPlaced: isPlaced ?? this.isPlaced,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameHu.present) {
      map['name_hu'] = Variable<String>(nameHu.value);
    }
    if (assetPath.present) {
      map['asset_path'] = Variable<String>(assetPath.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isPlaced.present) {
      map['is_placed'] = Variable<bool>(isPlaced.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FurnitureCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameHu: $nameHu, ')
          ..write('assetPath: $assetPath, ')
          ..write('type: $type, ')
          ..write('price: $price, ')
          ..write('isLocked: $isLocked, ')
          ..write('isPlaced: $isPlaced, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }
}

class $StudentProfilesTable extends StudentProfiles
    with TableInfo<$StudentProfilesTable, StudentProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Student'));
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
      'xp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _coinsMeta = const VerificationMeta('coins');
  @override
  late final GeneratedColumn<int> coins = GeneratedColumn<int>(
      'coins', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, displayName, xp, coins, level];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<StudentProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('coins')) {
      context.handle(
          _coinsMeta, coins.isAcceptableOrUnknown(data['coins']!, _coinsMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      xp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      coins: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}coins'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
    );
  }

  @override
  $StudentProfilesTable createAlias(String alias) {
    return $StudentProfilesTable(attachedDatabase, alias);
  }
}

class StudentProfile extends DataClass implements Insertable<StudentProfile> {
  final int id;
  final String userId;
  final String displayName;
  final int xp;
  final int coins;
  final int level;
  const StudentProfile(
      {required this.id,
      required this.userId,
      required this.displayName,
      required this.xp,
      required this.coins,
      required this.level});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    map['xp'] = Variable<int>(xp);
    map['coins'] = Variable<int>(coins);
    map['level'] = Variable<int>(level);
    return map;
  }

  StudentProfilesCompanion toCompanion(bool nullToAbsent) {
    return StudentProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      displayName: Value(displayName),
      xp: Value(xp),
      coins: Value(coins),
      level: Value(level),
    );
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentProfile(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      xp: serializer.fromJson<int>(json['xp']),
      coins: serializer.fromJson<int>(json['coins']),
      level: serializer.fromJson<int>(json['level']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'xp': serializer.toJson<int>(xp),
      'coins': serializer.toJson<int>(coins),
      'level': serializer.toJson<int>(level),
    };
  }

  StudentProfile copyWith(
          {int? id,
          String? userId,
          String? displayName,
          int? xp,
          int? coins,
          int? level}) =>
      StudentProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        xp: xp ?? this.xp,
        coins: coins ?? this.coins,
        level: level ?? this.level,
      );
  StudentProfile copyWithCompanion(StudentProfilesCompanion data) {
    return StudentProfile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      xp: data.xp.present ? data.xp.value : this.xp,
      coins: data.coins.present ? data.coins.value : this.coins,
      level: data.level.present ? data.level.value : this.level,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentProfile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('xp: $xp, ')
          ..write('coins: $coins, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, displayName, xp, coins, level);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentProfile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.xp == this.xp &&
          other.coins == this.coins &&
          other.level == this.level);
}

class StudentProfilesCompanion extends UpdateCompanion<StudentProfile> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<int> xp;
  final Value<int> coins;
  final Value<int> level;
  const StudentProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.xp = const Value.absent(),
    this.coins = const Value.absent(),
    this.level = const Value.absent(),
  });
  StudentProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.displayName = const Value.absent(),
    this.xp = const Value.absent(),
    this.coins = const Value.absent(),
    this.level = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<StudentProfile> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<int>? xp,
    Expression<int>? coins,
    Expression<int>? level,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (xp != null) 'xp': xp,
      if (coins != null) 'coins': coins,
      if (level != null) 'level': level,
    });
  }

  StudentProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String>? displayName,
      Value<int>? xp,
      Value<int>? coins,
      Value<int>? level}) {
    return StudentProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      level: level ?? this.level,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (coins.present) {
      map['coins'] = Variable<int>(coins.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('xp: $xp, ')
          ..write('coins: $coins, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $TopicProgressTable topicProgress = $TopicProgressTable(this);
  late final $QuestionProgressTable questionProgress =
      $QuestionProgressTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $UserItemsTable userItems = $UserItemsTable(this);
  late final $EcgCasesTable ecgCases = $EcgCasesTable(this);
  late final $EcgDiagnosesTable ecgDiagnoses = $EcgDiagnosesTable(this);
  late final $FurnitureTable furniture = $FurnitureTable(this);
  late final $StudentProfilesTable studentProfiles =
      $StudentProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        questions,
        topicProgress,
        questionProgress,
        items,
        userItems,
        ecgCases,
        ecgDiagnoses,
        furniture,
        studentProfiles
      ];
}

typedef $$QuestionsTableCreateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> topicId,
  Value<String?> questionText,
  Value<String?> type,
  Value<String?> options,
  Value<String?> correctAnswer,
  Value<String?> explanation,
  Value<int?> bloomLevel,
  Value<int?> difficulty,
  Value<bool> active,
  Value<DateTime?> lastFetched,
});
typedef $$QuestionsTableUpdateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> topicId,
  Value<String?> questionText,
  Value<String?> type,
  Value<String?> options,
  Value<String?> correctAnswer,
  Value<String?> explanation,
  Value<int?> bloomLevel,
  Value<int?> difficulty,
  Value<bool> active,
  Value<DateTime?> lastFetched,
});

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get options => $composableBuilder(
      column: $table.options, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched, builder: (column) => ColumnFilters(column));
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get options => $composableBuilder(
      column: $table.options, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched, builder: (column) => ColumnOrderings(column));
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<int> get bloomLevel => $composableBuilder(
      column: $table.bloomLevel, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetched => $composableBuilder(
      column: $table.lastFetched, builder: (column) => column);
}

class $$QuestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
    Question,
    PrefetchHooks Function()> {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> topicId = const Value.absent(),
            Value<String?> questionText = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> options = const Value.absent(),
            Value<String?> correctAnswer = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<int?> bloomLevel = const Value.absent(),
            Value<int?> difficulty = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime?> lastFetched = const Value.absent(),
          }) =>
              QuestionsCompanion(
            id: id,
            serverId: serverId,
            topicId: topicId,
            questionText: questionText,
            type: type,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            bloomLevel: bloomLevel,
            difficulty: difficulty,
            active: active,
            lastFetched: lastFetched,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> topicId = const Value.absent(),
            Value<String?> questionText = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> options = const Value.absent(),
            Value<String?> correctAnswer = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<int?> bloomLevel = const Value.absent(),
            Value<int?> difficulty = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime?> lastFetched = const Value.absent(),
          }) =>
              QuestionsCompanion.insert(
            id: id,
            serverId: serverId,
            topicId: topicId,
            questionText: questionText,
            type: type,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            bloomLevel: bloomLevel,
            difficulty: difficulty,
            active: active,
            lastFetched: lastFetched,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
    Question,
    PrefetchHooks Function()>;
typedef $$TopicProgressTableCreateCompanionBuilder = TopicProgressCompanion
    Function({
  Value<int> id,
  Value<int?> userId,
  Value<String?> topicSlug,
  Value<int> currentBloomLevel,
  Value<int> currentStreak,
  Value<int> consecutiveWrong,
  Value<int> totalAnswered,
  Value<int> correctAnswered,
  Value<int> masteryScore,
  Value<int> unlockedBloomLevel,
  Value<int> questionsMastered,
  Value<int> levelCorrectCount,
  Value<DateTime?> lastStudiedAt,
});
typedef $$TopicProgressTableUpdateCompanionBuilder = TopicProgressCompanion
    Function({
  Value<int> id,
  Value<int?> userId,
  Value<String?> topicSlug,
  Value<int> currentBloomLevel,
  Value<int> currentStreak,
  Value<int> consecutiveWrong,
  Value<int> totalAnswered,
  Value<int> correctAnswered,
  Value<int> masteryScore,
  Value<int> unlockedBloomLevel,
  Value<int> questionsMastered,
  Value<int> levelCorrectCount,
  Value<DateTime?> lastStudiedAt,
});

class $$TopicProgressTableFilterComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topicSlug => $composableBuilder(
      column: $table.topicSlug, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get levelCorrectCount => $composableBuilder(
      column: $table.levelCorrectCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt, builder: (column) => ColumnFilters(column));
}

class $$TopicProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topicSlug => $composableBuilder(
      column: $table.topicSlug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get levelCorrectCount => $composableBuilder(
      column: $table.levelCorrectCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TopicProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicProgressTable> {
  $$TopicProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get topicSlug =>
      $composableBuilder(column: $table.topicSlug, builder: (column) => column);

  GeneratedColumn<int> get currentBloomLevel => $composableBuilder(
      column: $table.currentBloomLevel, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => column);

  GeneratedColumn<int> get consecutiveWrong => $composableBuilder(
      column: $table.consecutiveWrong, builder: (column) => column);

  GeneratedColumn<int> get totalAnswered => $composableBuilder(
      column: $table.totalAnswered, builder: (column) => column);

  GeneratedColumn<int> get correctAnswered => $composableBuilder(
      column: $table.correctAnswered, builder: (column) => column);

  GeneratedColumn<int> get masteryScore => $composableBuilder(
      column: $table.masteryScore, builder: (column) => column);

  GeneratedColumn<int> get unlockedBloomLevel => $composableBuilder(
      column: $table.unlockedBloomLevel, builder: (column) => column);

  GeneratedColumn<int> get questionsMastered => $composableBuilder(
      column: $table.questionsMastered, builder: (column) => column);

  GeneratedColumn<int> get levelCorrectCount => $composableBuilder(
      column: $table.levelCorrectCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastStudiedAt => $composableBuilder(
      column: $table.lastStudiedAt, builder: (column) => column);
}

class $$TopicProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TopicProgressTable,
    TopicProgressData,
    $$TopicProgressTableFilterComposer,
    $$TopicProgressTableOrderingComposer,
    $$TopicProgressTableAnnotationComposer,
    $$TopicProgressTableCreateCompanionBuilder,
    $$TopicProgressTableUpdateCompanionBuilder,
    (
      TopicProgressData,
      BaseReferences<_$AppDatabase, $TopicProgressTable, TopicProgressData>
    ),
    TopicProgressData,
    PrefetchHooks Function()> {
  $$TopicProgressTableTableManager(_$AppDatabase db, $TopicProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<String?> topicSlug = const Value.absent(),
            Value<int> currentBloomLevel = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<int> consecutiveWrong = const Value.absent(),
            Value<int> totalAnswered = const Value.absent(),
            Value<int> correctAnswered = const Value.absent(),
            Value<int> masteryScore = const Value.absent(),
            Value<int> unlockedBloomLevel = const Value.absent(),
            Value<int> questionsMastered = const Value.absent(),
            Value<int> levelCorrectCount = const Value.absent(),
            Value<DateTime?> lastStudiedAt = const Value.absent(),
          }) =>
              TopicProgressCompanion(
            id: id,
            userId: userId,
            topicSlug: topicSlug,
            currentBloomLevel: currentBloomLevel,
            currentStreak: currentStreak,
            consecutiveWrong: consecutiveWrong,
            totalAnswered: totalAnswered,
            correctAnswered: correctAnswered,
            masteryScore: masteryScore,
            unlockedBloomLevel: unlockedBloomLevel,
            questionsMastered: questionsMastered,
            levelCorrectCount: levelCorrectCount,
            lastStudiedAt: lastStudiedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<String?> topicSlug = const Value.absent(),
            Value<int> currentBloomLevel = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<int> consecutiveWrong = const Value.absent(),
            Value<int> totalAnswered = const Value.absent(),
            Value<int> correctAnswered = const Value.absent(),
            Value<int> masteryScore = const Value.absent(),
            Value<int> unlockedBloomLevel = const Value.absent(),
            Value<int> questionsMastered = const Value.absent(),
            Value<int> levelCorrectCount = const Value.absent(),
            Value<DateTime?> lastStudiedAt = const Value.absent(),
          }) =>
              TopicProgressCompanion.insert(
            id: id,
            userId: userId,
            topicSlug: topicSlug,
            currentBloomLevel: currentBloomLevel,
            currentStreak: currentStreak,
            consecutiveWrong: consecutiveWrong,
            totalAnswered: totalAnswered,
            correctAnswered: correctAnswered,
            masteryScore: masteryScore,
            unlockedBloomLevel: unlockedBloomLevel,
            questionsMastered: questionsMastered,
            levelCorrectCount: levelCorrectCount,
            lastStudiedAt: lastStudiedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TopicProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TopicProgressTable,
    TopicProgressData,
    $$TopicProgressTableFilterComposer,
    $$TopicProgressTableOrderingComposer,
    $$TopicProgressTableAnnotationComposer,
    $$TopicProgressTableCreateCompanionBuilder,
    $$TopicProgressTableUpdateCompanionBuilder,
    (
      TopicProgressData,
      BaseReferences<_$AppDatabase, $TopicProgressTable, TopicProgressData>
    ),
    TopicProgressData,
    PrefetchHooks Function()>;
typedef $$QuestionProgressTableCreateCompanionBuilder
    = QuestionProgressCompanion Function({
  Value<int> id,
  Value<int?> userId,
  Value<int?> questionId,
  Value<int> box,
  Value<int> consecutiveCorrect,
  Value<bool> mastered,
  Value<DateTime?> nextReviewAt,
  Value<DateTime?> lastAnsweredAt,
  Value<DateTime?> updatedAt,
});
typedef $$QuestionProgressTableUpdateCompanionBuilder
    = QuestionProgressCompanion Function({
  Value<int> id,
  Value<int?> userId,
  Value<int?> questionId,
  Value<int> box,
  Value<int> consecutiveCorrect,
  Value<bool> mastered,
  Value<DateTime?> nextReviewAt,
  Value<DateTime?> lastAnsweredAt,
  Value<DateTime?> updatedAt,
});

class $$QuestionProgressTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionProgressTable> {
  $$QuestionProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get box => $composableBuilder(
      column: $table.box, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get mastered => $composableBuilder(
      column: $table.mastered, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$QuestionProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionProgressTable> {
  $$QuestionProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get box => $composableBuilder(
      column: $table.box, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get mastered => $composableBuilder(
      column: $table.mastered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuestionProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionProgressTable> {
  $$QuestionProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<int> get consecutiveCorrect => $composableBuilder(
      column: $table.consecutiveCorrect, builder: (column) => column);

  GeneratedColumn<bool> get mastered =>
      $composableBuilder(column: $table.mastered, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAnsweredAt => $composableBuilder(
      column: $table.lastAnsweredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuestionProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionProgressTable,
    QuestionProgressData,
    $$QuestionProgressTableFilterComposer,
    $$QuestionProgressTableOrderingComposer,
    $$QuestionProgressTableAnnotationComposer,
    $$QuestionProgressTableCreateCompanionBuilder,
    $$QuestionProgressTableUpdateCompanionBuilder,
    (
      QuestionProgressData,
      BaseReferences<_$AppDatabase, $QuestionProgressTable,
          QuestionProgressData>
    ),
    QuestionProgressData,
    PrefetchHooks Function()> {
  $$QuestionProgressTableTableManager(
      _$AppDatabase db, $QuestionProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<int?> questionId = const Value.absent(),
            Value<int> box = const Value.absent(),
            Value<int> consecutiveCorrect = const Value.absent(),
            Value<bool> mastered = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<DateTime?> lastAnsweredAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              QuestionProgressCompanion(
            id: id,
            userId: userId,
            questionId: questionId,
            box: box,
            consecutiveCorrect: consecutiveCorrect,
            mastered: mastered,
            nextReviewAt: nextReviewAt,
            lastAnsweredAt: lastAnsweredAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<int?> questionId = const Value.absent(),
            Value<int> box = const Value.absent(),
            Value<int> consecutiveCorrect = const Value.absent(),
            Value<bool> mastered = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<DateTime?> lastAnsweredAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              QuestionProgressCompanion.insert(
            id: id,
            userId: userId,
            questionId: questionId,
            box: box,
            consecutiveCorrect: consecutiveCorrect,
            mastered: mastered,
            nextReviewAt: nextReviewAt,
            lastAnsweredAt: lastAnsweredAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuestionProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionProgressTable,
    QuestionProgressData,
    $$QuestionProgressTableFilterComposer,
    $$QuestionProgressTableOrderingComposer,
    $$QuestionProgressTableAnnotationComposer,
    $$QuestionProgressTableCreateCompanionBuilder,
    $$QuestionProgressTableUpdateCompanionBuilder,
    (
      QuestionProgressData,
      BaseReferences<_$AppDatabase, $QuestionProgressTable,
          QuestionProgressData>
    ),
    QuestionProgressData,
    PrefetchHooks Function()>;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String?> name,
  Value<String?> type,
  Value<String?> slotType,
  Value<int?> price,
  Value<String?> assetPath,
  Value<String?> description,
  Value<String?> theme,
  Value<bool> isPremium,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String?> name,
  Value<String?> type,
  Value<String?> slotType,
  Value<int?> price,
  Value<String?> assetPath,
  Value<String?> description,
  Value<String?> theme,
  Value<bool> isPremium,
});

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slotType => $composableBuilder(
      column: $table.slotType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnFilters(column));
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slotType => $composableBuilder(
      column: $table.slotType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get theme => $composableBuilder(
      column: $table.theme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnOrderings(column));
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get slotType =>
      $composableBuilder(column: $table.slotType, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get assetPath =>
      $composableBuilder(column: $table.assetPath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<bool> get isPremium =>
      $composableBuilder(column: $table.isPremium, builder: (column) => column);
}

class $$ItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
    Item,
    PrefetchHooks Function()> {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> slotType = const Value.absent(),
            Value<int?> price = const Value.absent(),
            Value<String?> assetPath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> theme = const Value.absent(),
            Value<bool> isPremium = const Value.absent(),
          }) =>
              ItemsCompanion(
            id: id,
            serverId: serverId,
            name: name,
            type: type,
            slotType: slotType,
            price: price,
            assetPath: assetPath,
            description: description,
            theme: theme,
            isPremium: isPremium,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> slotType = const Value.absent(),
            Value<int?> price = const Value.absent(),
            Value<String?> assetPath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> theme = const Value.absent(),
            Value<bool> isPremium = const Value.absent(),
          }) =>
              ItemsCompanion.insert(
            id: id,
            serverId: serverId,
            name: name,
            type: type,
            slotType: slotType,
            price: price,
            assetPath: assetPath,
            description: description,
            theme: theme,
            isPremium: isPremium,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsTable,
    Item,
    $$ItemsTableFilterComposer,
    $$ItemsTableOrderingComposer,
    $$ItemsTableAnnotationComposer,
    $$ItemsTableCreateCompanionBuilder,
    $$ItemsTableUpdateCompanionBuilder,
    (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
    Item,
    PrefetchHooks Function()>;
typedef $$UserItemsTableCreateCompanionBuilder = UserItemsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> userId,
  Value<int?> itemId,
  Value<bool> isPlaced,
  Value<int?> roomId,
  Value<String?> slot,
  Value<int> xPos,
  Value<int> yPos,
});
typedef $$UserItemsTableUpdateCompanionBuilder = UserItemsCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int?> userId,
  Value<int?> itemId,
  Value<bool> isPlaced,
  Value<int?> roomId,
  Value<String?> slot,
  Value<int> xPos,
  Value<int> yPos,
});

class $$UserItemsTableFilterComposer
    extends Composer<_$AppDatabase, $UserItemsTable> {
  $$UserItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xPos => $composableBuilder(
      column: $table.xPos, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get yPos => $composableBuilder(
      column: $table.yPos, builder: (column) => ColumnFilters(column));
}

class $$UserItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserItemsTable> {
  $$UserItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xPos => $composableBuilder(
      column: $table.xPos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get yPos => $composableBuilder(
      column: $table.yPos, builder: (column) => ColumnOrderings(column));
}

class $$UserItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserItemsTable> {
  $$UserItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<bool> get isPlaced =>
      $composableBuilder(column: $table.isPlaced, builder: (column) => column);

  GeneratedColumn<int> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get xPos =>
      $composableBuilder(column: $table.xPos, builder: (column) => column);

  GeneratedColumn<int> get yPos =>
      $composableBuilder(column: $table.yPos, builder: (column) => column);
}

class $$UserItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserItemsTable,
    UserItem,
    $$UserItemsTableFilterComposer,
    $$UserItemsTableOrderingComposer,
    $$UserItemsTableAnnotationComposer,
    $$UserItemsTableCreateCompanionBuilder,
    $$UserItemsTableUpdateCompanionBuilder,
    (UserItem, BaseReferences<_$AppDatabase, $UserItemsTable, UserItem>),
    UserItem,
    PrefetchHooks Function()> {
  $$UserItemsTableTableManager(_$AppDatabase db, $UserItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<int?> itemId = const Value.absent(),
            Value<bool> isPlaced = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<int> xPos = const Value.absent(),
            Value<int> yPos = const Value.absent(),
          }) =>
              UserItemsCompanion(
            id: id,
            serverId: serverId,
            userId: userId,
            itemId: itemId,
            isPlaced: isPlaced,
            roomId: roomId,
            slot: slot,
            xPos: xPos,
            yPos: yPos,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<int?> itemId = const Value.absent(),
            Value<bool> isPlaced = const Value.absent(),
            Value<int?> roomId = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<int> xPos = const Value.absent(),
            Value<int> yPos = const Value.absent(),
          }) =>
              UserItemsCompanion.insert(
            id: id,
            serverId: serverId,
            userId: userId,
            itemId: itemId,
            isPlaced: isPlaced,
            roomId: roomId,
            slot: slot,
            xPos: xPos,
            yPos: yPos,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserItemsTable,
    UserItem,
    $$UserItemsTableFilterComposer,
    $$UserItemsTableOrderingComposer,
    $$UserItemsTableAnnotationComposer,
    $$UserItemsTableCreateCompanionBuilder,
    $$UserItemsTableUpdateCompanionBuilder,
    (UserItem, BaseReferences<_$AppDatabase, $UserItemsTable, UserItem>),
    UserItem,
    PrefetchHooks Function()>;
typedef $$EcgCasesTableCreateCompanionBuilder = EcgCasesCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> description,
  required String type,
  required String difficulty,
  required String assetPath,
  required String correctDiagnoses,
});
typedef $$EcgCasesTableUpdateCompanionBuilder = EcgCasesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> description,
  Value<String> type,
  Value<String> difficulty,
  Value<String> assetPath,
  Value<String> correctDiagnoses,
});

class $$EcgCasesTableFilterComposer
    extends Composer<_$AppDatabase, $EcgCasesTable> {
  $$EcgCasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctDiagnoses => $composableBuilder(
      column: $table.correctDiagnoses,
      builder: (column) => ColumnFilters(column));
}

class $$EcgCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $EcgCasesTable> {
  $$EcgCasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctDiagnoses => $composableBuilder(
      column: $table.correctDiagnoses,
      builder: (column) => ColumnOrderings(column));
}

class $$EcgCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcgCasesTable> {
  $$EcgCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get assetPath =>
      $composableBuilder(column: $table.assetPath, builder: (column) => column);

  GeneratedColumn<String> get correctDiagnoses => $composableBuilder(
      column: $table.correctDiagnoses, builder: (column) => column);
}

class $$EcgCasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EcgCasesTable,
    EcgCase,
    $$EcgCasesTableFilterComposer,
    $$EcgCasesTableOrderingComposer,
    $$EcgCasesTableAnnotationComposer,
    $$EcgCasesTableCreateCompanionBuilder,
    $$EcgCasesTableUpdateCompanionBuilder,
    (EcgCase, BaseReferences<_$AppDatabase, $EcgCasesTable, EcgCase>),
    EcgCase,
    PrefetchHooks Function()> {
  $$EcgCasesTableTableManager(_$AppDatabase db, $EcgCasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcgCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcgCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcgCasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<String> assetPath = const Value.absent(),
            Value<String> correctDiagnoses = const Value.absent(),
          }) =>
              EcgCasesCompanion(
            id: id,
            title: title,
            description: description,
            type: type,
            difficulty: difficulty,
            assetPath: assetPath,
            correctDiagnoses: correctDiagnoses,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            required String type,
            required String difficulty,
            required String assetPath,
            required String correctDiagnoses,
          }) =>
              EcgCasesCompanion.insert(
            id: id,
            title: title,
            description: description,
            type: type,
            difficulty: difficulty,
            assetPath: assetPath,
            correctDiagnoses: correctDiagnoses,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EcgCasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EcgCasesTable,
    EcgCase,
    $$EcgCasesTableFilterComposer,
    $$EcgCasesTableOrderingComposer,
    $$EcgCasesTableAnnotationComposer,
    $$EcgCasesTableCreateCompanionBuilder,
    $$EcgCasesTableUpdateCompanionBuilder,
    (EcgCase, BaseReferences<_$AppDatabase, $EcgCasesTable, EcgCase>),
    EcgCase,
    PrefetchHooks Function()>;
typedef $$EcgDiagnosesTableCreateCompanionBuilder = EcgDiagnosesCompanion
    Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<int> rowid,
});
typedef $$EcgDiagnosesTableUpdateCompanionBuilder = EcgDiagnosesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<int> rowid,
});

class $$EcgDiagnosesTableFilterComposer
    extends Composer<_$AppDatabase, $EcgDiagnosesTable> {
  $$EcgDiagnosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));
}

class $$EcgDiagnosesTableOrderingComposer
    extends Composer<_$AppDatabase, $EcgDiagnosesTable> {
  $$EcgDiagnosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));
}

class $$EcgDiagnosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcgDiagnosesTable> {
  $$EcgDiagnosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);
}

class $$EcgDiagnosesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EcgDiagnosesTable,
    EcgDiagnose,
    $$EcgDiagnosesTableFilterComposer,
    $$EcgDiagnosesTableOrderingComposer,
    $$EcgDiagnosesTableAnnotationComposer,
    $$EcgDiagnosesTableCreateCompanionBuilder,
    $$EcgDiagnosesTableUpdateCompanionBuilder,
    (
      EcgDiagnose,
      BaseReferences<_$AppDatabase, $EcgDiagnosesTable, EcgDiagnose>
    ),
    EcgDiagnose,
    PrefetchHooks Function()> {
  $$EcgDiagnosesTableTableManager(_$AppDatabase db, $EcgDiagnosesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcgDiagnosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcgDiagnosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcgDiagnosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EcgDiagnosesCompanion(
            id: id,
            name: name,
            description: description,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EcgDiagnosesCompanion.insert(
            id: id,
            name: name,
            description: description,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EcgDiagnosesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EcgDiagnosesTable,
    EcgDiagnose,
    $$EcgDiagnosesTableFilterComposer,
    $$EcgDiagnosesTableOrderingComposer,
    $$EcgDiagnosesTableAnnotationComposer,
    $$EcgDiagnosesTableCreateCompanionBuilder,
    $$EcgDiagnosesTableUpdateCompanionBuilder,
    (
      EcgDiagnose,
      BaseReferences<_$AppDatabase, $EcgDiagnosesTable, EcgDiagnose>
    ),
    EcgDiagnose,
    PrefetchHooks Function()>;
typedef $$FurnitureTableCreateCompanionBuilder = FurnitureCompanion Function({
  Value<int> id,
  required String slug,
  Value<String?> nameEn,
  Value<String?> nameHu,
  Value<String?> assetPath,
  Value<String?> type,
  Value<int> price,
  Value<bool> isLocked,
  Value<bool> isPlaced,
  Value<DateTime?> unlockedAt,
});
typedef $$FurnitureTableUpdateCompanionBuilder = FurnitureCompanion Function({
  Value<int> id,
  Value<String> slug,
  Value<String?> nameEn,
  Value<String?> nameHu,
  Value<String?> assetPath,
  Value<String?> type,
  Value<int> price,
  Value<bool> isLocked,
  Value<bool> isPlaced,
  Value<DateTime?> unlockedAt,
});

class $$FurnitureTableFilterComposer
    extends Composer<_$AppDatabase, $FurnitureTable> {
  $$FurnitureTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameHu => $composableBuilder(
      column: $table.nameHu, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));
}

class $$FurnitureTableOrderingComposer
    extends Composer<_$AppDatabase, $FurnitureTable> {
  $$FurnitureTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameHu => $composableBuilder(
      column: $table.nameHu, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetPath => $composableBuilder(
      column: $table.assetPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPlaced => $composableBuilder(
      column: $table.isPlaced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));
}

class $$FurnitureTableAnnotationComposer
    extends Composer<_$AppDatabase, $FurnitureTable> {
  $$FurnitureTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameHu =>
      $composableBuilder(column: $table.nameHu, builder: (column) => column);

  GeneratedColumn<String> get assetPath =>
      $composableBuilder(column: $table.assetPath, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isPlaced =>
      $composableBuilder(column: $table.isPlaced, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);
}

class $$FurnitureTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FurnitureTable,
    FurnitureData,
    $$FurnitureTableFilterComposer,
    $$FurnitureTableOrderingComposer,
    $$FurnitureTableAnnotationComposer,
    $$FurnitureTableCreateCompanionBuilder,
    $$FurnitureTableUpdateCompanionBuilder,
    (
      FurnitureData,
      BaseReferences<_$AppDatabase, $FurnitureTable, FurnitureData>
    ),
    FurnitureData,
    PrefetchHooks Function()> {
  $$FurnitureTableTableManager(_$AppDatabase db, $FurnitureTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FurnitureTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FurnitureTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FurnitureTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String?> nameEn = const Value.absent(),
            Value<String?> nameHu = const Value.absent(),
            Value<String?> assetPath = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<int> price = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isPlaced = const Value.absent(),
            Value<DateTime?> unlockedAt = const Value.absent(),
          }) =>
              FurnitureCompanion(
            id: id,
            slug: slug,
            nameEn: nameEn,
            nameHu: nameHu,
            assetPath: assetPath,
            type: type,
            price: price,
            isLocked: isLocked,
            isPlaced: isPlaced,
            unlockedAt: unlockedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String slug,
            Value<String?> nameEn = const Value.absent(),
            Value<String?> nameHu = const Value.absent(),
            Value<String?> assetPath = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<int> price = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isPlaced = const Value.absent(),
            Value<DateTime?> unlockedAt = const Value.absent(),
          }) =>
              FurnitureCompanion.insert(
            id: id,
            slug: slug,
            nameEn: nameEn,
            nameHu: nameHu,
            assetPath: assetPath,
            type: type,
            price: price,
            isLocked: isLocked,
            isPlaced: isPlaced,
            unlockedAt: unlockedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FurnitureTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FurnitureTable,
    FurnitureData,
    $$FurnitureTableFilterComposer,
    $$FurnitureTableOrderingComposer,
    $$FurnitureTableAnnotationComposer,
    $$FurnitureTableCreateCompanionBuilder,
    $$FurnitureTableUpdateCompanionBuilder,
    (
      FurnitureData,
      BaseReferences<_$AppDatabase, $FurnitureTable, FurnitureData>
    ),
    FurnitureData,
    PrefetchHooks Function()>;
typedef $$StudentProfilesTableCreateCompanionBuilder = StudentProfilesCompanion
    Function({
  Value<int> id,
  required String userId,
  Value<String> displayName,
  Value<int> xp,
  Value<int> coins,
  Value<int> level,
});
typedef $$StudentProfilesTableUpdateCompanionBuilder = StudentProfilesCompanion
    Function({
  Value<int> id,
  Value<String> userId,
  Value<String> displayName,
  Value<int> xp,
  Value<int> coins,
  Value<int> level,
});

class $$StudentProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $StudentProfilesTable> {
  $$StudentProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get coins => $composableBuilder(
      column: $table.coins, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));
}

class $$StudentProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentProfilesTable> {
  $$StudentProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get coins => $composableBuilder(
      column: $table.coins, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));
}

class $$StudentProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentProfilesTable> {
  $$StudentProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get coins =>
      $composableBuilder(column: $table.coins, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);
}

class $$StudentProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudentProfilesTable,
    StudentProfile,
    $$StudentProfilesTableFilterComposer,
    $$StudentProfilesTableOrderingComposer,
    $$StudentProfilesTableAnnotationComposer,
    $$StudentProfilesTableCreateCompanionBuilder,
    $$StudentProfilesTableUpdateCompanionBuilder,
    (
      StudentProfile,
      BaseReferences<_$AppDatabase, $StudentProfilesTable, StudentProfile>
    ),
    StudentProfile,
    PrefetchHooks Function()> {
  $$StudentProfilesTableTableManager(
      _$AppDatabase db, $StudentProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> coins = const Value.absent(),
            Value<int> level = const Value.absent(),
          }) =>
              StudentProfilesCompanion(
            id: id,
            userId: userId,
            displayName: displayName,
            xp: xp,
            coins: coins,
            level: level,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String userId,
            Value<String> displayName = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> coins = const Value.absent(),
            Value<int> level = const Value.absent(),
          }) =>
              StudentProfilesCompanion.insert(
            id: id,
            userId: userId,
            displayName: displayName,
            xp: xp,
            coins: coins,
            level: level,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudentProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudentProfilesTable,
    StudentProfile,
    $$StudentProfilesTableFilterComposer,
    $$StudentProfilesTableOrderingComposer,
    $$StudentProfilesTableAnnotationComposer,
    $$StudentProfilesTableCreateCompanionBuilder,
    $$StudentProfilesTableUpdateCompanionBuilder,
    (
      StudentProfile,
      BaseReferences<_$AppDatabase, $StudentProfilesTable, StudentProfile>
    ),
    StudentProfile,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$TopicProgressTableTableManager get topicProgress =>
      $$TopicProgressTableTableManager(_db, _db.topicProgress);
  $$QuestionProgressTableTableManager get questionProgress =>
      $$QuestionProgressTableTableManager(_db, _db.questionProgress);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$UserItemsTableTableManager get userItems =>
      $$UserItemsTableTableManager(_db, _db.userItems);
  $$EcgCasesTableTableManager get ecgCases =>
      $$EcgCasesTableTableManager(_db, _db.ecgCases);
  $$EcgDiagnosesTableTableManager get ecgDiagnoses =>
      $$EcgDiagnosesTableTableManager(_db, _db.ecgDiagnoses);
  $$FurnitureTableTableManager get furniture =>
      $$FurnitureTableTableManager(_db, _db.furniture);
  $$StudentProfilesTableTableManager get studentProfiles =>
      $$StudentProfilesTableTableManager(_db, _db.studentProfiles);
}
