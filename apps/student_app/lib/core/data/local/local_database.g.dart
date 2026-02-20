// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalQuestionsTable extends LocalQuestions
    with TableInfo<$LocalQuestionsTable, LocalQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bloomLevelMeta = const VerificationMeta(
    'bloomLevel',
  );
  @override
  late final GeneratedColumn<int> bloomLevel = GeneratedColumn<int>(
    'bloom_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    bloomLevel,
    content,
    explanation,
    optionsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('bloom_level')) {
      context.handle(
        _bloomLevelMeta,
        bloomLevel.isAcceptableOrUnknown(data['bloom_level']!, _bloomLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_bloomLevelMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      bloomLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bloom_level'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
    );
  }

  @override
  $LocalQuestionsTable createAlias(String alias) {
    return $LocalQuestionsTable(attachedDatabase, alias);
  }
}

class LocalQuestion extends DataClass implements Insertable<LocalQuestion> {
  final String id;
  final String topicId;
  final int bloomLevel;
  final String content;
  final String explanation;
  final String optionsJson;
  const LocalQuestion({
    required this.id,
    required this.topicId,
    required this.bloomLevel,
    required this.content,
    required this.explanation,
    required this.optionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['topic_id'] = Variable<String>(topicId);
    map['bloom_level'] = Variable<int>(bloomLevel);
    map['content'] = Variable<String>(content);
    map['explanation'] = Variable<String>(explanation);
    map['options_json'] = Variable<String>(optionsJson);
    return map;
  }

  LocalQuestionsCompanion toCompanion(bool nullToAbsent) {
    return LocalQuestionsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      bloomLevel: Value(bloomLevel),
      content: Value(content),
      explanation: Value(explanation),
      optionsJson: Value(optionsJson),
    );
  }

  factory LocalQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuestion(
      id: serializer.fromJson<String>(json['id']),
      topicId: serializer.fromJson<String>(json['topicId']),
      bloomLevel: serializer.fromJson<int>(json['bloomLevel']),
      content: serializer.fromJson<String>(json['content']),
      explanation: serializer.fromJson<String>(json['explanation']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'topicId': serializer.toJson<String>(topicId),
      'bloomLevel': serializer.toJson<int>(bloomLevel),
      'content': serializer.toJson<String>(content),
      'explanation': serializer.toJson<String>(explanation),
      'optionsJson': serializer.toJson<String>(optionsJson),
    };
  }

  LocalQuestion copyWith({
    String? id,
    String? topicId,
    int? bloomLevel,
    String? content,
    String? explanation,
    String? optionsJson,
  }) => LocalQuestion(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    bloomLevel: bloomLevel ?? this.bloomLevel,
    content: content ?? this.content,
    explanation: explanation ?? this.explanation,
    optionsJson: optionsJson ?? this.optionsJson,
  );
  LocalQuestion copyWithCompanion(LocalQuestionsCompanion data) {
    return LocalQuestion(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      bloomLevel: data.bloomLevel.present
          ? data.bloomLevel.value
          : this.bloomLevel,
      content: data.content.present ? data.content.value : this.content,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('bloomLevel: $bloomLevel, ')
          ..write('content: $content, ')
          ..write('explanation: $explanation, ')
          ..write('optionsJson: $optionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, topicId, bloomLevel, content, explanation, optionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuestion &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.bloomLevel == this.bloomLevel &&
          other.content == this.content &&
          other.explanation == this.explanation &&
          other.optionsJson == this.optionsJson);
}

class LocalQuestionsCompanion extends UpdateCompanion<LocalQuestion> {
  final Value<String> id;
  final Value<String> topicId;
  final Value<int> bloomLevel;
  final Value<String> content;
  final Value<String> explanation;
  final Value<String> optionsJson;
  final Value<int> rowid;
  const LocalQuestionsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.bloomLevel = const Value.absent(),
    this.content = const Value.absent(),
    this.explanation = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQuestionsCompanion.insert({
    required String id,
    required String topicId,
    required int bloomLevel,
    required String content,
    required String explanation,
    required String optionsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       topicId = Value(topicId),
       bloomLevel = Value(bloomLevel),
       content = Value(content),
       explanation = Value(explanation),
       optionsJson = Value(optionsJson);
  static Insertable<LocalQuestion> custom({
    Expression<String>? id,
    Expression<String>? topicId,
    Expression<int>? bloomLevel,
    Expression<String>? content,
    Expression<String>? explanation,
    Expression<String>? optionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (bloomLevel != null) 'bloom_level': bloomLevel,
      if (content != null) 'content': content,
      if (explanation != null) 'explanation': explanation,
      if (optionsJson != null) 'options_json': optionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? topicId,
    Value<int>? bloomLevel,
    Value<String>? content,
    Value<String>? explanation,
    Value<String>? optionsJson,
    Value<int>? rowid,
  }) {
    return LocalQuestionsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      content: content ?? this.content,
      explanation: explanation ?? this.explanation,
      optionsJson: optionsJson ?? this.optionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (bloomLevel.present) {
      map['bloom_level'] = Variable<int>(bloomLevel.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('bloomLevel: $bloomLevel, ')
          ..write('content: $content, ')
          ..write('explanation: $explanation, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMasteryTable extends LocalMastery
    with TableInfo<$LocalMasteryTable, LocalMasteryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMasteryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easinessMeta = const VerificationMeta(
    'easiness',
  );
  @override
  late final GeneratedColumn<double> easiness = GeneratedColumn<double>(
    'easiness',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
    'next_review',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    questionId,
    easiness,
    interval,
    repetitions,
    nextReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_mastery';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMasteryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('easiness')) {
      context.handle(
        _easinessMeta,
        easiness.isAcceptableOrUnknown(data['easiness']!, _easinessMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, questionId};
  @override
  LocalMasteryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMasteryData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      easiness: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}easiness'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review'],
      )!,
    );
  }

  @override
  $LocalMasteryTable createAlias(String alias) {
    return $LocalMasteryTable(attachedDatabase, alias);
  }
}

class LocalMasteryData extends DataClass
    implements Insertable<LocalMasteryData> {
  final String userId;
  final String questionId;
  final double easiness;
  final int interval;
  final int repetitions;
  final DateTime nextReview;
  const LocalMasteryData({
    required this.userId,
    required this.questionId,
    required this.easiness,
    required this.interval,
    required this.repetitions,
    required this.nextReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['question_id'] = Variable<String>(questionId);
    map['easiness'] = Variable<double>(easiness);
    map['interval'] = Variable<int>(interval);
    map['repetitions'] = Variable<int>(repetitions);
    map['next_review'] = Variable<DateTime>(nextReview);
    return map;
  }

  LocalMasteryCompanion toCompanion(bool nullToAbsent) {
    return LocalMasteryCompanion(
      userId: Value(userId),
      questionId: Value(questionId),
      easiness: Value(easiness),
      interval: Value(interval),
      repetitions: Value(repetitions),
      nextReview: Value(nextReview),
    );
  }

  factory LocalMasteryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMasteryData(
      userId: serializer.fromJson<String>(json['userId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      easiness: serializer.fromJson<double>(json['easiness']),
      interval: serializer.fromJson<int>(json['interval']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      nextReview: serializer.fromJson<DateTime>(json['nextReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'questionId': serializer.toJson<String>(questionId),
      'easiness': serializer.toJson<double>(easiness),
      'interval': serializer.toJson<int>(interval),
      'repetitions': serializer.toJson<int>(repetitions),
      'nextReview': serializer.toJson<DateTime>(nextReview),
    };
  }

  LocalMasteryData copyWith({
    String? userId,
    String? questionId,
    double? easiness,
    int? interval,
    int? repetitions,
    DateTime? nextReview,
  }) => LocalMasteryData(
    userId: userId ?? this.userId,
    questionId: questionId ?? this.questionId,
    easiness: easiness ?? this.easiness,
    interval: interval ?? this.interval,
    repetitions: repetitions ?? this.repetitions,
    nextReview: nextReview ?? this.nextReview,
  );
  LocalMasteryData copyWithCompanion(LocalMasteryCompanion data) {
    return LocalMasteryData(
      userId: data.userId.present ? data.userId.value : this.userId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      easiness: data.easiness.present ? data.easiness.value : this.easiness,
      interval: data.interval.present ? data.interval.value : this.interval,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMasteryData(')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('easiness: $easiness, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReview: $nextReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    questionId,
    easiness,
    interval,
    repetitions,
    nextReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMasteryData &&
          other.userId == this.userId &&
          other.questionId == this.questionId &&
          other.easiness == this.easiness &&
          other.interval == this.interval &&
          other.repetitions == this.repetitions &&
          other.nextReview == this.nextReview);
}

class LocalMasteryCompanion extends UpdateCompanion<LocalMasteryData> {
  final Value<String> userId;
  final Value<String> questionId;
  final Value<double> easiness;
  final Value<int> interval;
  final Value<int> repetitions;
  final Value<DateTime> nextReview;
  final Value<int> rowid;
  const LocalMasteryCompanion({
    this.userId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.easiness = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMasteryCompanion.insert({
    required String userId,
    required String questionId,
    this.easiness = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       questionId = Value(questionId);
  static Insertable<LocalMasteryData> custom({
    Expression<String>? userId,
    Expression<String>? questionId,
    Expression<double>? easiness,
    Expression<int>? interval,
    Expression<int>? repetitions,
    Expression<DateTime>? nextReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      if (easiness != null) 'easiness': easiness,
      if (interval != null) 'interval': interval,
      if (repetitions != null) 'repetitions': repetitions,
      if (nextReview != null) 'next_review': nextReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMasteryCompanion copyWith({
    Value<String>? userId,
    Value<String>? questionId,
    Value<double>? easiness,
    Value<int>? interval,
    Value<int>? repetitions,
    Value<DateTime>? nextReview,
    Value<int>? rowid,
  }) {
    return LocalMasteryCompanion(
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      easiness: easiness ?? this.easiness,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (easiness.present) {
      map['easiness'] = Variable<double>(easiness.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMasteryCompanion(')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('easiness: $easiness, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReview: $nextReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalQuestionsTable localQuestions = $LocalQuestionsTable(this);
  late final $LocalMasteryTable localMastery = $LocalMasteryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localQuestions,
    localMastery,
  ];
}

typedef $$LocalQuestionsTableCreateCompanionBuilder =
    LocalQuestionsCompanion Function({
      required String id,
      required String topicId,
      required int bloomLevel,
      required String content,
      required String explanation,
      required String optionsJson,
      Value<int> rowid,
    });
typedef $$LocalQuestionsTableUpdateCompanionBuilder =
    LocalQuestionsCompanion Function({
      Value<String> id,
      Value<String> topicId,
      Value<int> bloomLevel,
      Value<String> content,
      Value<String> explanation,
      Value<String> optionsJson,
      Value<int> rowid,
    });

class $$LocalQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bloomLevel => $composableBuilder(
    column: $table.bloomLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bloomLevel => $composableBuilder(
    column: $table.bloomLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get bloomLevel => $composableBuilder(
    column: $table.bloomLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );
}

class $$LocalQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalQuestionsTable,
          LocalQuestion,
          $$LocalQuestionsTableFilterComposer,
          $$LocalQuestionsTableOrderingComposer,
          $$LocalQuestionsTableAnnotationComposer,
          $$LocalQuestionsTableCreateCompanionBuilder,
          $$LocalQuestionsTableUpdateCompanionBuilder,
          (
            LocalQuestion,
            BaseReferences<_$AppDatabase, $LocalQuestionsTable, LocalQuestion>,
          ),
          LocalQuestion,
          PrefetchHooks Function()
        > {
  $$LocalQuestionsTableTableManager(
    _$AppDatabase db,
    $LocalQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<int> bloomLevel = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalQuestionsCompanion(
                id: id,
                topicId: topicId,
                bloomLevel: bloomLevel,
                content: content,
                explanation: explanation,
                optionsJson: optionsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String topicId,
                required int bloomLevel,
                required String content,
                required String explanation,
                required String optionsJson,
                Value<int> rowid = const Value.absent(),
              }) => LocalQuestionsCompanion.insert(
                id: id,
                topicId: topicId,
                bloomLevel: bloomLevel,
                content: content,
                explanation: explanation,
                optionsJson: optionsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalQuestionsTable,
      LocalQuestion,
      $$LocalQuestionsTableFilterComposer,
      $$LocalQuestionsTableOrderingComposer,
      $$LocalQuestionsTableAnnotationComposer,
      $$LocalQuestionsTableCreateCompanionBuilder,
      $$LocalQuestionsTableUpdateCompanionBuilder,
      (
        LocalQuestion,
        BaseReferences<_$AppDatabase, $LocalQuestionsTable, LocalQuestion>,
      ),
      LocalQuestion,
      PrefetchHooks Function()
    >;
typedef $$LocalMasteryTableCreateCompanionBuilder =
    LocalMasteryCompanion Function({
      required String userId,
      required String questionId,
      Value<double> easiness,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime> nextReview,
      Value<int> rowid,
    });
typedef $$LocalMasteryTableUpdateCompanionBuilder =
    LocalMasteryCompanion Function({
      Value<String> userId,
      Value<String> questionId,
      Value<double> easiness,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime> nextReview,
      Value<int> rowid,
    });

class $$LocalMasteryTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMasteryTable> {
  $$LocalMasteryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easiness => $composableBuilder(
    column: $table.easiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMasteryTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMasteryTable> {
  $$LocalMasteryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easiness => $composableBuilder(
    column: $table.easiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMasteryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMasteryTable> {
  $$LocalMasteryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easiness =>
      $composableBuilder(column: $table.easiness, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );
}

class $$LocalMasteryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMasteryTable,
          LocalMasteryData,
          $$LocalMasteryTableFilterComposer,
          $$LocalMasteryTableOrderingComposer,
          $$LocalMasteryTableAnnotationComposer,
          $$LocalMasteryTableCreateCompanionBuilder,
          $$LocalMasteryTableUpdateCompanionBuilder,
          (
            LocalMasteryData,
            BaseReferences<_$AppDatabase, $LocalMasteryTable, LocalMasteryData>,
          ),
          LocalMasteryData,
          PrefetchHooks Function()
        > {
  $$LocalMasteryTableTableManager(_$AppDatabase db, $LocalMasteryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMasteryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMasteryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMasteryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<double> easiness = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> nextReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMasteryCompanion(
                userId: userId,
                questionId: questionId,
                easiness: easiness,
                interval: interval,
                repetitions: repetitions,
                nextReview: nextReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String questionId,
                Value<double> easiness = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> nextReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMasteryCompanion.insert(
                userId: userId,
                questionId: questionId,
                easiness: easiness,
                interval: interval,
                repetitions: repetitions,
                nextReview: nextReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMasteryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMasteryTable,
      LocalMasteryData,
      $$LocalMasteryTableFilterComposer,
      $$LocalMasteryTableOrderingComposer,
      $$LocalMasteryTableAnnotationComposer,
      $$LocalMasteryTableCreateCompanionBuilder,
      $$LocalMasteryTableUpdateCompanionBuilder,
      (
        LocalMasteryData,
        BaseReferences<_$AppDatabase, $LocalMasteryTable, LocalMasteryData>,
      ),
      LocalMasteryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalQuestionsTableTableManager get localQuestions =>
      $$LocalQuestionsTableTableManager(_db, _db.localQuestions);
  $$LocalMasteryTableTableManager get localMastery =>
      $$LocalMasteryTableTableManager(_db, _db.localMastery);
}
