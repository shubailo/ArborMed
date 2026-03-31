// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQuestionCollectionCollection on Isar {
  IsarCollection<QuestionCollection> get questionCollections =>
      this.collection();
}

const QuestionCollectionSchema = CollectionSchema(
  name: r'QuestionCollection',
  id: -6570938562249556041,
  properties: {
    r'attempts': PropertySchema(
      id: 0,
      name: r'attempts',
      type: IsarType.long,
    ),
    r'bloomLevel': PropertySchema(
      id: 1,
      name: r'bloomLevel',
      type: IsarType.long,
    ),
    r'correctAnswerIndex': PropertySchema(
      id: 2,
      name: r'correctAnswerIndex',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'explanationEn': PropertySchema(
      id: 4,
      name: r'explanationEn',
      type: IsarType.string,
    ),
    r'explanationHu': PropertySchema(
      id: 5,
      name: r'explanationHu',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 6,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'optionsEn': PropertySchema(
      id: 7,
      name: r'optionsEn',
      type: IsarType.stringList,
    ),
    r'optionsHu': PropertySchema(
      id: 8,
      name: r'optionsHu',
      type: IsarType.stringList,
    ),
    r'remoteId': PropertySchema(
      id: 9,
      name: r'remoteId',
      type: IsarType.long,
    ),
    r'successRate': PropertySchema(
      id: 10,
      name: r'successRate',
      type: IsarType.double,
    ),
    r'textEn': PropertySchema(
      id: 11,
      name: r'textEn',
      type: IsarType.string,
    ),
    r'textHu': PropertySchema(
      id: 12,
      name: r'textHu',
      type: IsarType.string,
    ),
    r'topicSlug': PropertySchema(
      id: 13,
      name: r'topicSlug',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 14,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _questionCollectionEstimateSize,
  serialize: _questionCollectionSerialize,
  deserialize: _questionCollectionDeserialize,
  deserializeProp: _questionCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'topicSlug': IndexSchema(
      id: 5254990363469185301,
      name: r'topicSlug',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'topicSlug',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _questionCollectionGetId,
  getLinks: _questionCollectionGetLinks,
  attach: _questionCollectionAttach,
  version: '3.1.0+1',
);

int _questionCollectionEstimateSize(
  QuestionCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.explanationEn;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.explanationHu;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.optionsEn.length * 3;
  {
    for (var i = 0; i < object.optionsEn.length; i++) {
      final value = object.optionsEn[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.optionsHu.length * 3;
  {
    for (var i = 0; i < object.optionsHu.length; i++) {
      final value = object.optionsHu[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.textEn.length * 3;
  bytesCount += 3 + object.textHu.length * 3;
  bytesCount += 3 + object.topicSlug.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _questionCollectionSerialize(
  QuestionCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeLong(offsets[1], object.bloomLevel);
  writer.writeLong(offsets[2], object.correctAnswerIndex);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.explanationEn);
  writer.writeString(offsets[5], object.explanationHu);
  writer.writeBool(offsets[6], object.isFavorite);
  writer.writeStringList(offsets[7], object.optionsEn);
  writer.writeStringList(offsets[8], object.optionsHu);
  writer.writeLong(offsets[9], object.remoteId);
  writer.writeDouble(offsets[10], object.successRate);
  writer.writeString(offsets[11], object.textEn);
  writer.writeString(offsets[12], object.textHu);
  writer.writeString(offsets[13], object.topicSlug);
  writer.writeString(offsets[14], object.type);
}

QuestionCollection _questionCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QuestionCollection();
  object.attempts = reader.readLong(offsets[0]);
  object.bloomLevel = reader.readLong(offsets[1]);
  object.correctAnswerIndex = reader.readLong(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.explanationEn = reader.readStringOrNull(offsets[4]);
  object.explanationHu = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[6]);
  object.optionsEn = reader.readStringList(offsets[7]) ?? [];
  object.optionsHu = reader.readStringList(offsets[8]) ?? [];
  object.remoteId = reader.readLong(offsets[9]);
  object.successRate = reader.readDouble(offsets[10]);
  object.textEn = reader.readString(offsets[11]);
  object.textHu = reader.readString(offsets[12]);
  object.topicSlug = reader.readString(offsets[13]);
  object.type = reader.readString(offsets[14]);
  return object;
}

P _questionCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readStringList(offset) ?? []) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _questionCollectionGetId(QuestionCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _questionCollectionGetLinks(
    QuestionCollection object) {
  return [];
}

void _questionCollectionAttach(
    IsarCollection<dynamic> col, Id id, QuestionCollection object) {
  object.id = id;
}

extension QuestionCollectionQueryWhereSort
    on QueryBuilder<QuestionCollection, QuestionCollection, QWhere> {
  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhere>
      anyRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'remoteId'),
      );
    });
  }
}

extension QuestionCollectionQueryWhere
    on QueryBuilder<QuestionCollection, QuestionCollection, QWhereClause> {
  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      remoteIdEqualTo(int remoteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'remoteId',
        value: [remoteId],
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      remoteIdNotEqualTo(int remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [remoteId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'remoteId',
              lower: [],
              upper: [remoteId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      remoteIdGreaterThan(
    int remoteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [remoteId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      remoteIdLessThan(
    int remoteId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [],
        upper: [remoteId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      remoteIdBetween(
    int lowerRemoteId,
    int upperRemoteId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'remoteId',
        lower: [lowerRemoteId],
        includeLower: includeLower,
        upper: [upperRemoteId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      topicSlugEqualTo(String topicSlug) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'topicSlug',
        value: [topicSlug],
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterWhereClause>
      topicSlugNotEqualTo(String topicSlug) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicSlug',
              lower: [],
              upper: [topicSlug],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicSlug',
              lower: [topicSlug],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicSlug',
              lower: [topicSlug],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'topicSlug',
              lower: [],
              upper: [topicSlug],
              includeUpper: false,
            ));
      }
    });
  }
}

extension QuestionCollectionQueryFilter
    on QueryBuilder<QuestionCollection, QuestionCollection, QFilterCondition> {
  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      attemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      attemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      attemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      bloomLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bloomLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      bloomLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bloomLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      bloomLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bloomLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      bloomLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bloomLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      correctAnswerIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctAnswerIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      correctAnswerIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctAnswerIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      correctAnswerIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctAnswerIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      correctAnswerIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctAnswerIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'explanationEn',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'explanationEn',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'explanationEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'explanationEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'explanationEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanationEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'explanationEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'explanationHu',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'explanationHu',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'explanationHu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'explanationHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'explanationHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanationHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      explanationHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'explanationHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'optionsEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'optionsEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'optionsEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'optionsEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'optionsEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsEnLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsEn',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'optionsHu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'optionsHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'optionsHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'optionsHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'optionsHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      optionsHuLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'optionsHu',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      remoteIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      remoteIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      remoteIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      remoteIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      successRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'successRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      successRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'successRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      successRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'successRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      successRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'successRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textEn',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textHu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      textHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textHu',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topicSlug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topicSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topicSlug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topicSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      topicSlugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topicSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension QuestionCollectionQueryObject
    on QueryBuilder<QuestionCollection, QuestionCollection, QFilterCondition> {}

extension QuestionCollectionQueryLinks
    on QueryBuilder<QuestionCollection, QuestionCollection, QFilterCondition> {}

extension QuestionCollectionQuerySortBy
    on QueryBuilder<QuestionCollection, QuestionCollection, QSortBy> {
  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByBloomLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloomLevel', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByBloomLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloomLevel', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByCorrectAnswerIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswerIndex', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByCorrectAnswerIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswerIndex', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByExplanationEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationEn', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByExplanationEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationEn', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByExplanationHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationHu', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByExplanationHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationHu', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortBySuccessRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successRate', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortBySuccessRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successRate', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTextEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textEn', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTextEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textEn', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTextHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHu', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTextHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHu', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTopicSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicSlug', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTopicSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicSlug', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension QuestionCollectionQuerySortThenBy
    on QueryBuilder<QuestionCollection, QuestionCollection, QSortThenBy> {
  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByBloomLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloomLevel', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByBloomLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloomLevel', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByCorrectAnswerIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswerIndex', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByCorrectAnswerIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctAnswerIndex', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByExplanationEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationEn', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByExplanationEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationEn', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByExplanationHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationHu', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByExplanationHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanationHu', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenBySuccessRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successRate', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenBySuccessRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successRate', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTextEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textEn', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTextEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textEn', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTextHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHu', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTextHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHu', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTopicSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicSlug', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTopicSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicSlug', Sort.desc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension QuestionCollectionQueryWhereDistinct
    on QueryBuilder<QuestionCollection, QuestionCollection, QDistinct> {
  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByBloomLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bloomLevel');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByCorrectAnswerIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctAnswerIndex');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByExplanationEn({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'explanationEn',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByExplanationHu({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'explanationHu',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByOptionsEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'optionsEn');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByOptionsHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'optionsHu');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctBySuccessRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successRate');
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByTextEn({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByTextHu({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textHu', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByTopicSlug({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicSlug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuestionCollection, QuestionCollection, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension QuestionCollectionQueryProperty
    on QueryBuilder<QuestionCollection, QuestionCollection, QQueryProperty> {
  QueryBuilder<QuestionCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QuestionCollection, int, QQueryOperations> attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<QuestionCollection, int, QQueryOperations> bloomLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bloomLevel');
    });
  }

  QueryBuilder<QuestionCollection, int, QQueryOperations>
      correctAnswerIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctAnswerIndex');
    });
  }

  QueryBuilder<QuestionCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<QuestionCollection, String?, QQueryOperations>
      explanationEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'explanationEn');
    });
  }

  QueryBuilder<QuestionCollection, String?, QQueryOperations>
      explanationHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'explanationHu');
    });
  }

  QueryBuilder<QuestionCollection, bool, QQueryOperations>
      isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<QuestionCollection, List<String>, QQueryOperations>
      optionsEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'optionsEn');
    });
  }

  QueryBuilder<QuestionCollection, List<String>, QQueryOperations>
      optionsHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'optionsHu');
    });
  }

  QueryBuilder<QuestionCollection, int, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<QuestionCollection, double, QQueryOperations>
      successRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successRate');
    });
  }

  QueryBuilder<QuestionCollection, String, QQueryOperations> textEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textEn');
    });
  }

  QueryBuilder<QuestionCollection, String, QQueryOperations> textHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textHu');
    });
  }

  QueryBuilder<QuestionCollection, String, QQueryOperations>
      topicSlugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicSlug');
    });
  }

  QueryBuilder<QuestionCollection, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
